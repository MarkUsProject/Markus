require "test_helper"

class TimeWarpTest < Minitest::Test
  def test_test_unit_test_case_should_respond_to_pretend_now_is
    assert_equal true, self.respond_to?(:pretend_now_is)
  end

  def test_pretend_now_is_should_set_now_back_in_time
    pretend_now_is(Time.utc(2008,"jul",25,6,15)) do #=> Fri Jul 25 06:15:00 UTC 2008
      assert_equal 2008, Time.now.utc.year
      assert_equal    7, Time.now.utc.month
      assert_equal   25, Time.now.utc.day
      assert_equal    6, Time.now.utc.hour
      assert_equal   15, Time.now.utc.min
    end
  end

  def test_pretend_now_is_should_set_now_forward_in_time
    future_year = Time.now.year + 1
    pretend_now_is(Time.utc(future_year,"jul",25,6,15)) do #=> Fri Jul 25 06:15:00 UTC future_year
      assert_equal future_year, Time.now.utc.year
      assert_equal           7, Time.now.utc.month
      assert_equal          25, Time.now.utc.day
      assert_equal           6, Time.now.utc.hour
      assert_equal          15, Time.now.utc.min
    end
  end

  def test_pretend_now_should_revert_to_real_now_after_block
    now        = Time.now
    now_year   = now.year
    now_month  = now.month
    now_day    = now.day
    now_hour   = now.hour
    now_minute = now.min

    pretend_now_is(Time.utc(2008,"jul",25,6,15)) do #=> Fri Jul 25 06:15:00 UTC 2008
      # block of code
    end

    assert_equal   now_year, Time.now.year
    assert_equal  now_month, Time.now.month
    assert_equal    now_day, Time.now.day
    assert_equal   now_hour, Time.now.hour
    assert_equal now_minute, Time.now.min
  end

  def test_pretend_now_resolves_to_the_same_value_regardless_of_setting_by_time_argument_or_time_utc_arguments
    now_with_time_argument = now_with_time_utc_arguments = nil
    pretend_now_is(Time.utc(2008,"jul",25,6,15)) do #=> Fri Jul 25 06:15:00 UTC 2008
      now_with_time_argument = Time.now.utc
    end
    pretend_now_is(2008,"jul",25,6,15) do           #=> Fri Jul 25 06:15:00 UTC 2008
      now_with_time_utc_arguments = Time.now.utc
    end
    assert_equal now_with_time_argument.to_s, now_with_time_utc_arguments.to_s
  end

  def test_pretend_now_without_a_block
    now        = Time.now
    now_year   = now.year
    now_month  = now.month
    now_day    = now.day
    now_hour   = now.hour
    now_minute = now.min

    pretend_now_is(Time.utc(2008,"jul",25,6,15))
    assert_equal 2008, Time.now.utc.year
    assert_equal    7, Time.now.utc.month
    assert_equal   25, Time.now.utc.day
    assert_equal    6, Time.now.utc.hour
    assert_equal   15, Time.now.utc.min
    reset_to_real_time

    assert_equal   now_year, Time.now.year
    assert_equal  now_month, Time.now.month
    assert_equal    now_day, Time.now.day
    assert_equal   now_hour, Time.now.hour
    assert_equal now_minute, Time.now.min
  end

  def test_pretend_now_with_an_object_that_responds_to_to_time
    # Date objects in rails have to_time methods, but without Rails, they don't so we fake it
    date = Object.new
    def date.to_time
      Time.utc(2008,"jul",25,0,0)
    end
    pretend_now_is(date) do #=> Fri Jul 25 00:00:00 UTC 2008
      assert_equal 2008, Time.now.utc.year
      assert_equal    7, Time.now.utc.month
      assert_equal   25, Time.now.utc.day
      assert_equal    0, Time.now.utc.hour
      assert_equal    0, Time.now.utc.min
    end
  end

  def test_pretend_now_with_date
    # Date.today returns the current date in local time, not UTC
    # use local time to test this instead
    pretend_now_is(Time.local(2008,"jul",25,6,15)) do #=> Fri Jul 25 06:15:00 2008 (local)
      assert_equal 2008, Date.today.year
      assert_equal    7, Date.today.month
      assert_equal   25, Date.today.day
    end
  end

  def test_pretend_now_with_date_time
    pretend_now_is(Time.utc(2008,"jul",25,6,15)) do #=> Fri Jul 25 06:15:00 UTC 2008
      date_time = DateTime.now.new_offset(0) # UTC DateTime
      assert_equal 2008, date_time.year
      assert_equal    7, date_time.month
      assert_equal   25, date_time.day
      assert_equal    6, date_time.hour
      assert_equal   15, date_time.min
    end
  end

  def test_pretend_now_with_inherited_time_class
    eval <<-EVAL
      class MyTime < Time
        def a_method_that_returns_one
          return 1
        end
      end
    EVAL
    pretend_now_is(Time.utc(2008,"jul",25,6,15)) do #=> Fri Jul 25 06:15:00 UTC 2008
      my_time = MyTime.now.utc
      assert_equal   2008, my_time.year
      assert_equal      7, my_time.month
      assert_equal     25, my_time.day
      assert_equal      6, my_time.hour
      assert_equal     15, my_time.min
      assert_equal MyTime, my_time.class
      assert_equal      1, my_time.a_method_that_returns_one
    end
  end

  def test_time_constructor_with_arguments
    time = ::Time.new(2005, 11, 10, 12, 0, 2, 0)

    assert_equal 2005, time.year
    assert_equal 11,   time.month
    assert_equal 10,   time.day
    assert_equal 12,   time.hour
    assert_equal 0,    time.min
    assert_equal 0,    time.utc_offset
  end
end
