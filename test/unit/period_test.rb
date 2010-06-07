# test using MACHINIST

require File.join(File.dirname(__FILE__),'/../test_helper')
require File.join(File.dirname(__FILE__),'/../blueprints/blueprints')
require File.join(File.dirname(__FILE__),'/../blueprints/helper')
require 'shoulda'

class PeriodTest < ActiveSupport::TestCase
  should_validate_presence_of :hours
  should_belong_to :submission_rule
  
  def setup
    clear_fixtures
  end  
  
  context "Valid grace period" do   
    setup do
      @period = Period.make
	end
	
    should "return true for valid grace periods" do
	  assert @period.valid?
    end		
  end

  context "Invalid grace period" do   
    setup do
	  @period = Period.make
	end
	
    should "return false for invalid grace periods" do
	  @period.hours = nil
	  assert !@period.valid?, "period expected to be invalid when hours is set to nil"
    end		
  end
      
end
