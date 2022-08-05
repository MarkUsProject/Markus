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

describe Student do
  context 'A good Student model' do
    subject { create :student }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:course_id) }
    it 'will have many accepted groupings' do
      is_expected.to have_many(:accepted_groupings).through(:memberships)
    end

    it 'will have many pending groupings' do
      is_expected.to have_many(:pending_groupings).through(:memberships)
    end

    it 'will have many rejected groupings' do
      is_expected.to have_many(:rejected_groupings).through(:memberships)
    end

    it 'will have many student memberships' do
      is_expected.to have_many :student_memberships
    end

    it 'will have many accepted memberships' do
      is_expected.to have_many :accepted_memberships
    end

    it 'will have many grace period deductions available' do
      is_expected.to have_many :grace_period_deductions
    end

    it 'will belong to a section' do
      is_expected.to belong_to(:section).optional
    end

    it 'will have some number of grace credits' do
      is_expected.to validate_numericality_of :grace_credits
    end

    it 'has a preference for receives_invite_emails' do
      should allow_value(true).for(:receives_invite_emails)
      should allow_value(false).for(:receives_invite_emails)
      should_not allow_value(nil).for(:receives_invite_emails)
    end

    it 'has a preference for receives_results_emails' do
      should allow_value(true).for(:receives_results_emails)
      should allow_value(false).for(:receives_results_emails)
      should_not allow_value(nil).for(:receives_results_emails)
    end
  end

  context 'A pair of students in the same group' do
    before(:each) do
      @membership1 = create(:student_membership, membership_status: StudentMembership::STATUSES[:inviter])
      @grouping = @membership1.grouping
      @membership2 = create(:student_membership, grouping: @grouping,
                                                 membership_status: StudentMembership::STATUSES[:accepted])
      @student1 = @membership1.role
      @student2 = @membership2.role
      @student_id_list = [@student1.id, @student2.id]
    end

    it 'can be hidden without error' do
      Student.hide_students(@student_id_list)

      expect(@student1.reload.hidden).to be true
      expect(@student2.reload.hidden).to be true
    end

    it 'should not cause error when user is not found on hide and remove' do
      # Mocks to enter into the if that leads to the call to remove the student
      allow_any_instance_of(Assignment).to receive(:vcs_submit)
      allow_any_instance_of(Grouping).to receive(:is_valid?)

      # Mock the repository and raise Repository::UserNotFound
      mock_repo = class_double('Repository::AbstractRepository')
      allow_any_instance_of(mock_repo).to receive(:close).and_return(true)
      allow_any_instance_of(mock_repo).to receive(:remove_user).and_return(Repository::UserNotFound)
      allow_any_instance_of(Group).to receive(:access_repo).and_yield(mock_repo)

      Student.hide_students(@student_id_list)
    end

    [{ type: 'negative', grace_credits: '-10', expected: 0 },
     { type: 'positive', grace_credits: '10', expected: 15 }].each do |item|
      it "should not error when given #{item[:type]} grace credits" do
        expect(Student.give_grace_credits(@student_id_list, item[:grace_credits]))

        expect(item[:expected]).eql?(@student1.grace_credits)
        expect(item[:expected]).eql?(@student2.grace_credits)
      end
    end
  end

  context 'Hidden Students' do
    before(:each) do
      @student1 = create(:student, hidden: true)
      @student2 = create(:student, hidden: true)

      @membership1 = create(:student_membership, membership_status: StudentMembership::STATUSES[:inviter],
                                                 role: @student1)
      @grouping = @membership1.grouping
      @membership2 = create(:student_membership, grouping: @grouping,
                                                 membership_status: StudentMembership::STATUSES[:accepted],
                                                 role: @student2)
      @student_id_list = [@student1.id, @student2.id]
    end

    it 'should unhide without error' do
      # TODO: test the repo with mocks
      Student.unhide_students(@student_id_list)

      expect(@student1.reload.hidden).to be false
      expect(@student2.reload.hidden).to be false
    end

    it 'should unhide without error when users already exists in repo' do
      # Mocks to enter into the if
      allow_any_instance_of(Assignment).to receive(:vcs_submit)
      allow_any_instance_of(Grouping).to receive(:is_valid?)

      # Mock the repository and raise Repository::UserNotFound
      mock_repo = class_double('Repository::AbstractRepository')
      allow_any_instance_of(mock_repo).to receive(:close).and_return(true)
      allow_any_instance_of(mock_repo).to receive(:add_user).and_return(Repository::UserAlreadyExistent)
      allow_any_instance_of(Group).to receive(:access_repo).and_yield(mock_repo)

      Student.unhide_students(@student_id_list)
    end
  end

  context 'A hidden student' do
    it 'cannot be invited to a grouping' do
      student = create(:student, hidden: true)
      grouping = create(:grouping)
      student.invite(grouping.id)

      expect(student.student_memberships.size).to eq 0
    end
  end

  context 'A Student' do
    before(:each) do
      @student = create(:student)
    end

    context 'and a grouping' do
      it 'should be invited to a grouping' do
        grouping = create(:grouping)
        @student.invite(grouping.id)

        expect(@student.student_memberships.size).to eq 1
        membership = @student.student_memberships.first

        expect(membership.grouping_id).to eq(grouping.id)
        expect(membership.membership_status).to eq StudentMembership::STATUSES[:pending]
      end
    end

    context 'with a group name autogenerated assignment' do
      before(:each) do
        @assignment = create(:assignment, assignment_properties_attributes: { group_name_autogenerated: true })
        @grouping = @student.create_autogenerated_name_group(@assignment)
      end

      it 'should assert no pending groupings after create' do
        expect(@student.has_pending_groupings_for?(@assignment.id)).to be_falsey
      end

      it 'should create the group in the same course as the assignment' do
        expect(@grouping.group.course_id).to eq @assignment.course_id
      end

      it 'should assert an accepted grouping exists after create' do
        expect(@student.has_accepted_grouping_for?(@assignment.id)).to_not be_nil
      end
    end

    context 'with a pending membership' do
      before(:each) do
        @membership = create(:student_membership, role: @student)
      end

      context 'on an assignment' do
        before(:each) do
          @assignment = @membership.grouping.assignment
        end

        it 'can destroy all pending memberships' do
          @student.destroy_all_pending_memberships(@assignment.id)
          expect(@student.student_memberships
                         .where(membership_status: StudentMembership::STATUSES[:pending])
                         .size).to eq 0
        end

        it 'rejects all other pending memberships upon joining a group' do
          grouping = @membership.grouping
          grouping2 = create(:grouping, assignment: @assignment)
          membership2 = create(:student_membership, grouping: grouping2, role: @student)

          expect(@student.join(grouping))

          membership = StudentMembership.find_by(grouping_id: grouping.id, role_id: @student.id)
          expect(StudentMembership::STATUSES[:accepted]).to eq(membership.membership_status)

          other_membership = Membership.find(membership2.id)
          expect(StudentMembership::STATUSES[:rejected]).to eq(other_membership.membership_status)
        end

        it 'should have pending memberships after their creation.' do
          grouping2 = create(:grouping, assignment: @assignment)
          create(:student_membership, grouping: grouping2, role: @student)
          expect(@student.student_memberships
                         .pluck(:grouping_id).sort).to eq [@membership.grouping_id, grouping2.id].sort
        end

        context 'working alone' do
          before(:each) do
            expect(@student.create_group_for_working_alone_student(@assignment.id))
            @group = Group.find_by(group_name: @student.user_name)
          end

          it 'should create the group' do
            expect(@group).to_not be_nil
          end

          it 'should create the group in the same course as the assignment' do
            expect(@group.course_id).to eq @assignment.course_id
          end

          it 'have their repo name equal their user name' do
            expect(@group.repo_name).to eq(@student.user_name)
          end

          it 'not have any pending memberships' do
            expect(@student.has_pending_groupings_for?(@assignment.id)).to be false
          end

          it 'have an accepted grouping' do
            expect(@student.has_accepted_grouping_for?(@assignment.id))
          end

          context 'a timed assignment' do
            let(:assignment) { create :timed_assignment }
            let(:group) do
              @student.create_group_for_working_alone_student(assignment.id)
              @student.groupings.find_by(assessment_id: assignment.id).group
            end

            it 'should always create a group with an autogenerated group name' do
              expect(group.group_name).to eq(group.get_autogenerated_group_name)
            end
          end
        end

        context 'working alone but has an existing group' do
          before(:each) do
            @grouping = create(:grouping, assignment: @assignment)
            @membership2 = create(:student_membership,
                                  role: @student,
                                  membership_status: StudentMembership::STATUSES[:inviter],
                                  grouping: @grouping)
          end

          it 'will raise a validation error' do
            expect { @student.create_group_for_working_alone_student(@assignment.id) }.to(
              raise_error(ActiveRecord::RecordInvalid)
            )
          end
        end
      end
    end

    context 'with grace credits' do
      it 'return remaining normally' do
        expect(@student.remaining_grace_credits).to eq 5
      end

      # FAILING
      it 'return normally when over deducted' do
        membership = create(:student_membership, role: @student)
        create(:grace_period_deduction, membership: membership, deduction: 10)
        create(:grace_period_deduction, membership: membership, deduction: 20)
        expect(@student.remaining_grace_credits).to eq(-25)
      end
    end

    context 'as a noteable' do
      it 'display for note without seeing an exception' do
        expect(@student.display_for_note).to_not be_nil
      end
    end

    it 'assert student has a section' do
      expect(@student.has_section?).to_not be_nil
    end

    it "assert student doesn't have a section" do
      student = create(:student, section: nil)
      expect(student.has_section?).to be_falsey
    end

    it 'update the section of the students in the list' do
      student1 = create(:student, section: nil)
      student2 = create(:student, section: nil)
      students_ids = [student1.id, student2.id]
      section_temp = create(:section)
      section_id = section_temp.id
      Student.update_section(students_ids, section_id)
      students = Student.find(students_ids)

      expect(students[0].section).not_to be_nil
    end

    it 'update the section of the students in the list, setting it to no section' do
      student1 = create(:student)
      student2 = create(:student)
      students_ids = [student1.id, student2.id]
      section_id = 0
      Student.update_section(students_ids, section_id)
      students = Student.find(students_ids)

      expect(students[0].section).to be_nil
    end

    it 'cannot be assigned to an admin user' do
      expect(build(:student, user: create(:admin_user))).not_to be_valid
    end

    it 'cannot be assigned to an autotest user' do
      expect(build(:student, user: create(:autotest_user))).not_to be_valid
    end
  end
end
