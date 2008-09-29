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
  
  # User creation validations --------------------------------------------
  
  # Tests if user validates the presence of the following fields when created
  #   :user_name, :user_number, :last_name, :first_name
  def test_validate_presence_of
    no_user_name = create_no_attr(:user_name)
    assert !no_user_name.valid?
    
    no_user_number = create_no_attr(:user_number)
    assert !no_user_number.valid?
    
    no_last_name = create_no_attr(:last_name)
    assert !no_last_name.valid?
    
    no_first_name = create_no_attr(:first_name)
    assert !no_first_name.valid?
    
    valid_user = create_no_attr(nil)
    assert valid_user.valid?
  end
  
  
  # test if User validates uniqueness of user_name and user_number
  def test_validates_uniq
    new_user = { 
      :user_name => 'adminotdup',
      :user_number => '987654321', 
      :last_name => 'De Niro', 
      :first_name => 'Robert', 
      :role => 'admin'
    }
    
    user = User.new(new_user)
    user.user_name = 'admin'
    assert !user.valid?  # username already exists in users.yml
    
    user = User.new(new_user)
    user.user_number = '123456789'
    assert !user.valid?  # user number already exists in users.yml
  end
  
  # test validation for role
  def test_invalid_role
    new_user = { 
      :user_name => 'adminotdup',
      :user_number => '987654321', 
      :last_name => 'De Niro', 
      :first_name => 'Robert', 
      :role => 'admin'
    }
    
    user = User.new(new_user)
    assert user.valid?
    user.role = 'invalid'
    assert !user.valid?
  end
  
  # tests format for user number (must be 9 digits)
  def test_valid_number_format
    new_user = { 
      :user_name => 'adminotdup',
      :user_number => '987654321', 
      :last_name => 'De Niro', 
      :first_name => 'Robert', 
      :role => 'admin'
    }
    
    user = User.new(new_user)
    assert user.valid?
    
    user.user_number = '12b456a89'
    assert !user.valid?, "alphanumeric user number"
    
    user.user_number = '12345678'
    assert !user.valid?, "8 digit user number"
  end
  
  # Update tests ---------------------------------------------------------
  
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
    old_student = users(:student1)
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
    old_student = users(:student1)
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
  
  # Helper method tests --------------------------------------------------
  
  # Test if student method fetches all students
  def test_students
    users = User.students
    users.each do |s|
      assert s.role == User::STUDENT
    end
  end
  
  private
  
  # Helper method for test_validate_presence_of to create a user without 
  # the specified attribute. if attr == nil then all attributes are included
  def create_no_attr(attr)
    new_user = { 
      :user_name => 'adminotdup',
      :user_number => '987654321', 
      :last_name => 'De Niro', 
      :first_name => 'Robert', 
      :role => 'admin'
    }
    
    new_user.delete(attr) if attr
    User.new(new_user)
  end

  
end
