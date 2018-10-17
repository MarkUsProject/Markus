# TODO
# These tests are for the CSV/YML upload functions.  They're testing
# to make sure we can easily create/update users based on their user_name.
# Test if user with a unique user number has been added to database

require 'spec_helper'
require 'shoulda'

include MarkusConfigurator

describe 'TATest' do
  context 'A TA with a membership' do
    before(:each) do
      @assignment = create(:assignment)
      @ta = create(:ta)
      @grouping = create(:grouping, assignment: @assignment)
      create(:ta_membership, grouping: @grouping, user: @ta)
    end

    it 'gets membership for one assignment' do
      expect(@ta.memberships_for_assignment(@assignment)).not_to be_nil
    end

    it 'is already assigned to a grouping' do
      expect(@ta.is_assigned_to_grouping?(@grouping.id)).not_to be_nil
    end
  end
end
