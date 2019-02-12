[![Gem Version](https://badge.fury.io/rb/rubanok.svg)](https://rubygems.org/gems/rubanok) [![Build Status](https://travis-ci.org/palkan/rubanok.svg?branch=master)](https://travis-ci.org/palkan/rubanok)

# Rubanok

Rubanok provides a DSL to build parameters-based data transformers.

📖 Read the introduction post: ["Carve your controllers like Papa Carlo"](https://dev.to/evilmartians/carve-your-controllers-like-papa-carlo-32m6")

The typical usage is to describe all the possible collection manipulation for REST `index` action, e.g. filtering, sorting, searching, pagination, etc..

So, instead of:

```ruby
class CourseSessionController < ApplicationController
  def index
    @sessions = CourseSession.
                  search(params[:q]).
                  by_course_type(params[:course_type_id]).
                  by_role(params[:role_id]).
                  paginate(page_params).
                  order(ordering_params)
  end
end
```

You have:

```ruby
class CourseSessionController < ApplicationController
  def index
    @sessions = planish(
      # pass input
      CourseSession.all,
      # pass params
      params,
      # provide a plane to use
      with: CourseSessionsPlane
    )
  end
end
```

Or we can try to infer all the configuration for you:


```ruby
class CourseSessionController < ApplicationController
  def index
    @sessions = planish(CourseSession.all)
  end
end
```

Requirements:
- Ruby ~> 2.5
- Rails >= 4.2 (only for using with Rails)

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Installation

Add to your `Gemfile`:

```ruby
gem "rubanok"
```

And run `bundle install`.

## Usage

The core concept of this library is a _plane_ (or _hand plane_, or "рубанок" in Russian). Plane is responsible for mapping parameters to transformrations.

From the example above:

```ruby
class CourseSessionsPlane < Rubanok::Plane
  # You can map keys
  map :q do |q:|
    # `raw` is an accessor for input data
    raw.search(q)
  end
end

# The following code
CourseSessionsPlane.call(CourseSession.all, q: "xyz")

# is equal to
CourseSession.all.search("xyz")
```

You can map multiple keys at once:

```ruby
class CourseSessionsPlane < Rubanok::Plane
  DEFAULT_PAGE_SIZE = 25

  map :page, :per_page do |page:, per_page: DEFAULT_PAGE_SIZE|
    raw.paginate(page: page, per_page: per_page)
  end
end
```

There is also `match` method to handle values:

```ruby
class CourseSessionsPlane < Rubanok::Plane
  SORT_ORDERS = %w(asc desc).freeze
  SORTABLE_FIELDS = %w(id name created_at).freeze

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
end
```

**NOTE:** matching only match the exact values; more complex matching could be added in the future.

### Rule activation

Rubanok _activates_ a rule by checking whether the corresponding keys are present in the params object. All the fields must be present to apply the rule.

Sometimes you might want to make some fields optional (or event all of them). You can use `activate_on` and `activate_always` options for that:

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

By default, Rubanok ignores empty param values (using `#empty?` under the hood) and do not activate the matching rules (i.e. `{ q: "" }` or `{ q: nil }` won't activate the `map :q` rule).

You can change this behaviour by setting: `Rubanok.ignore_empty_values = false`.

### Testing

One of the benefits of having all the modification logic in its own class is the ability to test it in isolation:

```ruby
# For example, with RSpec
describe CourseSessionsPlane do
  let(:input ) { CourseSession.all }
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
describe CourseSessionController do
  subject { get :index }

  specify do
    expect { subject }.to have_planished(CourseSession.all).
      with(CourseSessionsPlane)
  end
end
```

**NOTE**: input matching only checks for the class equality.

To use `have_planished` matcher you must add the following line to your `spec_helper.rb` / `rails_helper.rb` (it's added automatically if RSpec defined and `RAILS_ENV`/`RACK_ENV` is equal to `"test"`):

```ruby
require "rubanok/rspec"
```

### Rails vs. non-Rails

Rubanok is a Rails-free library but has some useful Rails extensions, such as `planish` helper for controllers (included automatically into `ActionController::Base` and `ActionController::API`).

If you use `ActionController::Metal` you must include the `Rubanok::Controller` module yourself.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/palkan/rubanok.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
