require 'test_helper'
require 'shoulda'

class StudentTest < ActiveSupport::TestCase
  fixtures :users

  # Update tests ---------------------------------------------------------
  
  # These tests are for the CSV/YML upload functions.  They're testing
  # to make sure we can easily create/update users based on their user_name
  
  # Test if user with a unique user number has been added to database
  def test_student_csv_upload_with_no_duplicates
    csv_file_data = "newuser1,USER1,USER1
newuser2,USER2,USER2"
    num_users = Student.all.size
    User.upload_user_list(Student, csv_file_data)

    assert_equal num_users + 2, Student.all.size, "Expected a different number of users - the CSV upload didn't work"
    
    
    csv_1 = Student.find_by_user_name('newuser1')
    assert_not_nil csv_1, "Couldn't find a user uploaded by CSV"
    assert_equal "USER1", csv_1.last_name, "Last name did not match"
    assert_equal "USER1", csv_1.first_name, "First name did not match"
    
    csv_2 = Student.find_by_user_name('newuser2')
    assert_not_nil csv_2, "Couldn't find a user uploaded by CSV"
    assert_equal "USER2", csv_2.last_name, "Last name did not match"
    assert_equal "USER2", csv_2.first_name, "First name did not match"
    
  end
  
  def test_student_csv_upload_with_duplicate
    new_user = Student.new({:user_name => "exist_student", :first_name => "Nelle", :last_name => "Varoquaux"})
    
    assert new_user.save, "Could not create a new student"
   
    csv_file_data = "newuser1,USER1,USER1
exist_student,USER2,USER2"    

    User.upload_user_list(Student, csv_file_data)
    
    user = Student.find_by_user_name("exist_student")
    assert_equal "USER2", user.last_name, "Last name was not properly overwritten by CSV file"
    assert_equal "USER2", user.first_name, "First name was not properly overwritten by CSV file"
    
    other_user = Student.find_by_user_name("newuser1")
    assert_not_nil other_user, "Could not find the other user uploaded by CSV"
  
  end

  def test_has_accepted_grouping_for?
      user = Student.new({:user_name => "exist_student", :first_name => "Nelle", :last_name => "Varoquaux"})
      user.save
      assert !user.has_accepted_grouping_for?(1), "Should return no grouping
      for this assignment"

      group = Group.new({:group_name => "nelle"})
      group.save
      grouping = Grouping.new({:group_id => group.id, :assignment_id => 1})
      grouping.save
      membership = StudentMembership.new({:user_id => user.id, :grouping_id => grouping.id, :membership_status => StudentMembership::STATUSES[:inviter]})
      membership.save
      assert user.has_accepted_grouping_for?(1)
  end

  def test_accepted_grouping_for
     user = Student.new({:user_name => "exist_student", :first_name => "Nelle", :last_name => "Varoquaux"})
     user.save

     group = Group.new({:group_name => "nelle"})
     group.save
     grouping = Grouping.new({:group_id => group.id, :assignment_id => 1})
     grouping.save
     membership = StudentMembership.new({:user_id => user.id, :grouping_id => grouping.id, :membership_status => StudentMembership::STATUSES[:inviter]})
     membership.save
 
  end
end
