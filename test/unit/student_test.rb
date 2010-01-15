require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'
require 'mocha'

class StudentTest < ActiveSupport::TestCase

  should_have_many :accepted_groupings
  should_have_many :pending_groupings
  should_have_many :rejected_groupings
  should_have_many :student_memberships
  should_have_many :grace_period_deductions

  def setup
    setup_group_fixture_repos
  end

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
    assignment = assignments(:assignment_1)
    user = Student.new({:user_name => "exist_student", :first_name => "Nelle", :last_name => "Varoquaux"})
    user.save
    assert !user.has_accepted_grouping_for?(1), "Should return no grouping for this assignment"

    group = Group.new({:group_name => "nelle"})
    group.save
    grouping = Grouping.new({:group_id => group.id, :assignment_id => assignment.id})
    grouping.save
    membership = StudentMembership.new({:user_id => user.id, :grouping_id => grouping.id, :membership_status => StudentMembership::STATUSES[:inviter]})
    membership.save
    assert user.has_accepted_grouping_for?(assignment.id)
  end

  def test_accepted_grouping_for
     assignment = assignments(:assignment_1)
     user = Student.new({:user_name => "exist_student", :first_name => "Nelle", :last_name => "Varoquaux"})
     user.save

     group = Group.new({:group_name => "nelle"})
     group.save
     grouping = Grouping.new({:group_id => group.id, :assignment_id => assignment.id})
     grouping.save
     membership = StudentMembership.new({:user_id => user.id, :grouping_id => grouping.id, :membership_status => StudentMembership::STATUSES[:inviter]})
     membership.save

  end

  def test_if_destroy_all_pending_memberships
     assignment = assignments(:assignment_1)
     student = users(:student5)
     student.destroy_all_pending_memberships(assignment.id)
     assert_equal(0,student.pending_memberships_for(assignment.id).length)
  end

  def test_create_group_for_working_alone_student_group_existence
    assignment = assignments(:assignment_1)
    student = users(:student5)
    student.create_group_for_working_alone_student(assignment.id)
    assert Group.find(:first, :conditions => {:group_name =>
    student.user_name}), "the group has not been created"
  end

  def test_create_group_for_working_alone_student_membership_existence
    assignment = assignments(:assignment_1)
    student = users(:student5)
    student.create_group_for_working_alone_student(assignment.id)
    assert student.has_accepted_grouping_for?(assignment.id)
  end

  def
  test_create_group_for_working_alone_student_pending_membership_destroyed
    assignment = assignments(:assignment_1)
    student = users(:student5)
    student.create_group_for_working_alone_student(assignment.id)
    assert !student.has_pending_groupings_for?(assignment.id)
  end

  def test_create_group_for_working_alone_student_new_group
    assignment = assignments(:assignment_1)
    student = users(:student5)
    assert student.create_group_for_working_alone_student(assignment.id)
  end

  def test_create_group_for_working_alone_student_existing_group
    assignment = assignments(:assignment_1)
    student = users(:student1)

    # Mock the repository
    Grouping.any_instance.stubs(:save).returns(true)

    assert student.create_group_for_working_alone_student(assignment.id)
  end

  def test_create_autogenerated_name_group
     assignment = assignments(:assignment_1)
     student = users(:student5)
     assert student.create_autogenerated_name_group(assignment.id)
  end

  def test_create_autogenerated_name_group_error
    assignment = assignments(:assignment_3)
    student = users(:student5)
    assert_raise student.create_autogenerated_name_group(assignment.id)
    rescue
  end

  def test_create_autogenerated_name_group_pengin_memberships
    assignment = assignments(:assignment_1)
    student = users(:student5)
    student.create_autogenerated_name_group(assignment.id)
    assert !student.has_pending_groupings_for?(assignment.id)
  end

  def test_create_autogenerated_name_group_accepted_memberships
    assignment = assignments(:assignment_1)
    student = users(:student5)
    student.create_autogenerated_name_group(assignment.id)
    assert student.has_accepted_grouping_for?(assignment.id)
  end

  def test_memberships_for
    student = users(:student1)
    a = assignments(:assignment_1)
    assert_not_nil student.memberships_for(a.id)
  end

  def test_pending_memberships_for_not_empty
	  student = users(:student5)
	  a = assignments(:assignment_1)
	  pending_memberships = student.pending_memberships_for(a.id)

	  assert_not_nil pending_memberships
	  assert_equal(2, pending_memberships.length)
    
    expected_groupings = [groupings(:grouping_2), groupings(:grouping_3)]
    assert_equal expected_groupings.map(&:id).to_set, pending_memberships.map(&:grouping_id).to_set
    assert_equal [], pending_memberships.delete_if {|e| e.user_id == student.id}
  end

  def test_pending_membership_for_empty
    student = users(:student1)
    a = assignments(:assignment_1)
    pending_memberships = student.pending_memberships_for(a.id)

    assert_not_nil pending_memberships
    assert_equal(0, pending_memberships.length)
  end

  def test_pending_membership_for_group_nil
    student = users(:student1)
    a = assignments(:assignment_1)

    Student.any_instance.stubs(:pending_groupings_for).returns(nil)

    pending_memberships = student.pending_memberships_for(a.id)

    assert_nil pending_memberships
  end

  def test_invite_hidden
    student = users(:hidden_student)
    grouping = groupings(:grouping_1)
    student.invite(grouping.id)

    pending_memberships = student.pending_memberships_for(grouping.assignment_id)

    assert_not_nil pending_memberships
    assert_equal(0, pending_memberships.length)
  end

  def test_invite_not_hidden
    student = users(:student1)
    grouping = groupings(:grouping_2)

    #Test that grouping.update_repository_permissions is called at least once
    Grouping.any_instance.expects(:update_repository_permissions).at_least(1)

    student.invite(grouping.id)

    pending_memberships = student.pending_memberships_for(grouping.assignment_id)

    assert_not_nil pending_memberships
    assert_equal(1, pending_memberships.length)

    membership = pending_memberships[0]

    assert_equal(StudentMembership::STATUSES[:pending], membership.membership_status)
    assert_equal(grouping.id, membership.grouping_id)
    assert_equal(student.id, membership.user_id)
  end

  def test_remaining_grace_credits_nil
    student = users(:student2)
    assert_equal(5, student.remaining_grace_credits)
  end

  def test_remaining_grace_credits_not_nil
    student = users(:student1)
    assert_equal(-25, student.remaining_grace_credits)
  end

  def give_grace_credits(grace_credits, expected_value)
    student1 = users(:student1)
    student2 = users(:student2)

    assert Student.give_grace_credits([student1.id, student2.id], grace_credits)

    #You have to find the students to get the updated values
    updatedStudent1 = Student.find(student1.id)
    updatedStudent2 = Student.find(student2.id)

    assert_equal(expected_value, updatedStudent1.grace_credits)
    assert_equal(expected_value, updatedStudent2.grace_credits)
  end

  def test_give_grace_credits_negative
    give_grace_credits("-10", 0)
  end

  def test_give_grace_credits_positive
    give_grace_credits("10", 15)
  end

  def test_join
    student = users(:student5)
    grouping = groupings(:grouping_2)
    Grouping.any_instance.expects(:update_repository_permissions).at_least(1)

    assert student.join(grouping.id)

    membership = StudentMembership.find_by_grouping_id_and_user_id(grouping.id, student.id)
    assert_equal('accepted', membership.membership_status)

    otherMembership = Membership.find(memberships(:membership9).id)
    assert_equal('rejected', otherMembership.membership_status)
  end

  def test_hide_students
    student1 = users(:student1)
    student2 = users(:student2)

    student_id_list = [student1.id, student2.id]

    Student.hide_students(student_id_list)

    students = Student.find(student_id_list)
    assert_equal(true, students[0].hidden)
    assert_equal(true, students[1].hidden)
  end


  def test_hide_students_repo_remove_user
    student1 = users(:student1)
    student2 = users(:student2)

    # Mocks to enter into the if
    Group.any_instance.stubs(:repository_external_commits_only?).returns(true)
    Grouping.any_instance.stubs(:is_valid?).returns(true)

    # Mock the repository and expect :remove_user with the student's user_name
    mock_repo = mock('Repository::AbstractRepository')
    mock_repo.stubs(:remove_user).returns(true)
    mock_repo.expects(:remove_user).with(any_of(student1.user_name, student2.user_name)).at_least(2)
    Group.any_instance.stubs(:repo).returns(mock_repo)

    student_id_list = [student1.id, student2.id]

    assert Student.hide_students(student_id_list)
  end

  def test_hide_students_repo_remove_user_raise_not_found
    student1 = users(:student1)
    student2 = users(:student2)

    # Mocks to enter into the if
    Group.any_instance.stubs(:repository_external_commits_only?).returns(true)
    Grouping.any_instance.stubs(:is_valid?).returns(true)

    # Mock the repository and raise Repository::UserNotFound
    mock_repo = mock('Repository::AbstractRepository')
    mock_repo.stubs(:remove_user).raises(Repository::UserNotFound)
    Group.any_instance.stubs(:repo).returns(mock_repo)

    student_id_list = [student1.id, student2.id]

    assert Student.hide_students(student_id_list)
  end

  def test_unhide_students
      student1 = users(:student1)
      student2 = users(:student2)

      student1.hidden = true
      student1.save
      student2.hidden = true
      student2.save

      student_id_list = [student1.id, student2.id]

      #TODO test the repo with mocks
      assert Student.unhide_students(student_id_list)

      students = Student.find(student_id_list)
      assert_equal(false, students[0].hidden)
      assert_equal(false, students[1].hidden)
  end

  def test_unhide_students_repo_add_user
    student1 = users(:student1)
    student2 = users(:student2)

    # Mocks to enter into the if
    Group.any_instance.stubs(:repository_external_commits_only?).returns(true)
    Grouping.any_instance.stubs(:is_valid?).returns(true)

    # Mock the repository and expect :remove_user with the student's user_name
    mock_repo = mock('Repository::AbstractRepository')
    mock_repo.stubs(:add_user).returns(true)
    mock_repo.expects(:add_user).with(any_of(student1.user_name, student2.user_name), Repository::Permission::READ_WRITE).at_least(2)
    Group.any_instance.stubs(:repo).returns(mock_repo)

    student_id_list = [student1.id, student2.id]

    assert Student.unhide_students(student_id_list)
  end

  def test_unhide_students_repo_add_user_raise_already_existant
    student1 = users(:student1)
    student2 = users(:student2)

    # Mocks to enter into the if
    Group.any_instance.stubs(:repository_external_commits_only?).returns(true)
    Grouping.any_instance.stubs(:is_valid?).returns(true)

    # Mock the repository and raise Repository::UserNotFound
    mock_repo = mock('Repository::AbstractRepository')
    mock_repo.stubs(:add_user).raises(Repository::UserAlreadyExistent)
    Group.any_instance.stubs(:repo).returns(mock_repo)

    student_id_list = [student1.id, student2.id]

    assert Student.unhide_students(student_id_list)
  end

end
