# Change log

## master

## 0.5.0 (2023-12-04)

- Add nested processors support. ([@palkan][])

## 0.4.0 (2021-03-05)

- Ruby 3.0 compatibility. ([@palkan][])

- Add RBS. ([@palkan][])

## 0.3.0 (2020-10-21)

- Add `filter_with: Symbol | Proc` option to `.map` to allowing filtering the input value. ([@palkan][])

- Allow specifying `ignore_empty_values: *` per rule. ([@palkan][])

- Add `prepare` DSL method to transform the input once before the first rule is activated. ([@palkan][])

When no rules match, the method is not called.
Useful when you want to perform some default transformations.

## 0.2.1 (2019-08-24)

- Fix bug with trying to add a helper for API controller. ([@palkan][])

Fixes [#10](https://github.com/palkan/rubanok/issues/10).

## 0.2.0 (2019-08-23)

- Add `Process.project` and `rubanok_scope` methods to get the Hash of recognized params. ([@palkan][])

```ruby
class PostsProcessor < Rubanok::Processor
  map(:q) { block }
  match(:page, :per_page, activate_on: :page) { block }
end

PostsProcessor.project(q: "search_me", filter: "smth", page: 2)
# => { q: "search_me", page: 2 }

class PostsController < ApplicationController
  def index
    @filter_params = rubanok_scope
    # or
    @filter_params = rubanok_scope params.require(:filter), with: PostsProcessor
    # ...
  end
end
```

- Improve naming by using "processor" instead of "plane". ([@palkan][])

See [the discussion](https://github.com/palkan/rubanok/issues/3).

**NOTE**: Older API is still available without deprecation.

- Add `fail_when_no_matches` parameter to `match` method. ([@Earendil95][])

## 0.1.3 (2019-03-05)

- Fix using `activate_always: true` with `default` matching clause. ([@palkan][])

## 0.1.1 (2019-01-16)

- Fix RSpec matcher to call original implementation instead of returning `nil`. ([@palkan][])

## 0.1.0 (2019-01-04)

Initial implementation.

## 0.0.1 (2018-12-07)

Proposal added.

[@palkan]: https://github.com/palkan
[@Earendil95]: https://github.com/Earendil95
