RMagick Contributor's Guide
===========================

Welcome
-------

Thank you for considering contributing to RMagick. Your contribution is always welcome and appreciated!

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.


Background
----------

RMagick is a Ruby gem with a C extension. The extension wraps the ImageMagick C library. Therefore, the following document may be helpful to you:

[Running C in Ruby](http://silverhammermba.github.io/emberb/extend/)


Priorities
----------

1.  [Open issues][open-issues]. You are welcome to reproduce them, report
  current state, suggest solutions, open pull requests with fixes. If you
  don't know where to start, sort issues by least recently updated. You can
  also [subscribe to receive random issues by email][codetriage].

2.  [CodeClimate Issues][codeclimate-issues]. You can install [CodeClimate
  Browser Extension][codeclimate-extension] to see them right on GitHub.


Testing
-------

Our goal is to migrate to [RSpec](http://rspec.info).

If you write new tests, please do it in RSpec.

You are also welcome to convert existing Test/Unit tests to RSpec.

Run all tests:

    bundle exec rake

It will run RSpec and Minitest tests.

Useful information about RSpec:
* [Better Specs](http://www.betterspecs.org/) — how to write RSpec tests better
* [RSpec matchers cheat sheet](http://cheatrags.com/rspec-matchers) - how to use RSpec matchers to test different things


Committing
----------

It is better if you follow [Git Style Guide](https://github.com/agis-/git-style-guide).


Pull Requests
-------------

Please choose the `rmagick/rmagick` repo as the destination for your pull
request. GitHub may suggest `rmagick-temp/rmagick` repo by default. **This is
incorrect.** Please switch to `rmagick/rmagick`. It should be the next repo in
the drop-down list.

Every pull request is tested on GitHub Actions to cover Linux builds and Windows builds.
It runs all tests on several Ruby and ImageMagick versions.

A quick way to fix formatting errors is to run `bundle exec rubocop --autocorrect path/to/file.rb`.

If you add new classes or methods, please add tests for them as well.
RSpec is preferred (see above).
Tests should test all possible branches of code execution (all conditions in `if`/`case` statements, etc.) to avoid errors later.

Thanks
------

[open-issues]: https://github.com/rmagick/rmagick/issues
[codetriage]: http://www.codetriage.com/rmagick/rmagick
[codeclimate-issues]: https://codeclimate.com/github/rmagick/rmagick/issues
[codeclimate-extension]: https://docs.codeclimate.com/docs/browser-extension
