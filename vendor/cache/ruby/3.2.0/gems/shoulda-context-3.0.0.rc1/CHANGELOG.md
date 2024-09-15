# Changelog

## 3.0.0.rc1 - 2024-04-21

### Backward-incompatible changes

* Drop support for Ruby 2.5 and 2.6 by @vsppedro. Ruby 2.7.x is the only version supported now. ([#76], [#77], [#78])
* Drop support for Rails 4.2, 5.0, 5.1 and 5.2 by @vsppedro. Rails 6.0.x and Rails 6.1.x are the only versions supported now. ([#79], [#80], [#81], [#82])

[#74]: https://github.com/thoughtbot/shoulda-context/pull/74
[#76]: https://github.com/thoughtbot/shoulda-context/pull/76
[#77]: https://github.com/thoughtbot/shoulda-context/pull/77
[#78]: https://github.com/thoughtbot/shoulda-context/pull/78
[#79]: https://github.com/thoughtbot/shoulda-context/pull/79
[#80]: https://github.com/thoughtbot/shoulda-context/pull/80
[#81]: https://github.com/thoughtbot/shoulda-context/pull/81
[#82]: https://github.com/thoughtbot/shoulda-context/pull/82

### Bug fixes

* Fix broken thoughtbot logo on README.md by @sarahraqueld. ([#0551d18c92eebd94db70917d668202508b7d2268])
* Use proper source location for should calls without a block by @segiddins. ([#92])
* Fix the link to the gem on Rubygems in the README by @mcmire and @0xRichardH. ([#1098f5beb9b49a9d88434f6b3b6ccb58b2dfe93f])
* Fix a method redefinition warning by @Earlopain. ([#94])

[#0551d18c92eebd94db70917d668202508b7d2268]: https://github.com/thoughtbot/shoulda-context/commit/0551d18c92eebd94db70917d668202508b7d2268
[#92]: https://github.com/thoughtbot/shoulda-context/pull/92
[#94]: https://github.com/thoughtbot/shoulda-context/pull/94

### Features

* Add support for Rails 6.1 by @vsppedro. ([#84])

[#84]: https://github.com/thoughtbot/shoulda-context/pull/84

### Improvements

* Update README for consistency across all shoulda-* gems by @mcmire. ([#5da1895f6c9917bc2aa0a248c209edb453a1340e])
* Bump warnings_logger to 0.1.1 by @mcmire. ([#970d3d57a584ecb2652f0bc7188761024de16c52])
* Add 'Getting started' section to the README by @mcmire. ([#52915f3a3cb36ae0494cfbacccc162b95932ca24])
* Switch to Github Actions by @vsppedro. ([#74], [#83])
* Do fewer intermediary allocations when calculating test methods by @segiddins. ([#89])
* Call dynamic-readme reusable workflow by @stefannibrasil. ([#95])

[#5da1895f6c9917bc2aa0a248c209edb453a1340e]: https://github.com/thoughtbot/shoulda-context/commit/5da1895f6c9917bc2aa0a248c209edb453a1340e
[#970d3d57a584ecb2652f0bc7188761024de16c52]: https://github.com/thoughtbot/shoulda-context/commit/970d3d57a584ecb2652f0bc7188761024de16c52
[#52915f3a3cb36ae0494cfbacccc162b95932ca24]: https://github.com/thoughtbot/shoulda-context/commit/52915f3a3cb36ae0494cfbacccc162b95932ca24
[#1098f5beb9b49a9d88434f6b3b6ccb58b2dfe93f]: https://github.com/thoughtbot/shoulda-context/commit/1098f5beb9b49a9d88434f6b3b6ccb58b2dfe93f
[#83]: https://github.com/thoughtbot/shoulda-context/pull/83
[#89]: https://github.com/thoughtbot/shoulda-context/pull/89
[#95]: https://github.com/thoughtbot/shoulda-context/pull/95

## 2.0.0 (2020-06-13)

### Backward-incompatible changes

* Drop support for RSpec 2 matchers. Matchers passed to `should` must conform
  to RSpec 3's API (`failure_message` and `failure_message_when_negated`).
* Drop support for older versions of Rails. Rails 4.x-6.x are the
  only versions supported now.
* Drop support for older versions of Ruby. Ruby 2.4.x-2.7.x are the only
  versions supported now.

### Bug fixes

* Fix how test names are generated so that when including the name of the
  outermost test class, "Test" is not removed from the class name if it does not
  fall at the end.
* Remove warning from Ruby about `context` not being used when using the gem
  with warnings enabled.
* Fix macro autoloading code. Files intended to hold custom macros which are
  located in either `test/shoulda_macros`, `vendor/gems/*/shoulda_macros`, or
  `vendor/plugins/*/shoulda_macros` are now loaded and mixed into your test
  framework's automatically.
* Restore compatibility with Shoulda Matchers, starting from 3.0.
* Fix some compatibility issues with Minitest 5.
* Fix running tests within a Rails < 5.2 environment so that when tests fail, an
  error is not produced claiming that Minitest::Result cannot find a test
  method.
