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

    it 'will have many grace period deductions available' do
      is_expected.to have_many :grace_period_deductions
    end

    it 'will belong to a section' do
      is_expected.to belong_to :section
    end

    it 'will have some number of grace credits' do
      is_expected.to validate_numericality_of :grace_credits
    end
  end

  context 'A pair of students in the same group' do
    before(:each) do
      @membership1 = create(:student_membership, membership_status: StudentMembership::STATUSES[:inviter])
      @grouping = @membership1.grouping
      @membership2 = create(:student_membership, grouping: @grouping,
                                             membership_status: StudentMembership::STATUSES[:accepted])
      @student1 = @membership1.user
      @student2 = @membership2.user
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
      allow_any_instance_of(Group).to receive(:repo).and_return(mock_repo)

      Student.hide_students(@student_id_list)
    end

    [{type: 'negative', grace_credits: '-10', expected: 0 },
     {type: 'positive', grace_credits: '10', expected: 15 }].each do |item|
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
                            user: @student1)
      @grouping = @membership1.grouping
      @membership2 = create(:student_membership, grouping: @grouping,
                            membership_status: StudentMembership::STATUSES[:accepted], user: @student2)
      @student_id_list = [@student1.id, @student2.id]
    end

    it 'should unhide without error' do
      #TODO test the repo with mocks
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
      allow_any_instance_of(Group).to receive(:repo).and_return(mock_repo)

      Student.unhide_students(@student_id_list)
    end
  end

  context 'A hidden Student' do

      it 'should not become a member of a grouping' do
        @student = create(:student, hidden: true)
        grouping = create(:grouping)
        @student.invite(grouping.id)

        pending_memberships = @student.pending_memberships_for(grouping.assignment_id)

        expect(pending_memberships).not_to be_nil
        expect(pending_memberships.length).to eq(0)
      end
    end

  context 'A Student' do
    before(:each) do
      @student = create(:student)
    end

    context 'with an assignment' do
      before(:each) do
        @assignment = create(:assignment, group_name_autogenerated: false)
      end

      it 'does not return nil on call to memberships_for' do
        expect(@student.memberships_for(@assignment.id)).not_to be_nil
      end

      it 'returns empty when there are no pending memberships' do
        pending_memberships = @student.pending_memberships_for(@assignment.id)
        expect(pending_memberships).not_to be_nil
        expect(pending_memberships.length).to eq(0)
      end

      it 'returns nil when there are no pending groupings' do
        allow_any_instance_of(Student).to receive(:pending_groupings_for).and_return(nil)
        pending_memberships = @student.pending_memberships_for(@assignment.id)
        expect(pending_memberships).to be_nil
      end

      it 'correctly returns if it has accepted groupings' do
        expect(@student.has_accepted_grouping_for?(@assignment.id)).to be_falsey
        @grouping = create(:grouping, assignment: @assignment)
        create(:student_membership, user: @student, grouping: @grouping,
                                            membership_status: StudentMembership::STATUSES[:inviter])
        expect(@student.has_accepted_grouping_for?(@assignment.id)).to be true
      end

      it 'correctly returns the accepted grouping' do
        expect(@student.accepted_grouping_for(@assignment.id)).to be_nil
        grouping = create(:grouping, assignment: @assignment)
        create(:student_membership, user: @student, grouping: grouping,
                                           membership_status: StudentMembership::STATUSES[:inviter])
        expect(grouping).to eq(@student.accepted_grouping_for(@assignment.id))
      end

      it 'raises an error when creating an autogenerated name group' do
        expect { @student.create_autogenerated_name_group(@assignment.id) }.to raise_error
      end
    end

    context 'and a grouping' do
      it 'should be invited to a grouping' do
        grouping = create(:grouping)
        @student.invite(grouping.id)

        pending_memberships = @student.pending_memberships_for(grouping.assignment_id)

        expect(pending_memberships).not_to be_nil
        expect(pending_memberships.length).to eq 1

        membership = pending_memberships[0]

        expect(StudentMembership::STATUSES[:pending]).to eq(membership.membership_status)
        expect(grouping.id).to eq(membership.grouping_id)
        expect(@student.id).to eq(membership.user_id)
      end
    end

    context 'with a group name autogenerated assignment' do
      before(:each) do
        @assignment = create(:assignment, group_name_autogenerated: true)
        @student.create_autogenerated_name_group(@assignment.id)
      end

      it 'should assert no pending groupings after create' do
        expect(@student.has_pending_groupings_for?(@assignment.id)).to be_falsey
      end

      it 'should assert an accepted grouping exists after create' do
        expect(@student.has_accepted_grouping_for?(@assignment.id)).to_not be_nil
      end
    end

    context 'with a pending membership' do
      before(:each) do
        @membership = create(:student_membership, user: @student)
      end

      context 'on an assignment' do
        before(:each) do
          @assignment = @membership.grouping.assignment
        end

        it 'can destroy all pending memberships' do
          @student.destroy_all_pending_memberships(@assignment.id)
          expect(@student.pending_memberships_for(@assignment.id).length).to eq(0)
        end

        it 'rejects all other pending memberships upon joining a group' do
          grouping = @membership.grouping
          grouping2 = create(:grouping, assignment: @assignment)
          membership2 = create(:student_membership, grouping: grouping2, user: @student)

          expect(@student.join(grouping.id))

          membership = StudentMembership.find_by_grouping_id_and_user_id(grouping.id, @student.id)
          expect(StudentMembership::STATUSES[:accepted]).to eq(membership.membership_status)

          other_membership = Membership.find(membership2.id)
          expect(StudentMembership::STATUSES[:rejected]).to eq(other_membership.membership_status)
        end

        it 'should have pending memberships after their creation.' do
          grouping2 = create(:grouping, assignment: @assignment)
          membership2 = create(:student_membership, grouping: grouping2, user: @student)
          pending_memberships = @student.pending_memberships_for(@assignment.id)

          expect(pending_memberships).not_to be_nil
          expect(pending_memberships.length).to eq(2)

          expected_groupings = [@membership.grouping, membership2.grouping]
          expect(expected_groupings.map(&:id).to_set).to eq(pending_memberships.map(&:grouping_id).to_set)
          expect(pending_memberships.delete_if { |e| e.user_id == @student.id }).to eq([])
        end

        context 'working alone' do
          before(:each) do
            expect(@student.create_group_for_working_alone_student(@assignment.id))
            @group = Group.find_by(group_name: @student.user_name)
          end

          it 'should create the group' do
            expect(@group).to_not be_nil
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
        end

        context 'working alone but has an existing group' do
          before(:each) do
            @group = create(:group)
            @grouping = create(:grouping, group: @group, assignment: @assignment)
            @membership2 = create(:student_membership, user: @student,
                                  membership_status: StudentMembership::STATUSES[:inviter], grouping: @grouping)
          end

          it 'will not cause any errors' do
            expect { @student.create_group_for_working_alone_student(@assignment.id) }.to_not raise_error
          end
        end
      end
    end

    context 'with grace credits' do
      it 'return remaining normally' do
        expect(@student.remaining_grace_credits).to eq 5
      end

      #FAILING
      it 'return normally when over deducted' do
        membership = create(:student_membership, user: @student)
        create(:grace_period_deduction, membership: membership, deduction: 10)
        create(:grace_period_deduction, membership: membership, deduction: 20)
        expect(@student.remaining_grace_credits).to eq -25
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

   end
end
