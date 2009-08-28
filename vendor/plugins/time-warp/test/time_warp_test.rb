require File.dirname(__FILE__) + '/test_helper.rb'

class TimeWarpTest < Test::Unit::TestCase
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
end
