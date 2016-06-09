# Context architecture
#
# TODO: Complete contexts
#
# - Tests on database structure and model
# - CSV and YML upload
#  - with no duplicates and no sections
#  - with duplicates and no sections
#  - with no duplicates and sections
#  - with duplicates and sections
#  - with no duplicates and one section
#  - with duplicates and sections and update of a section
#  - with an invalid file

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class StudentTest < ActiveSupport::TestCase

  context 'A good Student model' do

    should have_many(:accepted_groupings).through(:memberships)
    should have_many(:pending_groupings).through(:memberships)
    should have_many(:rejected_groupings).through(:memberships)
    should have_many :student_memberships
    should have_many :grace_period_deductions
    should belong_to :section

    should validate_numericality_of :grace_credits

  end

  context 'CSV and YML upload' do

    # Update tests ---------------------------------------------------------

    # These tests are for the CSV/YML upload functions.  They're testing
    # to make sure we can easily create/update users based on their user_name

    # Test if user with a unique user number has been added to database

    context 'with no duplicates and no sections' do

      setup do
        csv_file_data = StringIO.new("newuser1,USER1,USER1\n" +
                                         'newuser2,USER2,USER2')

        @num_users = Student.all.size

        User.upload_user_list(Student, csv_file_data, nil)

        @csv_1 = Student.find_by_user_name('newuser1')
        @csv_2 = Student.find_by_user_name('newuser2')
      end

      should 'have no duplicates' do
        assert_equal @num_users + 2, Student.all.size, "Expected a different number of users - the CSV upload didn't work"

        assert_not_nil @csv_1, "Couldn't find a user uploaded by CSV"
        assert_equal 'USER1', @csv_1.last_name, 'Last name did not match'
        assert_equal 'USER1', @csv_1.first_name, 'First name did not match'

        assert_not_nil @csv_2, "Couldn't find a user uploaded by CSV"
        assert_equal 'USER2', @csv_2.last_name, 'Last name did not match'
        assert_equal 'USER2', @csv_2.first_name, 'First name did not match'
      end
    end

    context 'with duplicates and no sections' do

      setup do

      end

      should 'have no duplicates' do
        new_user = Student.new({user_name: 'exist_student', first_name: 'Nelle', last_name: 'Varoquaux'})

        assert new_user.save, 'Could not create a new student'

        csv_file_data = StringIO.new("newuser1,USER1,USER1\n" +
                                         'exist_student,USER2,USER2')

        User.upload_user_list(Student, csv_file_data, nil)

        user = Student.find_by_user_name('exist_student')
        assert_equal 'USER2', user.last_name, 'Last name was not properly overwritten by CSV file'
        assert_equal 'USER2', user.first_name, 'First name was not properly overwritten by CSV file'

        other_user = Student.find_by_user_name('newuser1')
        assert_not_nil other_user, 'Could not find the other user uploaded by CSV'
      end
    end

    context 'with no duplicates and sections' do

      setup do
        csv_file_data = StringIO.new("newuser1,USER1,USER1,SECTION1\n" +
                                         'newuser2,USER2,USER2,SECTION2')

        @num_users = Student.all.size

        User.upload_user_list(Student, csv_file_data, nil)

        @csv_1 = Student.find_by_user_name('newuser1')
        @csv_2 = Student.find_by_user_name('newuser2')
      end

      should 'have no duplicates and correct sections' do
        assert_equal @num_users + 2, Student.all.size, "Expected a different number of users - the CSV upload didn't work"

        assert_not_nil @csv_1, "Couldn't find a user uploaded by CSV"
        assert_equal 'USER1', @csv_1.last_name, 'Last name did not match'
        assert_equal 'SECTION1', @csv_1.section.name, 'Section did not match'
        assert_equal 'USER1', @csv_1.first_name, 'First name did not match'

        assert_not_nil @csv_2, "Couldn't find a user uploaded by CSV"
        assert_equal 'USER2', @csv_2.last_name, 'Last name did not match'
        assert_equal 'SECTION2', @csv_2.section.name, 'Section did not match'
        assert_equal 'USER2', @csv_2.first_name, 'First name did not match'
      end
    end

    context 'with no duplicates and only one section' do

      setup do
        csv_file_data = StringIO.new("newuser1,USER1,USER1,SECTION1\n" +
                                         'newuser2,USER2,USER2')

        @num_users = Student.all.size

        User.upload_user_list(Student, csv_file_data, nil)

        @csv_1 = Student.find_by_user_name('newuser1')
        @csv_2 = Student.find_by_user_name('newuser2')
      end

      should 'have no duplicates and correct sections' do
        assert_equal @num_users + 2, Student.all.size, "Expected a different number of users - the CSV upload didn't work"

        assert_not_nil @csv_1, "Couldn't find a user uploaded by CSV"
        assert_equal 'USER1', @csv_1.last_name, 'Last name did not match'
        assert_equal 'SECTION1', @csv_1.section.name, 'Section did not match'
        assert_equal 'USER1', @csv_1.first_name, 'First name did not match'

        assert_not_nil @csv_2, "Couldn't find a user uploaded by CSV"
        assert_equal 'USER2', @csv_2.last_name, 'Last name did not match'
        assert_nil @csv_2.section, 'Section should be nil'
        assert_equal 'USER2', @csv_2.first_name, 'First name did not match'
      end
    end

    context 'with duplicates and sections and update of a section' do

      setup do
        @section = Section.create(name: 'SECTION0')
      end

      should 'have no duplicates' do
        new_user = Student.new(user_name: 'exist_student',
                               first_name: 'Nelle',
                               last_name: 'Varoquaux',
                               section: @section)

        assert new_user.save, 'Could not create a new student'

        csv_file_data = StringIO.new("newuser1,USER1,USER1,SECTION1\n" +
                                         'exist_student,USER2,USER2,SECTION2')

        User.upload_user_list(Student, csv_file_data, nil)

        user = Student.find_by_user_name('exist_student')
        assert_equal 'USER2', user.last_name, 'Last name was not properly overwritten by CSV file'
        assert_equal 'SECTION2', user.section.name, 'Section was not properly overwritten by CSV file'
        assert_equal 'USER2', user.first_name, 'First name was not properly overwritten by CSV file'

        other_user = Student.find_by_user_name('newuser1')
        assert_not_nil other_user, 'Could not find the other user uploaded by CSV'
      end
    end

    context 'with an invalid file' do

      setup do
        @csv_file_data = StringIO.new("newuser1USER1USER1,\n" +
                                          'newuser2,USER2,USER2')

        @num_users = Student.all.size
        @result = User.upload_user_list(Student, @csv_file_data, nil)
      end

      should 'not add any student to the database' do
        assert_equal @result[:invalid_lines].first, 'newuser1USER1USER1,'
        assert_equal Student.all.size, @num_users + 1
      end
    end
  end

  context 'A pair of students in the same group' do
    setup do
      @membership1 = StudentMembership.make(membership_status: StudentMembership::STATUSES[:inviter])
      @grouping = @membership1.grouping
      @membership2 = StudentMembership.make({grouping: @grouping, membership_status: StudentMembership::STATUSES[:accepted]})
      @student1 = @membership1.user
      @student2 = @membership2.user

      @student_id_list = [@student1.id, @student2.id]
    end

    should 'hide without error' do
      Student.hide_students(@student_id_list)

      students = Student.find(@student_id_list)
      assert_equal(true, students[0].hidden)
      assert_equal(true, students[1].hidden)
    end

    should 'hide students and have the repo remove them' do
      # Mocks to enter into the if
      Assignment.any_instance.stubs(:vcs_submit).returns(true)
      Grouping.any_instance.stubs(:is_valid?).returns(true)

      # Mock the repository and expect :remove_user with the student's user_name
      mock_repo = mock('Repository::AbstractRepository')
      mock_repo.stubs(:remove_user).returns(true)
      mock_repo.stubs(:close).returns(true)
      mock_repo.expects(:remove_user).with(any_of(@student1.user_name, @student2.user_name)).at_least(2)
      Group.any_instance.stubs(:repo).returns(mock_repo)

      Student.hide_students(@student_id_list)
    end

    should 'not error when user is not found on hide and remove' do
      # Mocks to enter into the if that leads to the call to remove the student
      Assignment.any_instance.stubs(:vcs_submit).returns(true)
      Grouping.any_instance.stubs(:is_valid?).returns(true)

      # Mock the repository and raise Repository::UserNotFound
      mock_repo = mock('Repository::AbstractRepository')
      mock_repo.stubs(:close).returns(true)
      mock_repo.stubs(:remove_user).raises(Repository::UserNotFound)
      Group.any_instance.stubs(:repo).returns(mock_repo)

      Student.hide_students(@student_id_list)
    end

    [{type: 'negative', grace_credits: '-10', expected: 0 },
     {type: 'positive', grace_credits: '10', expected: 15 }].each do |item|
      should "not error when given #{item[:type]} grace credits" do
        assert Student.give_grace_credits(@student_id_list, item[:grace_credits])

        #You have to find the students to get the updated values
        students = Student.find(@student_id_list)

        assert_equal(item[:expected], students[0].grace_credits)
        assert_equal(item[:expected], students[1].grace_credits)
      end
    end
  end

  context 'Hidden Students' do
    setup do
      @student1 = Student.make(:hidden)
      @student2 = Student.make(:hidden)

      @membership1 = StudentMembership.make({membership_status: StudentMembership::STATUSES[:inviter], user: @student1})
      @grouping = @membership1.grouping
      @membership2 = StudentMembership.make({grouping: @grouping, membership_status: StudentMembership::STATUSES[:accepted], user: @student2})

      @student_id_list = [@student1.id, @student2.id]
    end

    should 'unhide without error' do
      #TODO test the repo with mocks
      Student.unhide_students(@student_id_list)

      students = Student.find(@student_id_list)
      assert_equal(false, students[0].hidden)
      assert_equal(false, students[1].hidden)
    end

    should 'unhide without error when users already exists in repo' do
      # Mocks to enter into the if
      Assignment.any_instance.stubs(:vcs_submit).returns(true)
      Grouping.any_instance.stubs(:is_valid?).returns(true)

      # Mock the repository and raise Repository::UserNotFound
      mock_repo = mock('Repository::AbstractRepository')
      mock_repo.stubs(:close).returns(true)
      mock_repo.stubs(:add_user).raises(Repository::UserAlreadyExistent)
      Group.any_instance.stubs(:repo).returns(mock_repo)

      Student.unhide_students(@student_id_list)
    end
  end


  context 'A hidden Student' do
    setup do
      @student = Student.make(:hidden)
    end

    should 'not become a member of a grouping' do
      grouping = Grouping.make
      @student.invite(grouping.id)

      pending_memberships = @student.pending_memberships_for(grouping.assignment_id)

      assert_not_nil pending_memberships
      assert_equal(0, pending_memberships.length)
    end
  end


  context 'A Student' do
    setup do
      @student = Student.make
    end

    context 'with an assignment' do
      setup do
        @assignment = Assignment.make(group_name_autogenerated: false)
      end

      should 'not return nil on call to memberships_for' do
        assert_not_nil @student.memberships_for(@assignment.id)
      end

      should 'return empty when there are no pending memberships' do
        pending_memberships = @student.pending_memberships_for(@assignment.id)

        assert_not_nil pending_memberships
        assert_equal(0, pending_memberships.length)
      end

      should 'return nil when there are no pending groupings' do
        Student.any_instance.stubs(:pending_groupings_for).returns(nil)
        pending_memberships = @student.pending_memberships_for(@assignment.id)
        assert_nil pending_memberships
      end

      should 'correctly return if it has accepted groupings' do
        assert !@student.has_accepted_grouping_for?(@assignment.id), 'Should return no grouping for this assignment'
        membership = StudentMembership.make({user: @student, grouping: Grouping.make(assignment: @assignment),membership_status: StudentMembership::STATUSES[:inviter]})
        assert @student.has_accepted_grouping_for?(@assignment.id)
      end

      should 'correctly return the accepted grouping' do
        assert_nil @student.accepted_grouping_for(@assignment.id), 'Should return no grouping for this assignment'
        grouping = Grouping.make(assignment: @assignment)
        membership = StudentMembership.make({user: @student, grouping: grouping,membership_status: StudentMembership::STATUSES[:inviter]})
        assert_equal(grouping, @student.accepted_grouping_for(@assignment.id))
      end

      should 'raise when creating an autogenerated name group' do
        assert_raise RuntimeError do
          @student.create_autogenerated_name_group(@assignment.id)
        end
      end
    end

    context 'and a grouping' do
      should 'can be invited to a grouping' do
        grouping = Grouping.make
        #Test that grouping.update_repository_permissions is called at least once
        Grouping.any_instance.expects(:update_repository_permissions).at_least(1)

        @student.invite(grouping.id)

        pending_memberships = @student.pending_memberships_for(grouping.assignment_id)

        assert_not_nil pending_memberships
        assert_equal(1, pending_memberships.length)

        membership = pending_memberships[0]

        assert_equal(StudentMembership::STATUSES[:pending], membership.membership_status)
        assert_equal(grouping.id, membership.grouping_id)
        assert_equal(@student.id, membership.user_id)
      end
    end

    context 'with a group name autogenerated assignment' do
      setup do
        @assignment = Assignment.make(group_name_autogenerated: true)
        assert @student.create_autogenerated_name_group(@assignment.id)
      end

      should 'assert no pending groupings after create' do
        assert !@student.has_pending_groupings_for?(@assignment.id)
      end

      should 'assert an accepted grouping exists after create' do
        assert @student.has_accepted_grouping_for?(@assignment.id)
      end
    end

    context 'with a pending membership' do
      setup do
        @membership = StudentMembership.make({user: @student})
      end


      context 'on an assignment' do
        setup do
          @assignment = @membership.grouping.assignment
        end

        should 'succeed at destroying all pending memberships' do
          @student.destroy_all_pending_memberships(@assignment.id)
          assert_equal(0, @student.pending_memberships_for(@assignment.id).length)
        end

        should 'reject all other pending memberships upon joining a group' do
          grouping = @membership.grouping
          membership2 = StudentMembership.make(grouping: Grouping.make(assignment: @assignment), user: @student)

          Grouping.any_instance.expects(:update_repository_permissions).at_least(1)

          assert @student.join(grouping.id)

          membership = StudentMembership.find_by_grouping_id_and_user_id(grouping.id, @student.id)
          assert_equal(StudentMembership::STATUSES[:accepted], membership.membership_status)

          otherMembership = Membership.find(membership2.id)
          assert_equal(StudentMembership::STATUSES[:rejected], otherMembership.membership_status)
        end

        should 'have pending memberships after their creation.' do
          membership2 = StudentMembership.make(grouping: Grouping.make(assignment: @assignment), user: @student)

          pending_memberships = @student.pending_memberships_for(@assignment.id)

          assert_not_nil pending_memberships
          assert_equal(2, pending_memberships.length)

          expected_groupings = [@membership.grouping, membership2.grouping]
          assert_equal expected_groupings.map(&:id).to_set, pending_memberships.map(&:grouping_id).to_set
          assert_equal [], pending_memberships.delete_if {|e| e.user_id == @student.id}
        end

        context 'working alone' do
          setup do
            assert @student.create_group_for_working_alone_student(@assignment.id)
            @group = Group.where(group_name: @student.user_name).first
          end

          should 'create the group' do
            assert Group.where(group_name: @student.user_name).first,
                   'the group has not been created'
          end

          should 'have their repo name equal their user name' do
            assert_equal(@group.repo_name, @student.user_name)
          end

          should 'not have any pending memberships' do
            assert !@student.has_pending_groupings_for?(@assignment.id)
          end

          should 'have an accepted grouping' do
            assert @student.has_accepted_grouping_for?(@assignment.id)
          end
        end

        context 'working alone but has an existing group' do
          setup do
            @group = Group.make
            @grouping = Grouping.make({group: @group, assignment: @assignment})
            @membership2 = StudentMembership.make({user: @student, membership_status: StudentMembership::STATUSES[:inviter], grouping: @grouping})
          end

          should 'work' do
            assert @student.create_group_for_working_alone_student(@assignment.id)
          end
        end
      end

    end

    context 'with grace credits' do
      should 'return remaining normally' do
        assert_equal(5, @student.remaining_grace_credits)
      end

      should 'return normally when over deducted' do
        deduction1 = GracePeriodDeduction.make(membership: StudentMembership.make(user: @student))
        deduction2 = GracePeriodDeduction.make(membership: deduction1.membership, deduction: 10)
        assert_equal(-25, @student.remaining_grace_credits)
      end
    end

    should 'assert student has a section' do
      assert @student.has_section?
    end

    should "assert student doesn't have a section" do
      student = Student.make(section: nil)
      assert !student.has_section?
    end

    should 'update the section of the students in the list' do
      student1 = Student.make(section: nil)
      student2 = Student.make(section: nil)
      students_ids = [student1.id, student2.id]
      section_id = Section.make.id
      Student.update_section(students_ids, section_id)
      students = Student.find(students_ids)
      assert_not_nil students[0].section
    end

    should 'update the section of the students in the list, setting it to no section' do
      student1 = Student.make
      student1.save
      student2 = Student.make
      student2.save
      students_ids = [student1.id, student2.id]
      section_id = 0
      Student.update_section(students_ids, section_id)
      students = Student.find(students_ids)
      assert_nil students[0].section
    end

    context 'as a noteable' do
      should 'display for note without seeing an exception' do
        assert_nothing_raised do
          @student.display_for_note
        end
      end
    end # end noteable context

  end
end
