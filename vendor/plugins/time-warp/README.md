### time_warp

When writing tests, it is often desirable to bend time in order to test limits and edges of the day.  It is especially useful to warp time to test results across the timezones of the world.  Manipulating time is also useful to assure a day of the week, month or year every time the test runs.

Some may say "Why not just mock Time#now?"  I see the point, but I find mocking around with baseline Ruby classes to be asking for trouble.  Eventually unusual behavior will rear its head and a day will be lost debugging tests - the most excruciating debugging one can be subjected to.


### Installation

Plugin:

    $ script/plugin install git://github.com/iridesco/time_warp.git

Gem:

    $ gem sources -a http://gems.github.com
    $ sudo gem install iridesco-time-warp

Gem config in a Rails app.  environment.rb:

    config.gem 'iridesco-time-warp', :lib => 'time_warp', :source => "http://gems.github.com"

### Example

And now a contrived example.  In this case, the goal is to let the full mechanics of Rails execute.  Yes, this test will even hit the database! The goal is to assure a particular day of week when each test method executes:

    require File.dirname(__FILE__) + '/../test_helper'
    class CompanyTest < Test::Unit::TestCase

      def setup
        @company = companies(:acme)
      end

      def test_should_find_company_needing_reminded_today
        pretend_now_is(Time.utc(2008,"jul",24,20)) do #=> Thu Jul 24 20:00:00 UTC 2008
          @company.reminder_day = 'Thursday'
          @company.save
          companies = Company.find_companies_needing_reminded_today
          assert_equal true, companies.include?(@company)
        end
      end

      def test_should_not_find_company_needing_reminded_tomorrow
        pretend_now_is(Time.utc(2008,"jul",24,20)) do #=> Thu Jul 24 20:00:00 UTC 2008
          @company.reminder_day = 'Friday'
          @company.save
          companies = Company.find_companies_needing_reminded_today
          assert_equal false, companies.include?(@company)
        end
      end

      def test_should_not_find_company_needing_reminded_yesterday
        pretend_now_is(Time.utc(2008,"jul",24,20)) do #=> Thu Jul 24 20:00:00 UTC 2008
          @company.reminder_day = 'Wednesday'
          @company.save
          companies = Company.find_companies_needing_reminded_today
          assert_equal false, companies.include?(@company)
        end
      end
    end

### Notes

The pretend\_now\_is method may also be called with the arguments for the Time#utc call, rather than a Time argument.  So:

    pretend_now_is(Time.utc(2008,"jul",24,20)) do
      # Shifted code
    end
  
Becomes:

    pretend_now_is(2008,"jul",24,20) do
      # Shifted code
    end
  
Also, pretend\_now\_is should impact `ActiveSupport` generated `Date` extensions such as `Date.today`, `Date.tomorrow`, and so on.

Credits
=======

The creation of this plugin is a direct result of Jason M. Felice's snippet (and ensuing discussion).  The snippet can be found [at DZone](http://snippets.dzone.com/posts/show/1738).

Further discussion of this snippet's evolution may be found [at Barry Hess's blog](http://bjhess.com/blog/2007/08/12/time-warp-for-rails-testing/).

time_warp is maintained and funded by [Iridesco](http://iridesco.com).


Copyright (c) 2008 [Barry Hess](http://bjhess.com), [Iridesco](http://iridesco.com).  Released under the MIT license.
