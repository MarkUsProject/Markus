require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  
  fixtures :users
  
  def setup
    # attributes with a user number that does not exists in db.
    @attr_no_dup = { 
      :user_name => 'admin__not_dup',
      :user_number => '987654321', 
      :last_name => 'De Niro', 
      :first_name => 'Robert', 
      :role => 'admin'
    }
    
    # attributes with a user number that exists in db.
    # same as the student
    @attr_dup = { 
      :user_name => 'student_dup',
      :user_number => '345678912', 
      :last_name => 'De Niro', 
      :first_name => 'Robert', 
      :role => 'student'
    }
    
    # attributes with a user number that exists in db.
    @attr_partial_dup = { 
      :user_name => 'student_dup',
      :user_number => '345678912'
    }
  end
  
  # User.update_on_duplicate tests ----------------------------------------
  
  
  # Test if user with a unique user number has been added to database
  def test_update_on_no_duplicate
    User.update_on_duplicate(@attr_no_dup)
    user = User.find_by_user_number(@attr_no_dup[:user_number])
    admin_user = users(:admin)
    
    assert_not_nil user
    assert_equal @attr_no_dup[:user_name], user.user_name
    # make sure admin_user is not overwritten
    assert_not_equal admin_user.user_name, user.user_name
  end
  
  # Test if attributes with existing user_number in database 
  # updates all specified attributes
  def test_update_with_duplicate
    # fetch old information about user 'student'
    old_student = users(:student)
    old_number = old_student.user_number
    old_username = old_student.user_name
    old_lastname = old_student.last_name
    
    # update user 'student'
    User.update_on_duplicate(@attr_dup)
    user = User.find_by_user_number(@attr_dup[:user_number])
    
    assert_not_nil user
    assert_equal @attr_dup[:user_name], user.user_name
    assert_equal old_number, user.user_number
    assert_not_equal old_username, user.user_name
    assert_not_equal old_lastname, user.last_name
  end
  
  # Test if attributes with existing user_number in database 
  # updates all specified attributes, and retains other attributes
  # if not specified in hash.
  def test_update_with_partial_duplicate
    # fetch old information about user 'student'
    old_student = users(:student)
    old_number = old_student.user_number
    old_username = old_student.user_name
    old_lastname = old_student.last_name
    
    # update user 'student'
    User.update_on_duplicate(@attr_partial_dup)
    user = User.find_by_user_number(@attr_partial_dup[:user_number])
    
    assert_not_nil user
    assert_equal @attr_partial_dup[:user_name], user.user_name
    assert_equal old_number, user.user_number
    assert_not_equal old_username, user.user_name
    assert_equal old_lastname, user.last_name  # shouldn't change
  end
end
