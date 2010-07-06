require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class UserTestWithouBlueprints < ActiveSupport::TestCase


  def setup
    # attributes with a user number that does not exists in db.
    @attr_no_dup = {
      :user_name => 'admin__not_dup',
      :last_name => 'De Niro',
      :first_name => 'Robert',
      :type => 'Admin'
    }

    # attributes with a user name that exists in db.
    # same as the student
    @attr_dup = {
      :user_name => 'student_dup',
      :last_name => 'De Niro',
      :first_name => 'Robert',
      :type => 'Student'
    }

  end

  # User creation validations --------------------------------------------

  # test if user_name, last_name, first_name are stripped correctly
  context "a user" do
    setup do
      @unspaceduser_name = 'ausername'
      @unspacedfirst_name = 'afirstname'
      @unspacedlast_name = 'alastname'
      new_user = {
        :user_name => '   ausername   ',
        :last_name => '   alastname  ',
        :first_name => '   afirstname ',
        :type => 'Student'
      }
      @user = Student.new(new_user)

    end

    should "strip all strings with white space" do
      assert @user.save
      assert_nil User.find_by_user_name('   ausername   ')
      assert_equal @user.user_name, @unspaceduser_name
      assert_equal @user.first_name, @unspacedfirst_name
      assert_equal @user.last_name, @unspacedlast_name
    end
  end


  # test if User validates uniqueness of user_name and user_number
  def test_validates_uniq
    new_user = {
      :user_name => 'adminotdup',
      :last_name => 'De Niro',
      :first_name => 'Robert',
      :type => 'Admin'
    }

    user = User.new(new_user)
    user.user_name = 'olm_admin'
    assert !user.valid?  # username already exists in users.yml
  end

  # test validation for role
  def test_invalid_role
    new_user = {
      :user_name => 'adminotdup',
      :last_name => 'De Niro',
      :first_name => 'Robert'
    }
    user = Admin.new(new_user)
    assert user.valid?
    user.type = 'invalid'
    assert !user.valid?
  end

  # Helper method tests --------------------------------------------------

  private

  # Helper method for test_validate_presence_of to create a user without
  # the specified attribute. if attr == nil then all attributes are included
  def create_no_attr(attr)
    new_user = {
      :user_name => 'adminotdup',
      :last_name => 'De Niro',
      :first_name => 'Robert'
    }

    new_user.delete(attr) if attr
    Admin.new(new_user)
  end



end
