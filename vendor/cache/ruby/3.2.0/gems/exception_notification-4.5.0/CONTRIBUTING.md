# How to contribute

We love your contribution, for it's essential for making ExceptionNotification greater every day.
In order to keep it as easy as possible to contribute changes, here are a few guidelines that we
need contributors to follow:

## First of all

* Check if the issue you're going to submit isn't already submitted in
  the [Issues](https://github.com/smartinez87/exception_notification/issues) page.

## Issues

* Submit a ticket for your issue, assuming one does not already exist.
* The issue must:
  * Clearly describe the problem including steps to reproduce when it is a bug.
  * Also include all the information you can to make it easier for us to reproduce it,
    like OS version, gem versions, etc...
  * Even better, provide a failing test case for it.

To help you add information to an issue, you can use the sample_app.
Steps to use sample_app:

1) Add your configuration to (ex. with webhook):
```ruby
config.middleware.use ExceptionNotification::Rack,
  # -----------------------------------
  # Change this with your configuration
  # https://github.com/smartinez87/exception_notification#notifiers
                        webhook: {
                          url: 'http://domain.com:5555/hubot/path'
                        }
  # -----------------------------------
```

2) Run `ruby examples/sample_app.rb`
If exception notification is working OK, the test should pass and trigger a notification as configured above. If it's not, you can copy the information printed on the terminal related to exception notification and report an issue with more info!

## Pull Requests

If you've gone the extra mile and have a patch that fixes the issue, you
should submit a Pull Request!

* Fork the repo on Github.
* Run Bundler and setup your test database

  ```
  bundle
  cd test/dummy
  bundle
  bundle exec rake db:reset db:test:prepare
  cd ../..
  bundle exec rake test
  ```
* Create a topic branch from where you want to base your work.
* Add a test for your change. Only refactoring and documentation changes
  require no new tests. If you are adding functionality or fixing a bug,
  we need a test!
* Run _all_ the tests to assure nothing else was broken. We only take pull requests with passing tests.
* Check for unnecessary whitespace with `git diff --check` before committing.
* Push to your fork and submit a pull request.
