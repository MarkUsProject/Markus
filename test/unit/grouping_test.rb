require 'test_helper'
require 'shoulda'

class GroupingTest < ActiveSupport::TestCase
  fixtures :groups
  fixtures :assignments
  should_belong_to :group
  should_belong_to :assignment
  should_have_many :memberships
  should_have_many :submissions

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

    group = Group.new
    group.group_name = "l'Olivier"
    group.save
    grouping.group_id = group.id
    assert grouping.save, "Save the grouping"
  end



end
