[![Gem Version](https://badge.fury.io/rb/rubanok.svg)](https://rubygems.org/gems/rubanok)
![Build](https://github.com/palkan/rubanok/workflows/Build/badge.svg)

# Rubanok

Rubanok provides a DSL to build parameters-based data transformers.

📖 Read the introduction post: ["Carve your controllers like Papa Carlo"](https://evilmartians.com/chronicles/rubanok-carve-your-rails-controllers-like-papa-carlo)

The typical usage is to describe all the possible collection manipulation for REST `index` action, e.g. filtering, sorting, searching, pagination, etc..

So, instead of:

```ruby
class CourseSessionController < ApplicationController
  def index
    @sessions = CourseSession
      .search(params[:q])
      .by_course_type(params[:course_type_id])
      .by_role(params[:role_id])
      .paginate(page_params)
      .order(ordering_params)
  end
end
```

You have:

```ruby
class CourseSessionController < ApplicationController
  def index
    @sessions = rubanok_process(
      # pass input
      CourseSession.all,
      # pass params
      params,
      # provide a processor to use
      with: CourseSessionsProcessor
    )
  end
end
```

Or we can try to infer all the configuration for you:

```ruby
class CourseSessionController < ApplicationController
  def index
    @sessions = rubanok_process(CourseSession.all)
  end
end
```

Requirements:

- Ruby ~> 2.5
- (optional\*) Rails >= 5.2 (Rails 4.2 should work but we don't test against it anymore)

\* This gem has no dependency on Rails.

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Installation

Add to your `Gemfile`:

```ruby
gem "rubanok"
```

And run `bundle install`.

## Usage

The core concept of this library is a processor (previously called _plane_ or _hand plane_, or "рубанок" in Russian). Processor is responsible for mapping parameters to transformations.

From the example above:

```ruby
class CourseSessionsProcessor < Rubanok::Processor
  # You can map keys
  map :q do |q:|
    # `raw` is an accessor for input data
    raw.search(q)
  end
end

# The following code
CourseSessionsProcessor.call(CourseSession.all, q: "xyz")

# is equal to
CourseSession.all.search("xyz")
```

You can map multiple keys at once:

```ruby
class CourseSessionsProcessor < Rubanok::Processor
  DEFAULT_PAGE_SIZE = 25

  map :page, :per_page do |page:, per_page: DEFAULT_PAGE_SIZE|
    raw.paginate(page: page, per_page: per_page)
  end
end
```

There is also `match` method to handle values:

```ruby
class CourseSessionsProcessor < Rubanok::Processor
  SORT_ORDERS = %w[asc desc].freeze
  SORTABLE_FIELDS = %w[id name created_at].freeze

  match :sort_by, :sort do
    having "course_id", "desc" do
      raw.joins(:courses).order("courses.id desc nulls last")
    end

    having "course_id", "asc" do
      raw.joins(:courses).order("courses.id asc nulls first")
    end

    # Match any value for the second arg
    having "type" do |sort: "asc"|
      # Prevent SQL injections
      raise "Possible injection: #{sort}" unless SORT_ORDERS.include?(sort)
      raw.joins(:course_type).order("course_types.name #{sort}")
    end

    # Match any value
    default do |sort_by:, sort: "asc"|
      raise "Possible injection: #{sort}" unless SORT_ORDERS.include?(sort)
      raise "The field is not sortable: #{sort_by}" unless SORTABLE_FIELDS.include?(sort_by)
      raw.order(sort_by => sort)
    end
  end

  # strict matching; if Processor will not match parameter, it will raise Rubanok::UnexpectedInputError
  # You can handle it in controller, for example, with sending 422 Unprocessable Entity to client
  match :filter, fail_when_no_matches: true do
    having "active" do
      raw.active
    end

    having "finished" do
      raw.finished
    end
  end
end
```

By default, Rubanok will not fail if no matches found in `match` rule. You can change it by setting: `Rubanok.fail_when_no_matches = true`.
If in example above you will call `CourseSessionsProcessor.call(CourseSession, filter: 'acitve')`, you will get `Rubanok::UnexpectedInputError: Unexpected input: {:filter=>'acitve'}`.

**NOTE:** Rubanok only matches exact values; more complex matching could be added in the future.

### Default transformation

Sometimes it's useful to perform some transformations before **any** rule is activated.

There is a special `prepare` method which allows you to define the default transformation:

```ruby
class CourseSearchQueryProcessor < Rubanok::Processor
  prepare do
    next if raw&.dig(:query, :bool)

    {query: {bool: {filters: []}}}
  end

  map :ids do |ids:|
    raw.dig(:query, :bool, :filters) << {terms: {id: ids}}
    raw
  end
end
```

The block should return a new initial value for the _raw_ input or `nil` (no transformation required).

The `prepare` callback is not executed if no params match, e.g.:

```ruby
CourseSearchQueryProcessor.call(nil, {}) #=> nil

# But
CourseSearchQueryProcessor.call(nil, {ids: [1]}) #=> {query {bool: {filters: [{terms: {ids: [1]}}]}}}

# Note that we can omit the first argument altogether
CourseSearchQueryProcessor.call({ids: [1]})
```

### Getting the matching params

Sometimes it could be useful to get the params that were used to process the data by Rubanok processor (e.g., you can use this data in views to display the actual filters state).

In Rails, you can use the `#rubanok_scope` method for that:

```ruby
class CourseSessionController < ApplicationController
  def index
    @sessions = rubanok_process(CourseSession.all)
    # Returns the Hash of params recognized by the CourseSessionProcessor.
    # For example:
    #
    #    params == {q: "search", role_id: 2, date: "2019-08-22"}
    #    @session_filter == {q: "search", role_id: 2}
    @sessions_filter = rubanok_scope(
      params.permit(:q, :role_id),
      with: CourseSessionProcessor
    )

    # You can omit all the arguments
    @sessions_filter = rubanok_scope #=> equals to rubanok_scope(params, with: implicit_rubanok_class)
  end
end
```

You can also accesss `rubanok_scope` in views (it's a helper method).

### Rule activation

Rubanok _activates_ a rule by checking whether the corresponding keys are present in the params object. All the fields must be present to apply the rule.

Some fields may be optional, or perhaps even all of them. You can use `activate_on` and `activate_always` options to mark something as an optional key instead of a required one:

```ruby
# Always apply the rule; use default values for keyword args
map :page, :per_page, activate_always: true do |page: 1, per_page: 2|
  raw.page(page).per(per_page)
end

# Only require `sort_by` to be preset to activate sorting rule
match :sort_by, :sort, activate_on: :sort_by do
 # ...
end
```

By default, Rubanok ignores empty param values (using `#empty?` under the hood) and will not run matching rules on those values. For example: `{ q: "" }` and `{ q: nil }` won't activate the `map :q` rule.

You can change this behaviour by specifying `ignore_empty_values: true` option for a particular rule or enabling this behaviour globally via `Rubanok.ignore_empty_values = true` (enabled by default).

### Input values filtering

For complex input types, such as arrays, it might be useful to _prepare_ the value before passing to a transforming block or prevent the activation altogether.

We provide a `filter_with:` option for the `.map` method, which could be used as follows:

```ruby
class PostsProcessor < Rubanok::Processor
  # We can pass a Proc
  map :ids, filter_with: ->(vals) { vals.reject(&:blank?).presence } do |ids:|
    raw.where(id: ids)
  end

  # or define a class method
  def self.non_empty_array(val)
    non_blank = val.reject(&:blank?)
    return if non_blank.empty?

    non_blank
  end

  # and pass its name as a filter_with value
  map :ids, filter_with: :non_empty_array do |ids:|
    raw.where(id: ids)
  end
end

# Filtered values are used in rules
PostsProcessor.call(Post.all, {ids: ["1", ""]}) == Post.where(id: ["1"])

# When filter returns empty value, the rule is not applied
PostsProcessor.call(Post.all, {ids: [nil, ""]}) == Post.all
```

### Testing

One of the benefits of having modification logic contained in its own class is the ability to test modifications in isolation:

```ruby
# For example, with RSpec
RSpec.describe CourseSessionsProcessor do
  let(:input) { CourseSession.all }
  let(:params) { {} }

  subject { described_class.call(input, params) }

  specify "searching" do
    params[:q] = "wood"

    expect(subject).to eq input.search("wood")
  end
end
```

Now in your controller you only have to test that the specific _plane_ is applied:

```ruby
RSpec.describe CourseSessionController do
  subject { get :index }

  specify do
    expect { subject }.to have_rubanok_processed(CourseSession.all)
      .with(CourseSessionsProcessor)
  end
end
```

**NOTE**: input matching only checks for the class equality.

To use `have_rubanok_processed` matcher you must add the following line to your `spec_helper.rb` / `rails_helper.rb` (it's added automatically if RSpec defined and `RAILS_ENV`/`RACK_ENV` is equal to `"test"`):

```ruby
require "rubanok/rspec"
```

### Rails vs. non-Rails

Rubanok does not require Rails, but it has some useful Rails extensions such as `rubanok_process` helper for controllers (included automatically into `ActionController::Base` and `ActionController::API`).

If you use `ActionController::Metal` you must include the `Rubanok::Controller` module yourself.

### Processor class inference in Rails controllers

By default, `rubanok_process` uses the following algorithm to define a processor class: `"#{controller_path.classify.pluralize}Processor".safe_constantize`.

You can change this by overriding the `#implicit_rubanok_class` method:

```ruby
class ApplicationController < ActionController::Smth
  # override the `implicit_rubanok_class` method
  def implicit_rubanok_class
    "#{controller_path.classify.pluralize}Scoper".safe_constantize
  end
end
```

Now you can use it like this:

```ruby
class CourseSessionsController < ApplicationController
  def index
    @sessions = rubanok_process(CourseSession.all, params)
    # which equals to
    @sessions = CourseSessionsScoper.call(CourseSession.all, params.to_unsafe_h)
  end
end
```

**NOTE:** the `planish` method is still available and it uses `#{controller_path.classify.pluralize}Plane".safe_constantize` under the hood (via the `#implicit_plane_class` method).

## Using with RBS/Steep

_Read ["Climbing Steep hills, or adopting Ruby 3 types with RBS"](https://evilmartians.com/chronicles/climbing-steep-hills-or-adopting-ruby-types) for the context._

Rubanok comes with Ruby type signatures (RBS).

To use them with Steep, add `library "rubanok"` to your Steepfile.

Since Rubanok provides DSL with implicit context switching (via `instance_eval`), you need to provide type hints for the type checker to help it
figure out the current context. Here is an example:

```ruby
class MyProcessor < Rubanok::Processor
  map :q do |q:|
    # @type self : Rubanok::Processor
    raw
  end

  match :sort_by, :sort, activate_on: :sort_by do
    # @type self : Rubanok::DSL::Matching::Rule
    having "status", "asc" do
      # @type self : Rubanok::Processor
      raw
    end

    # @type self : Rubanok::DSL::Matching::Rule
    default do |sort_by:, sort: "asc"|
      # @type self : Rubanok::Processor
      raw
    end
  end
end
```

Yeah, a lot of annotations 😞 Welcome to the type-safe world!

## Questions & Answers

- **Where to put my processor/plane classes?**

I put mine under `app/planes` (as `<resources>_plane.rb`) in my Rails app.

- **I don't like the naming ("planes" ✈️?), can I still use the library?**

Good news—the default naming [has been changed](https://github.com/palkan/rubanok/pull/8). "Planes" are still available if you prefer them (just like me 😉).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/palkan/rubanok.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
