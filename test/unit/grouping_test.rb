require 'test_helper'

class GroupingTest < ActiveSupport::TestCase
  fixtures :groups

  def test_grouping_should_not_save_without_assignment
    grouping = Grouping.new
    grouping.group_id = 1
    assert !grouping.save, "Saved the grouping without assignment"
  end

  def test_should_not_save_without_group
    grouping = Grouping.new
    grouping.assignment_id = 1
    assert !grouping.save, "Saved the grouping without group"
  end

  def test_save_grouping
    grouping = Grouping.new
    grouping.assignment_id = 1
    grouping.group_id = 1
    assert grouping.save, "Save the grouping"
  end



end
