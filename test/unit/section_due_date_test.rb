# Context architecture

require File.join(File.dirname(__FILE__),'/../test_helper')
require File.join(File.dirname(__FILE__),'/../blueprints/blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require 'shoulda'

class SectionTest < ActiveSupport::TestCase

  def setup
    clear_fixtures
  end

  context "An assignment with section due dates" do
    setup do
      @section = Section.make
      @now = DateTime.now
      @assignment = Assignment.make(:section_due_dates_type => true)
      SectionDueDate.make(:assignment => @assignment,
                          :section => @section,
                          :due_date => @now + 3)
    end

    should "return the due date for that section and assignment" do
      assert_equal (@now + 3).day(),
                    SectionDueDate.due_date_for(@section, @assignment).day()
    end
  end

end



