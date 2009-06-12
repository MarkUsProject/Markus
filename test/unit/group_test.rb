require 'test_helper'
require 'shoulda'

class GroupTest < ActiveSupport::TestCase
  fixtures :users
  should_have_many :groupings
  should_have_many :submissions, :through => :groupings
  should_have_many :assignments, :through => :groupings
  should_validate_presence_of :group_name

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


