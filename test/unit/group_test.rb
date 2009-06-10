require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  fixtures :users


  def test_should_not_save_without_groupname
    group = Group.new
    assert !group.save, "Group saved without groupnames"
  end

  def test_groupname_should_be_unique
    group = Group.new
    group.group_name = "Titanic"
    assert !group.save, "Group saved with an already existing groupname"
  end

  def test_save_group
    group = Group.new
    group.group_name = "totallyNewName"
    assert group.save, "Group not saved..."
  end

end


