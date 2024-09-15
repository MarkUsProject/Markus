# js_cookie_rails

[![Gem Version](https://badge.fury.io/rb/js_cookie_rails.svg)](http://badge.fury.io/rb/js_cookie_rails)

js_cookie_rails wraps the [js-cookie](https://github.com/js-cookie/js-cookie)
library in a rails engine for simple use with the asset pipeline provided by
Rails 3.1 and higher. The gem includes the development (non-minified) source
for ease of exploration. The asset pipeline will minify in production.

JavaScript Cookie is a "simple, lightweight JavaScript API for handling cookies."
Please see [js-cookie](https://github.com/js-cookie/js-cookie) for details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'js_cookie_rails'
```

And then execute:

    $ bundle

Add the following directive to your Javascript manifest file (application.js):

    //= require js.cookie

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/freego/js_cookie_rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

