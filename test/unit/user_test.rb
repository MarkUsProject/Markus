require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  
  fixtures :users
  
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
  
  # Tests if user validates the presence of the following fields when created
  #   :user_name, :last_name, :first_name
  def test_validate_presence_of
    no_user_name = create_no_attr(:user_name)
    assert !no_user_name.valid?
    
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
