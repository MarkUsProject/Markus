require 'test_helper'

class TATest < ActiveSupport::TestCase
  fixtures :users, :memberships, :assignments
  
  # Update tests ---------------------------------------------------------
  
  # These tests are for the CSV/YML upload functions.  They're testing
  # to make sure we can easily create/update users based on their user_name
  
  # Test if user with a unique user number has been added to database
  def test_ta_csv_upload_with_no_duplicates
    csv_file_data = "newuser1,USER1,USER1
newuser2,USER2,USER2"
    num_users = Ta.all.size
    Ta.upload_user_list(Ta, csv_file_data)

    assert_equal num_users + 2, Ta.all.size, "Expected a different number of users - the CSV upload didn't work"
    
    
    csv_1 = Ta.find_by_user_name('newuser1')
    assert_not_nil csv_1, "Couldn't find a user uploaded by CSV"
    assert_equal "USER1", csv_1.last_name, "Last name did not match"
    assert_equal "USER1", csv_1.first_name, "First name did not match"
    
    csv_2 = Ta.find_by_user_name('newuser2')
    assert_not_nil csv_2, "Couldn't find a user uploaded by CSV"
    assert_equal "USER2", csv_2.last_name, "Last name did not match"
    assert_equal "USER2", csv_2.first_name, "First name did not match"
    
  end
  
  def test_ta_csv_upload_with_duplicate
    new_user = Ta.new({:user_name => "exist_student", :first_name => "Nelle", :last_name => "Varoquaux"})
    
    assert new_user.save, "Could not create a new student"
   
    csv_file_data = "newuser1,USER1,USER1
exist_student,USER2,USER2"    

    User.upload_user_list(Ta, csv_file_data)
    
    user = Ta.find_by_user_name("exist_student")
    assert_equal "USER2", user.last_name, "Last name was not properly overwritten by CSV file"
    assert_equal "USER2", user.first_name, "First name was not properly overwritten by CSV file"
    
    other_user = Ta.find_by_user_name("newuser1")
    assert_not_nil other_user, "Could not find the other user uploaded by CSV"
  
  end
  
  
  def test_get_memberships_for_assignment
    
  end
  
end
