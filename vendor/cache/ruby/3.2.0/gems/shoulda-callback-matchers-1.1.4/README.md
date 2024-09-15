#Shoulda Callback Matchers
[![Gem Version](https://badge.fury.io/rb/shoulda-callback-matchers.svg)](http://badge.fury.io/rb/shoulda-callback-matchers) [![Build Status](https://travis-ci.org/beatrichartz/shoulda-callback-matchers.svg?branch=master)](https://travis-ci.org/beatrichartz/shoulda-callback-matchers) [![Code Climate](https://codeclimate.com/github/beatrichartz/shoulda-callback-matchers.png)](https://codeclimate.com/github/beatrichartz/shoulda-callback-matchers) [![Dependency Status](https://gemnasium.com/beatrichartz/shoulda-callback-matchers.svg)](https://gemnasium.com/beatrichartz/shoulda-callback-matchers)

Matchers to test before, after and around hooks(currently supports method and object callbacks):

# New maintainer wanted
If you fancy maintaining this gem, tweet [@beatrichartz](https://twitter.com/intent/tweet?text=%40beatrichartz&source=webclient) and I'll transfer it to you!

## Usage

Method Callbacks:

````ruby
describe Post do
  it { is_expected.to callback(:count_comments).before(:save) }
  it { is_expected.to callback(:post_to_twitter).after(:create) }
  it { is_expected.to callback(:evaluate_if_is_should_validate).before(:validation) }
  it { is_expected.to callback(:add_some_convenience_accessors).after(:find) }

  # with conditions

  it { is_expected.to callback(:assign_something).before(:create).if(:this_is_true) }
  it { is_expected.to callback(:destroy_something_else).before(:destroy).unless(:this_is_true) }
end

describe User do
  it { is_expected.not_to callback(:make_email_validation_ready!).before(:validation).on(:update) }
  it { is_expected.to callback(:make_email_validation_ready!).before(:validation).on(:create) }
  it { is_expected.to callback(:update_user_count).before(:destroy) }
end
````

Object Callbacks:

````ruby
class CallbackClass
  def before_save
	...
  end

  def after_create
	...
  end

  def before_validation
	...
  end

  def after_find
	...
  end
end

describe Post do
  it { is_expected.to callback(CallbackClass).before(:save) }
  it { is_expected.to callback(CallbackClass).after(:create) }
  it { is_expected.to callback(CallbackClass).before(:validation) }
  it { is_expected.to callback(CallbackClass).after(:find) }

	# with conditions
  it { is_expected.to callback(CallbackClass).before(:create).if(:this_is_true) }
  it { is_expected.to callback(CallbackClass).after(:find).unless(:is_this_true?) }
end

describe User do
  it { is_expected.not_to callback(CallbackClass).before(:validation).on(:update) }
  it { is_expected.to callback(CallbackClass).before(:validation).on(:create) }
  it { is_expected.to callback(CallbackClass).before(:destroy) }
end
````

This will test:
- the method call
- method existence

Either on the model itself or on the callback object. Be aware that obviously this does not test the callback method or object itself. It makes testing via triggering the callback events (validation, save) unnecessary, but you still have to test the called procedure seperately.

In Rails 3 or 4 and Bundler, add the following to your Gemfile:

````ruby
group :test do
  gem 'shoulda-callback-matchers', '~> 1.1.1'
end
````

This gem uses semantic versioning, so you won't have incompability issues with patches.

rspec-rails needs to be in the development group so that Rails generators work.

````ruby
group :development, :test do
  gem "rspec-rails"
end
````

Shoulda will automatically include matchers into the appropriate example groups.

## Troubleshooting

### RSpec + Spring
#### undefined method `callback'

If you're getting this error, it's probably due to classes being redefined by Spring - currently this library does not accommodate for reloaded classes. The easiest fix is to load the matchers into the test library config in your `rails_helper.rb`:

```ruby
RSpec.configure do |config|
  config.include(Shoulda::Callback::Matchers::ActiveModel)
end
```

## Credits

This gem is maintained by me and its contributors,
Shoulda is maintained and funded by [thoughtbot](http://thoughtbot.com/community)

## Contributors & Contributions
- @pvertenten (callback objects)
- @johnnyshields (bugfixes)
- @esbarango (README updates)
- @yuku-t (Rails 4.2 Support)

Let's make this gem useful, send me a PR if you've discovered an issue you'd like to fix!

## License

Shoulda is Copyright © 2006-2014 thoughtbot, inc.
Callback Matchers is Copyright © 2014 Beat Richartz
It is free software, and may be redistributed under the terms specified in the MIT-LICENSE file.
