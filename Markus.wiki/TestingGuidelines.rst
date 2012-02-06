================================================================================
How we do Testing
================================================================================

*Note:* This document is outdated. As of December 2009 we have mocha, selenium
and cucumber integrated. Lots of available testing tools, which is good. More
later...

We use Thoughtbot Shoulda for our testing (see
http://thoughtbot.com/projects/shoulda](http://thoughtbot.com/projects/shoulda).

* [[Shoulda Tutorial | http://thoughtbot.com/projects/shoulda/tutorial]]
* [[Shoulda RDoc | http://rdoc.info/projects/thoughtbot/shoulda]]

How to configure
================================================================================

Run the following Rake tasks::

    #>rake gems:install
    #>rake gems:unpack

Multiple Rake tasks are used to run tests::

    #>rake db:test:prepare
    #>rake test
    #>rake test:units
    #>...


How to use it?
================================================================================

Very similar to Test::Unit::

      require 'shoulda'
      class QuoteTest < Test::Unit::TestCase
        def setup
          # normal Test::Unit setup stuff here
        end

        # standard Test::Unit test
        def test_should_be_true
          assert true
        end

        # shoulda 'should' test
        should "be true" do
          assert true
        end
      end

