require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class UserTest < ActiveSupport::TestCase
  
  fixtures :users
  should_have_many :memberships
  should_have_many :groupings, :through => :memberships
  should_validate_presence_of :user_name
  should_validate_presence_of :last_name
  should_validate_presence_of :first_name

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

  def test_admin_if_true
     admin = users(:olm_admin1)
     assert admin.admin?, "should return true as user is admin"
  end
  
  def test_admin_if_false
     admin = users(:student1)
     assert !admin.admin?, "should return false as user not admin"
  end

  def test_ta_if_true
     ta = users(:ta1)
     assert ta.ta?, "should return true as user is ta"
  end

  def test_ta_if_false
     ta = users(:student1)
     assert !ta.ta?, "should return false, as user is not a ta"
  end

  def test_student_if_true
     student = users(:student1)
     assert student.student?, "should return true as student is a studet"
  end

  def test_student_if_false
     student = users(:ta1)
     assert !student.student?, "should return false as student is not a
     student"
  end


end
