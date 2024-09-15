# Shoulda Context [![Gem Version][version-badge]][rubygems] [![Build Status][travis-badge]][travis] ![Downloads][downloads-badge] [![Hound][hound-badge]][hound]

[version-badge]: https://img.shields.io/gem/v/shoulda-context.svg
[rubygems]: https://rubygems.org/gems/shoulda-context
[travis-badge]: https://img.shields.io/travis/thoughtbot/shoulda-context/master.svg
[travis]: https://travis-ci.org/thoughtbot/shoulda-context
[downloads-badge]: https://img.shields.io/gem/dtv/shoulda-context.svg
[hound-badge]: https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg
[hound]: https://houndci.com

Shoulda Context makes it easy to write understandable and maintainable tests
under Minitest and Test::Unit within Rails projects or plain Ruby projects. It's
fully compatible with your existing tests and requires no retooling to use.

## Quick links

📖 **[Read the documentation for the latest version.][rubydocs]**
📢 **[See what's changed in recent versions.][changelog]**

[rubydocs]: http://rubydoc.info/github/thoughtbot/shoulda-context/master/frames
[changelog]: CHANGELOG.md

[shoulda-context]: https://github.com/thoughtbot/shoulda-context

## Getting started

If you're working on a Rails app, then make sure to add this gem to the `test`
group in your Gemfile:

``` ruby
group :test do
  gem 'shoulda-context', '~> 3.0.0.rc1'
end
```

If you're not working on a Rails app, then you can simply add:

``` ruby
gem 'shoulda-context', '~> 3.0.0.rc1'
```

Then run `bundle install`.

## Overview

Instead of writing Ruby methods with `lots_of_underscores`, Shoulda Context lets
you name your tests and group them together using English.

At a minimum, the gem provides some convenience layers around core Minitest /
Test::Unit functionality. For instance, this test case:

```ruby
class CalculatorTest < Minitest::Test
  context "a calculator" do
    setup do
      @calculator = Calculator.new
    end

    should "add two numbers for the sum" do
      assert_equal 4, @calculator.sum(2, 2)
    end

    should "multiply two numbers for the product" do
      assert_equal 10, @calculator.product(2, 5)
    end
  end
end
```

turns into:

```ruby
class CalculatorTest < Minitest::Test
  def setup
    @calculator = Calculator.new
  end

  define_method "test_: a calculator should add two numbers for the sum" do
    assert_equal 4, @calculator.sum(2, 2)
  end

  define_method "test_: a calculator should multiply two numbers for the product" do
    assert_equal 10, @calculator.product(2, 5)
  end
end
```

However, Shoulda Context also provides functionality apart from Minitest /
Test::Unit that allows you to shorten tests drastically by making use of
RSpec-compatible matchers. For instance, with [Shoulda
Matchers][shoulda-matchers] you can write such tests as:

```ruby
class User < ActiveSupport::TestCase
  context "validations" do
    subject { FactoryBot.build(:user) }

    should validate_presence_of(:first_name)
    should validate_presence_of(:last_name)
    should validate_uniqueness_of(:email)
    should_not allow_value('weird').for(:email)
  end
end
```

[shoulda-matchers]: https://github.com/thoughtbot/shoulda-matchers

## API

### DSL

The primary method in Shoulda Context's API is `context`, which declares a group
of a tests.

These methods are available inside of a `context`:

* `setup` — a DSL-y alternative to defining a `setup` method
* `teardown` — a DSL-y alternative to defining a `teardown` method
* `should` — There are two forms:
  1. when passed a name + block, creates a test equivalent to defining a
  `test_` method
  2. when passed a matcher, creates a test that will run the matcher, asserting
  that it passes
* `should_not` — like the matcher version of `should`, but creates a test that
  asserts that the matcher fails
* `should_eventually` — allows you to temporarily skip tests
* `context` — creates a subcontext

These methods are available within a test case class, but outside of a
`context`:

* `should` — same as above
* `should_not` — same as above
* `should_eventually` — same as above
* `described_type` — returns the class being tested, as determined by the class
  name of the outermost class
* `subject` — lets you define an object that is the primary focus of the tests
  within a context; this is most useful when using a matcher as the matcher will
  make use of this as _its_ subject

And these methods are available inside of a test (whether defined via a method
or via `should`):

* `subject` — an instance of the class under test, which is derived
  automatically from the name of the test case class but is overridable via the
  class method version of `subject` above

### Assertions

In addition to the main API, the gem also provides some extra assertions that
may be of use:

* `assert_same_elements` — compares two arrays for equality, but ignoring
  ordering
* `assert_contains` — asserts that an array has an item
* `assert_does_not_contain` — the opposite of `assert_contains`
* `assert_accepts` — what `should` uses internally; asserts that a matcher
  object matches against a value
* `assert_reject` — what `should_not` uses internally; asserts that a matcher
  object does not match against a value

## Compatibility

Shoulda Context is [tested][travis] and supported against Ruby 2.7+, Rails 6.0+,
Minitest 4.x, and Test::Unit 3.x.

## Versioning

Shoulda Context follows Semantic Versioning 2.0 as defined at
<http://semver.org>.

## Team

Shoulda Context is currently maintained by [Pedro Paiva][VSPPedro]. Previous
maintainers include [Elliot Winkler][mcmire], [Travis Jeffery][travisjeffery],
[Gabe Berke-Williams][gabebw], [Ryan McGeary][rmm5t], [Joe Ferris][jferris], [Dan
Croaky][croaky], and [Tammer Saleh][tammersaleh].

[VSPPedro]: https://github.com/VSPPedro
[mcmire]: https://github.com/mcmire
[travisjeffery]: https://github.com/travisjeffery
[gabebw]: https://github.com/gabebw
[rmm5t]: https://github.com/rmm5t
[jferris]: https://github.com/jferris
[croaky]: https://github.com/croaky
[tammersaleh]: https://github.com/tammersaleh

## Copyright/License

Shoulda Context is copyright © Tammer Saleh and [thoughtbot,
inc][thoughtbot-website]. It is free and opensource software and may be
redistributed under the terms specified in the [LICENSE](LICENSE) file.

[thoughtbot-website]: https://thoughtbot.com?utm_source=github

<!-- START /templates/footer.md -->
## About thoughtbot

![thoughtbot](https://thoughtbot.com/thoughtbot-logo-for-readmes.svg)

This repo is maintained and funded by thoughtbot, inc.
The names and logos for thoughtbot are trademarks of thoughtbot, inc.

We love open source software!
See [our other projects][community].
We are [available for hire][hire].

[community]: https://thoughtbot.com/community?utm_source=github
[hire]: https://thoughtbot.com/hire-us?utm_source=github


<!-- END /templates/footer.md -->
