# test using MACHINIST
require File.join(File.dirname(__FILE__), '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require 'shoulda'

class PeriodTest < ActiveSupport::TestCase
  should validate_presence_of :hours
  should have_db_column :interval
  should belong_to :submission_rule

  def setup
    clear_fixtures
  end

  context "A valid grace period" do
    setup do
      @period = Period.make
    end

    should "return true when a positive hour value is entered" do
      assert @period.valid?
    end
  end

  context "A valid grace period" do
    setup do
      @period = Period.make
    end

    should "return true when zero hours is entered" do
      @period.hours = 0
      assert @period.valid?
    end
  end

  context "An invalid grace period" do
    setup do
      @period = Period.make
    end

    should "return false when nil hours is entered" do
      @period.hours = nil
      assert !@period.valid?, "period expected to be invalid when hours is set to nil"
    end
  end

  context "An invalid grace period" do
    setup do
      @period = Period.make
    end

    should "return false when a negative hour value is entered" do
      @period.hours = -10
      assert !@period.valid?, "period expected to be invalid when hours is negative"
    end
  end

end
