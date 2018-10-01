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
require 'shoulda'

describe Student do

  # Tests for a generic Student instantiation
  context 'A good Student model' do

    it { should have_many(:accepted_groupings).through(:memberships) }
    it { should have_many(:pending_groupings).through(:memberships) }
    it { should have_many(:rejected_groupings).through(:memberships) }
    it { should have_many :student_memberships }
    it { should have_many :grace_period_deductions }
    it { should belong_to :section }

    it { should validate_numericality_of :grace_credits }
  end

  # context 'A pair of students in the same group' do
  #     @membership1 = StudentMembership.new(membership_status: StudentMembership::STATUSES[:inviter])
  #     @grouping = @membership1.grouping
  #     @membership2 = StudentMembership.new({grouping: @grouping,
  #                                            membership_status: StudentMembership::STATUSES[:accepted]})
  #     @student1 = @membership1.user
  #     @student2 = @membership2.user
  #
  #     @student_id_list = [@student1.id, @student2.id]
  #
  #   it 'can hide without error' do
  #     Student.hide_students(@student_id_list)
  #     students = Student.find(@student_id_list)
  #
  #     expect(students[0].hidden).to be true
  #     expect(students[1].hidden).to be true
  #   end
  #
  #   it 'should not cause error when user is not found on hide and remove' do
  #     # Mocks to enter into the if that leads to the call to remove the student
  #     expect(Assignment.any_instance.stubs(:vcs_submit)).to be true
  #     expect(Grouping.any_instance.stubs(:is_valid?)).to be true
  #
  #     # Mock the repository and raise Repository::UserNotFound
  #     mock_repo = mock('Repository::AbstractRepository')
  #     expect(mock_repo.stubs(:close)).to be true
  #     expect(mock_repo.stubs(:remove_user)).to raise_error(Repository::UserNotFound)
  #     expect(Group.any_instance.stubs(:repo)).to eq(mock_repo)
  #
  #     Student.hide_students(@student_id_list)
  #
  #     [{type: 'negative', grace_credits: '-10', expected: 0 },
  #     {type: 'positive', grace_credits: '10', expected: 15 }].each do |item|
  #       it "should not error when given #{item[:type]} grace credits" do
  #         expect(Student.give_grace_credits(@student_id_list, item[:grace_credits]))
  #
  #         #You have to find the students to get the updated values
  #         students = Student.find(@student_id_list)
  #
  #         expect(item[:expected]).eql?(students[0].grace_credits)
  #         expect(item[:expected]).eql?(students[1].grace_credits)
  #       end
  #     end
  #   end
  # end

  # context 'Hidden Students' do
  #     @student1 = Student.new(:hidden)
  #     @student2 = Student.new(:hidden)
  #
  #     @membership1 = StudentMembership.new({membership_status: StudentMembership::STATUSES[:inviter], user: @student1})
  #     @grouping = @membership1.grouping
  #     @membership2 = StudentMembership.new({grouping: @grouping, membership_status: StudentMembership::STATUSES[:accepted], user: @student2})
  #
  #     @student_id_list = [@student1.id, @student2.id]
  #
  #   it 'should unhide without error' do
  #     #TODO test the repo with mocks
  #     Student.unhide_students(@student_id_list)
  #
  #     students = Student.find(@student_id_list)
  #     expect(students[0].hidden).to be false
  #     expect(students[1].hidden).to be false
  #   end
  #
  #   it 'should unhide without error when users already exists in repo' do
  #     # Mocks to enter into the if
  #     expect(Assignment.any_instance.stubs(:vcs_submit)).to be true
  #     expect(Grouping.any_instance.stubs(:is_valid?)).to be true
  #
  #     # Mock the repository and raise Repository::UserNotFound
  #     mock_repo = mock('Repository::AbstractRepository')
  #     expect(mock_repo.stubs(:close)).to be true
  #     expect(mock_repo.stubs(:add_user)).to raise_error(Repository::UserAlreadyExistent)
  #     expect(Group.any_instance.stubs(:repo)).to eq(mock_repo)
  #
  #     Student.unhide_students(@student_id_list)
  #   end
  # end
  #
  # context 'A hidden Student' do
  #     @student = Student.new(:hidden)
  #
  #     it 'should not become a member of a grouping' do
  #       grouping = Grouping.new
  #       @student.invite(grouping.id)
  #
  #       pending_memberships = @student.pending_memberships_for(grouping.assignment_id)
  #
  #       expect(pending_memberships).not_to be_nil
  #       expect(pending_memberships.length).to eq(0)
  #     end
  #   end

  context 'A Student' do
    @student = Student.new

    context 'with an assignment' do
      @assignment = Assignment.new(group_name_autogenerated: false)

      it 'should not return nil on call to memberships_for' do
          expect(@student.memberships_for(@assignment.id)).not_to be_nil
      end

      it 'should return empty when there are no pending memberships' do
        pending_memberships = @student.pending_memberships_for(@assignment.id)

        expect(pending_memberships).not_to be_nil
        expect(pending_memberships.length).to eq(0)
      end

      it 'should return nil when there are no pending groupings' do
        expect(Student.any_instance.stubs(:pending_groupings_for)).to be_nil

        pending_memberships = @student.pending_memberships_for(@assignment.id)
        expect(pending_memberships).to be_nil
      end

      it 'should correctly return if it has accepted groupings' do
        expect(@student.has_accepted_grouping_for?(@assignment.id)).to be_falsey
        membership = StudentMembership.new(user: @student, grouping: Grouping.new(assignment: @assignment),
                                              membership_status: StudentMembership::STATUSES[:inviter])
        expect(@student.has_accepted_grouping_for?(@assignment.id)).to be true
      end

      it 'should correctly return the accepted grouping' do
        expect(@student.accepted_grouping_for(@assignment.id)).to be_nil
        grouping = Grouping.new(assignment: @assignment)
        membership = StudentMembership.new({user: @student, grouping: grouping,
                                             membership_status: StudentMembership::STATUSES[:inviter]})
        expect(grouping).to eq(@student.accepted_grouping_for(@assignment.id))
      end

      it 'should raise when creating an autogenerated name group' do
        expect(@student.create_autogenerated_name_group(@assignment.id)).to raise_error(RuntimeError)
      end
    end

    context 'and a grouping' do
      it 'should be invited to a grouping' do
        grouping = Grouping.new
        @student.invite(grouping.id)

        pending_memberships = @student.pending_memberships_for(grouping.assignment_id)

        expect(pending_memberships).not_to be_nil
        expect(pending_memberships.length).to eq(1)

        membership = pending_memberships[0]

        expect(StudentMembership::STATUSES[:pending]).to eq(membership.membership_status)
        expect(grouping.id).to eq(membership.grouping_id)
        expect(@student.id).to eq(membership.user_id)
      end
    end

    context 'with a group name autogenerated assignment' do
        @assignment = Assignment.new(group_name_autogenerated: true)
        # expect(@student.create_autogenerated_name_group(@assignment.id)).not_to be_nil

      it 'should assert no pending groupings after create' do
        expect(@student.has_pending_groupings_for?(@assignment.id)).to be_falsey
      end

      it 'should assert an accepted grouping exists after create' do
        expect(@student.has_accepted_grouping_for?(@assignment.id))
      end
    end

    context 'with a pending membership' do
        @membership = StudentMembership.new({user: @student})

      context 'on an assignment' do
        setup do
          @assignment = @membership.grouping.assignment
        end

        it 'can destroy all pending memberships' do
          @student.destroy_all_pending_memberships(@assignment.id)
          expect(@student.pending_memberships_for(@assignment.id).length).to eq(0)
        end

        it 'rejects all other pending memberships upon joining a group' do
          grouping = @membership.grouping
          membership2 = StudentMembership.new(grouping: Grouping.make(assignment: @assignment), user: @student)

          expect(@student.join(grouping.id))

          membership = StudentMembership.find_by_grouping_id_and_user_id(grouping.id, @student.id)
          expect(StudentMembership::STATUSES[:accepted]).to eq(membership.membership_status)

          otherMembership = Membership.find(membership2.id)
          expect(StudentMembership::STATUSES[:rejected]).eq(otherMembership.membership_status)
        end

        it 'should have pending memberships after their creation.' do
          membership2 = StudentMembership.new(grouping: Grouping.make(assignment: @assignment), user: @student)
          pending_memberships = @student.pending_memberships_for(@assignment.id)

          expect(pending_memberships).not_to be_nil
          expect(pending_memberships.length).to eq(2)

          expected_groupings = [@membership.grouping, membership2.grouping]
          expect(expected_groupings.map(&:id).to_set).to eq(pending_memberships.map(&:grouping_id).to_set)
          expect(pending_memberships.delete_if {|e| e.user_id == @student.id}).to eq([])
        end

        # context 'working alone' do
        #     expect(@student.create_group_for_working_alone_student(@assignment.id)).not_to raise_error
        #     @group = Group.where(group_name: @student.user_name).first
        #
        #   it 'create the group' do
        #     expect(Group.where(group_name: @student.user_name).first)
        #   end
        #
        #   it 'have their repo name equal their user name' do
        #     expect(@group.repo_name).to eq(@student.user_name)
        #   end
        #
        #   it 'not have any pending memberships' do
        #     expect(@student.has_pending_groupings_for?(@assignment.id)).to be false
        #   end
        #
        #   it 'have an accepted grouping' do
        #     expect(@student.has_accepted_grouping_for?(@assignment.id))
        #   end
        # end

        context 'working alone but has an existing group' do
          @group = Group.new
          @grouping = Grouping.new({group: @group, assignment: @assignment})
          @membership2 = StudentMembership.new({user: @student, membership_status: StudentMembership::STATUSES[:inviter], grouping: @grouping})

          it 'work' do
            expect(@student.create_group_for_working_alone_student(@assignment.id)).not_to raise_error
          end
        end
      end
    end

    context 'with grace credits' do
      it 'return remaining normally' do
        expect(@student.remaining_grace_credits).to eq(5)
      end

      it 'return normally when over deducted' do
        deduction1 = GracePeriodDeduction.make(membership: StudentMembership.make(user: @student))
        #deduction2 unused?
        deduction2 = GracePeriodDeduction.make(membership: deduction1.membership, deduction: 10)
        expect(@student.remaining_grace_credits).to eq(-25)
      end
    end

    it 'assert student has a section' do
      expect(@student.has_section?)
    end

    it "assert student doesn't have a section" do
      student = Student.make(section: nil)
      #redundant test? Section assigned within test, too controlled.
      expect(student.has_section?).to be_falsey
    end

    it 'update the section of the students in the list' do
      student1 = Student.new(section: nil)
      student2 = Student.new(section: nil)
      students_ids = [student1.id, student2.id]
      section_id = Section.new.id
      Student.update_section(students_ids, section_id)
      students = Student.find(students_ids)

      expect(students[0].section).not_to be_nil
    end

    it 'update the section of the students in the list, setting it to no section' do
      student1 = Student.new
      student1.save
      student2 = Student.new
      student2.save
      students_ids = [student1.id, student2.id]
      section_id = 0
      Student.update_section(students_ids, section_id)
      students = Student.find(students_ids)

      expect(students[0].section).not_to be_nil
    end

    context 'as a noteable' do
      it 'display for note without seeing an exception' do
        expect(@student.display_for_note).not_to raise_error
      end
    end
  end
end
