require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'

include MarkusConfigurator

class TATest < ActiveSupport::TestCase

  def teardown
    destroy_repos
  end

  # Update tests ---------------------------------------------------------

  # These tests are for the CSV/YML upload functions.  They're testing
  # to make sure we can easily create/update users based on their user_name

  # Test if user with a unique user number has been added to database

  context 'A ta with a membership' do
    setup do
      @assignment = Assignment.make
      @ta = Ta.make
      @grouping = Grouping.make(assignment: @assignment)
      TaMembership.make(grouping: @grouping,
                        user: @ta)
    end


    should "get TA's memberships for one assignment" do
      assert_not_nil @ta.memberships_for_assignment(@assignment)
    end

    should 'already be assigned to a grouping' do
      assert @ta.is_assigned_to_grouping?(@grouping.id)
    end
  end
end
