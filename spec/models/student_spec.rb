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
require 'spec_helper'

describe Student do

  context 'A good Student model' do
    it { is_expected.to have_many(:accepted_groupings).through(:memberships) }
    it { is_expected.to have_many(:pending_groupings).through(:memberships) }
    it { is_expected.to have_many(:rejected_groupings).through(:memberships) }
    it { is_expected.to have_many(:student_memberships) }
    it { is_expected.to have_many(:grace_period_deductions) }
    it { is_expected.to belong_to(:section) }

    it { is_expected.to validate_numericality_of(:grace_credits) }
  end

  context 'CSV and YML upload' do

    # Update tests ---------------------------------------------------------

    # These tests are for the CSV/YML upload functions.  They're testing
    # to make sure we can easily create/update users based on their user_name

    # Test if user with a unique user number has been added to database

    context 'with no duplicates and no sections' do
      before :each do
        csv_file_data = StringIO.new("newuser1,USER1,USER1\n" +
                                       'newuser2,USER2,USER2')

        @num_users = Student.all.size

        User.upload_user_list(Student, csv_file_data, nil)

        @csv_1 = Student.find_by_user_name('newuser1')
        @csv_2 = Student.find_by_user_name('newuser2')
      end

      it 'have no duplicates' do
        expect(@num_users + 2).to eq Student.all.size

        expect(@csv_1).not_to be_nil
        expect(@csv_1.last_name).to eq 'USER1'
        expect(@csv_1.first_name).to eq 'USER1'

        expect(@csv_2).not_to be_nil
        expect(@csv_2.last_name).to eq 'USER2'
        expect(@csv_2.first_name).to eq 'USER2'
      end
    end

    context 'with duplicates and no sections' do
      it 'have no duplicates' do
        new_user = Student.new({user_name: 'exist_student', first_name: 'Nelle', last_name: 'Varoquaux'})

        expect(new_user.save).to be_truthy

        csv_file_data = StringIO.new("newuser1,USER1,USER1\n" +
                                       'exist_student,USER2,USER2')

        User.upload_user_list(Student, csv_file_data, nil)

        user = Student.find_by_user_name('exist_student')
        expect(user.last_name).to eq 'USER2'
        expect(user.first_name).to eq 'USER2'

        other_user = Student.find_by_user_name('newuser1')
        expect(other_user).not_to be_nil
      end
    end

    context 'with no duplicates and sections' do
      before :each do
        csv_file_data = StringIO.new("newuser1,USER1,USER1,SECTION1\n" +
                                       'newuser2,USER2,USER2,SECTION2')

        @num_users = Student.all.size

        User.upload_user_list(Student, csv_file_data, nil)

        @csv_1 = Student.find_by_user_name('newuser1')
        @csv_2 = Student.find_by_user_name('newuser2')
      end

      it 'have no duplicates and correct sections' do
        expect(Student.all.size).to eq @num_users + 2

        expect(@csv_1).not_to be_nil
        expect(@csv_1.last_name).to eq 'USER1'
        expect(@csv_1.section.name).to eq 'SECTION1'
        expect(@csv_1.first_name).to eq 'USER1'

        expect(@csv_2).not_to be_nil
        expect(@csv_2.last_name).to eq 'USER2'
        expect(@csv_2.section.name).to eq 'SECTION2'
        expect(@csv_2.first_name).to eq 'USER2'
      end
    end

    context 'with no duplicates and only one section' do

      before :each do
        csv_file_data = StringIO.new("newuser1,USER1,USER1,SECTION1\n" +
                                       'newuser2,USER2,USER2')

        @num_users = Student.all.size

        User.upload_user_list(Student, csv_file_data, nil)

        @csv_1 = Student.find_by_user_name('newuser1')
        @csv_2 = Student.find_by_user_name('newuser2')
      end

      it 'have no duplicates and correct sections' do
        expect(Student.all.size).to eq @num_users + 2

        expect(@csv_1).not_to be_nil
        expect(@csv_1.last_name).to eq 'USER1'
        expect(@csv_1.section.name).to eq 'SECTION1'
        expect(@csv_1.first_name).to eq 'USER1'

        expect(@csv_2).not_to be_nil
        expect(@csv_2.last_name).to eq 'USER2'
        expect(@csv_2.section).to be_nil
        expect(@csv_2.first_name).to eq 'USER2'
      end
    end

    context 'with duplicates and sections and update of a section' do

      before :each do
        @section = Section.create(name: 'SECTION0')
      end

      it 'have no duplicates' do
        new_user = Student.new(user_name: 'exist_student',
                               first_name: 'Nelle',
                               last_name: 'Varoquaux',
                               section: @section)

        expect(new_user.save).to be_truthy

        csv_file_data = StringIO.new("newuser1,USER1,USER1,SECTION1\n" +
                                       'exist_student,USER2,USER2,SECTION2')

        User.upload_user_list(Student, csv_file_data, nil)

        user = Student.find_by_user_name('exist_student')
        expect(user.last_name).to eq 'USER2'
        expect(user.section.name).to eq 'SECTION2'
        expect(user.first_name).to eq 'USER2'

        other_user = Student.find_by_user_name('newuser1')
        expect(other_user).not_to be_nil
      end
    end

    context 'with an invalid file' do

      before :each do
        @csv_file_data = StringIO.new("newuser1USER1USER1,\n" +
                                        'newuser2,USER2,USER2')

        @num_users = Student.all.size
        @result = User.upload_user_list(Student, @csv_file_data, nil)
      end

      it 'not add any student to the database' do
        expect(@result[:invalid_lines].first).to eq 'newuser1USER1USER1,'
        expect(Student.all.size).to eq @num_users + 1
      end
    end
  end

  context 'A pair of students in the same group' do
    before :each do
      @membership1 = create(:student_membership, membership_status: StudentMembership::STATUSES[:inviter])
      @grouping = @membership1.grouping
      @membership2 = create(:student_membership, grouping: @grouping, membership_status: StudentMembership::STATUSES[:accepted])
      @student1 = @membership1.user
      @student2 = @membership2.user

      @student_id_list = [@student1.id, @student2.id]
    end

    it 'hide without error' do
      Student.hide_students(@student_id_list)

      students = Student.find(@student_id_list)
      expect(students[0].hidden).to be_truthy
      expect(students[1].hidden).to be_truthy
    end

    it 'hide students and have the repo remove them' do
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

    it 'not error when user is not found on hide and remove' do
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
      it "not error when given #{item[:type]} grace credits" do
        expect(Student.give_grace_credits(@student_id_list, item[:grace_credits])).to be_truthy

        # You have to find the students to get the updated values
        students = Student.find(@student_id_list)

        expect(item[:expected]).to eq students[0].grace_credits
        expect(item[:expected]).to eq students[1].grace_credits
      end
    end
  end

  context 'Hidden Students' do
    before :each do
      @student1 = create(:student)
      @student2 = create(:student)
      @student1.hidden = true
      @student2.hidden = true

      @membership1 = create(:student_membership, membership_status: StudentMembership::STATUSES[:inviter], user: @student1)
      @grouping = @membership1.grouping
      @membership2 = create(:student_membership, grouping: @grouping, membership_status: StudentMembership::STATUSES[:accepted], user: @student2)

      @student_id_list = [@student1.id, @student2.id]
    end

    it 'unhide without error' do
      #TODO test the repo with mocks
      Student.unhide_students(@student_id_list)

      students = Student.find(@student_id_list)
      expect(students[0].hidden).to be_falsey
      expect(students[1].hidden).to be_falsey
    end

    it 'unhide without error when users already exists in repo' do
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
    before :each do
      @student = create(:student)
      @student.hidden = true
    end

    it 'not become a member of a grouping' do
      grouping = create(:grouping)
      @student.invite(grouping.id)

      pending_memberships = @student.pending_memberships_for(grouping.assignment_id)

      expect(pending_memberships).not_to be_nil
      expect(pending_memberships.length).to eq 0
    end
  end


  context 'A Student' do
    before :each do
      @student = create(:student)
    end

    context 'with an assignment' do
      before :each do
        @assignment = create(:assignment, group_name_autogenerated: false)
      end

      it 'not return nil on call to memberships_for' do
        expect(@student.memberships_for(@assignment.id)).not_to be_nil
      end

      it 'return empty when there are no pending memberships' do
        pending_memberships = @student.pending_memberships_for(@assignment.id)

        expect(pending_memberships).not_to be_nil
        expect(pending_memberships.length).to eq 0
      end

      it 'return nil when there are no pending groupings' do
        Student.any_instance.stubs(:pending_groupings_for).returns(nil)
        pending_memberships = @student.pending_memberships_for(@assignment.id)
        expect(pending_memberships).to be_nil
      end

      it 'correctly return if it has accepted groupings' do
        expect(@student.has_accepted_grouping_for?(@assignment.id)).to be_falsey
        membership = create(:student_membership, user: @student, grouping: create(:grouping, assignment: @assignment),membership_status: StudentMembership::STATUSES[:inviter])
        expect(@student.has_accepted_grouping_for?(@assignment.id)).to be_truthy
      end

      it 'correctly return the accepted grouping' do
        expect(@student.accepted_grouping_for(@assignment.id)).to be_nil
        grouping = create(:grouping, assignment: @assignment)
        membership = create(:student_membership, user: @student, grouping: grouping, membership_status: StudentMembership::STATUSES[:inviter])
        expect(@student.accepted_grouping_for(@assignment.id)).to eq grouping
      end

      it 'raise when creating an autogenerated name group' do
        expect { @student.create_autogenerated_name_group(@assignment.id) }.to raise_error(RuntimeError)
      end
    end

    context 'and a grouping' do
      it 'can be invited to a grouping' do
        grouping = create(:grouping)
        #Test that grouping.update_repository_permissions is called at least once
        Grouping.any_instance.expects(:update_repository_permissions).at_least(1)

        @student.invite(grouping.id)

        pending_memberships = @student.pending_memberships_for(grouping.assignment_id)

        expect(pending_memberships).not_to be_nil
        expect(pending_memberships.length).to eq 1

        membership = pending_memberships[0]

        expect(StudentMembership::STATUSES[:pending]).to eq membership.membership_status
        expect(grouping.id).to eq membership.grouping_id
        expect(@student.id).to eq membership.user_id
      end
    end

    context 'with a group name autogenerated assignment' do
      before :each do
        @assignment = create(:assignment, group_name_autogenerated: true)
        expect(@student.create_autogenerated_name_group(@assignment.id)).to be_truthy
      end

      it 'assert no pending groupings after create' do
        expect(@student.has_pending_groupings_for?(@assignment.id)).to be_falsey
      end

      it 'assert an accepted grouping exists after create' do
        expect(@student.has_accepted_grouping_for?(@assignment.id)).to be_truthy
      end
    end

    context 'with a pending membership' do
      before :each do
        @membership = create(:student_membership, membership_status: StudentMembership::STATUSES[:pending], user: @student)
      end


      context 'on an assignment' do
        before :each do
          @assignment = @membership.grouping.assignment
        end

        it 'succeed at destroying all pending memberships' do
          @student.destroy_all_pending_memberships(@assignment.id)
          expect(@student.pending_memberships_for(@assignment.id).length).to eq 0
        end

        it 'reject all other pending memberships upon joining a group' do
          grouping = @membership.grouping
          membership2 = create(:student_membership, membership_status: StudentMembership::STATUSES[:pending], grouping: create(:grouping, assignment: @assignment), user: @student)

          Grouping.any_instance.expects(:update_repository_permissions).at_least(1)

          expect(@student.join(grouping.id)).to be_truthy

          membership = StudentMembership.find_by_grouping_id_and_user_id(grouping.id, @student.id)
          expect(StudentMembership::STATUSES[:accepted]).to eq membership.membership_status

          otherMembership = Membership.find(membership2.id)
          expect(StudentMembership::STATUSES[:rejected]).to eq otherMembership.membership_status
        end

        it 'have pending memberships after their creation.' do
          membership2 = create(:student_membership, membership_status: StudentMembership::STATUSES[:pending], grouping: create(:grouping, assignment: @assignment), user: @student)

          pending_memberships = @student.pending_memberships_for(@assignment.id)

          expect(pending_memberships).not_to be_nil
          expect(pending_memberships.length).to eq 2

          expected_groupings = [@membership.grouping, membership2.grouping]
          expect(expected_groupings.map(&:id).to_set).to eq pending_memberships.map(&:grouping_id).to_set
          expect(pending_memberships.delete_if {|e| e.user_id == @student.id}).to eq []
        end

        context 'working alone' do
          before :each do
            @student.create_group_for_working_alone_student(@assignment.id)
            @group = Group.where(group_name: @student.user_name).first
          end

          it 'create the group' do
            expect(Group.where(group_name: @student.user_name).first).to be_truthy
          end

          it 'have their repo name equal their user name' do
            expect(@group.repo_name).to eq @student.user_name
          end

          it 'not have any pending memberships' do
            expect(@student.has_pending_groupings_for?(@assignment.id)).to be_falsey
          end

          it 'have an accepted grouping' do
            expect(@student.has_accepted_grouping_for?(@assignment.id)).to be_truthy
          end
        end

        context 'working alone but has an existing group' do
          before :each do
            @group = create(:group)
            @grouping = create(:grouping, group: @group, assignment: @assignment)
            @membership2 = create(:student_membership, user: @student, membership_status: StudentMembership::STATUSES[:inviter], grouping: @grouping)
          end

          it 'work' do
            expect(@student.create_group_for_working_alone_student(@assignment.id)).to be_truthy
          end
        end
      end

    end

    context 'with grace credits' do
      it 'return remaining normally' do
        expect(@student.remaining_grace_credits).to eq 5
      end

      it 'return normally when over deducted' do
        deduction1 = create(:grace_period_deduction, membership: create(:student_membership, user: @student))
        deduction2 = create(:grace_period_deduction, membership: deduction1.membership, deduction: 10)
        expect(@student.remaining_grace_credits).to eq -25
      end
    end

    it 'assert student has a section' do
      expect(@student.has_section?).to be_truthy
    end

    it "assert student doesn't have a section" do
      student = create(:student, section: nil)
      expect(student.has_section?).to be_falsey
    end

    it 'update the section of the students in the list' do
      student1 = create(:student, section: nil)
      student2 = create(:student, section: nil)
      students_ids = [student1.id, student2.id]
      section_id = create(:section).id
      Student.update_section(students_ids, section_id)
      students = Student.find(students_ids)
      expect(students[0].section).not_to be_nil
    end

    it 'update the section of the students in the list, setting it to no section' do
      student1 = create(:student)
      student1.save
      student2 = create(:student)
      student2.save
      students_ids = [student1.id, student2.id]
      section_id = 0
      Student.update_section(students_ids, section_id)
      students = Student.find(students_ids)
      expect(students[0].section).to be_nil
    end

    context 'as a noteable' do
      it 'display for note without seeing an exception' do
        expect { @student.display_for_note }.not_to raise_error
      end
    end # end noteable context

  end
end
