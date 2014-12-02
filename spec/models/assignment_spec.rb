require 'spec_helper'

describe Assignment do

  describe 'ActiveRecord associations' do
    it { is_expected.to have_one(:submission_rule).dependent(:destroy) }
    it { is_expected.to validate_presence_of(:submission_rule) }
    it { is_expected.to have_many(:annotation_categories).dependent(:destroy) }
    it { is_expected.to have_many(:groupings) }
    it { is_expected.to have_many(:ta_memberships).through(:groupings) }
    it { is_expected.to have_many(:student_memberships).through(:groupings) }
    it { is_expected.to have_many(:tokens).through(:groupings) }
    it { is_expected.to have_many(:submissions).through(:groupings) }
    it { is_expected.to have_many(:groups).through(:groupings) }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:section_due_dates) }
    it { is_expected.to accept_nested_attributes_for(:section_due_dates) }
    it { is_expected.to have_one(:assignment_stat).dependent(:destroy) }
    it do
      is_expected.to have_many(:rubric_criteria).dependent(:destroy)
        .order(:position)
    end
    it do
      is_expected.to have_many(:flexible_criteria).dependent(:destroy)
        .order(:position)
    end
    it { is_expected.to have_many(:assignment_files).dependent(:destroy) }
    it do
      is_expected.to accept_nested_attributes_for(:assignment_files)
        .allow_destroy(true)
    end
    it { is_expected.to have_many(:test_files).dependent(:destroy) }
    it do
      is_expected.to accept_nested_attributes_for(:test_files)
        .allow_destroy(true)
    end
    it do
      is_expected.to have_many(:criterion_ta_associations).dependent(:destroy)
    end
    it do
      is_expected.to accept_nested_attributes_for(:submission_rule)
        .allow_destroy(true)
    end
    it do
      is_expected.to accept_nested_attributes_for(:assignment_stat)
        .allow_destroy(true)
    end
  end

  describe 'ActiveModel validations' do
    it { is_expected.to validate_presence_of(:short_identifier) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:repository_folder) }
    it { is_expected.to validate_presence_of(:due_date) }
    it { is_expected.to validate_presence_of(:marking_scheme_type) }
    it { is_expected.to validate_presence_of(:group_min) }
    it { is_expected.to validate_presence_of(:group_max) }
    it { is_expected.to validate_presence_of(:notes_count) }
    it do
      is_expected.to validate_numericality_of(:group_min).is_greater_than(0)
    end
    it do
      is_expected.to validate_numericality_of(:group_max).is_greater_than(0)
    end
    it do
      is_expected.to validate_numericality_of(:tokens_per_day)
        .is_greater_than_or_equal_to(0)
    end

    it 'should require case sensitive unique value for short_identifier' do
      assignment = create(:assignment)
      expect(assignment).to validate_uniqueness_of(:short_identifier)
    end
  end

  describe 'custom validations' do
    it 'fails when group_max less than group_min' do
      assignment = build(:assignment, group_max: 1, group_min: 2)
      expect(assignment).not_to be_valid
    end

    it 'fails when due_date is invalid' do
      assignment = build(:assignment, due_date: '2000/01/40')
      expect(assignment).not_to be_valid
    end
  end

  let(:assignment) do
    build_stubbed(:assignment).tap do |assignment|
      allow(assignment).to receive(:save)
    end
  end

  describe '#tas' do
    before :each do
      @assignment = create(:assignment)
    end

    context 'when no TAs have been assigned' do
      it 'returns an empty array' do
        expect(@assignment.tas).to eq []
      end
    end

    context 'when TA(s) have been assigned to an assignment' do
      before :each do
        @grouping = create(:grouping, assignment: @assignment)
        @ta = create(:ta)
        @ta_membership = create(:ta_membership, user: @ta, grouping: @grouping)
      end

      describe 'one TA' do
        it 'returns the TA' do
          expect(@assignment.tas).to eq [@ta]
        end
      end

      describe 'more than one TA' do
        before :each do
          @other_ta = create(:ta)
          @ta_membership =
            create(:ta_membership, user: @other_ta, grouping: @grouping)
        end

        it 'returns all TAs' do
          expect(@assignment.tas).to eq [@ta, @other_ta]
        end
      end
    end
  end

  describe '#criterion_class' do
    context 'when the marking_scheme_type is rubric' do
      before :each do
        @assignment = build(:assignment, marking_scheme_type: Assignment::MARKING_SCHEME_TYPE[:rubric])
      end

      it 'returns RubricCriterion' do
        expect(@assignment.criterion_class).to equal(RubricCriterion)
      end
    end

    context 'when the marking_scheme_type is flexible' do
      before :each do
        @assignment = build(:assignment, marking_scheme_type: Assignment::MARKING_SCHEME_TYPE[:flexible])
      end

      it 'returns FlexibleCriterion' do
        expect(@assignment.criterion_class).to equal(FlexibleCriterion)
      end
    end

    context 'when the marking_scheme_type is nil' do
      before :each do
        @assignment = build(:assignment, marking_scheme_type: nil)
      end

      it 'returns nil' do
        expect(@assignment.criterion_class).to be_nil
      end
    end
  end

  describe '#group_assignment?' do
    context 'when invalid_override is allowed' do
      let(:assignment) { build(:assignment, invalid_override: true) }

      it 'returns true' do
        expect(assignment.group_assignment?).to be true
      end
    end

    context 'when invalid_override is not allowed ' do
      context 'and group_max is greater than 1' do
        let(:assignment) do
          build(:assignment, invalid_override: false, group_max: 2)
        end

        it 'returns true' do
          expect(assignment.group_assignment?).to be true
        end
      end

      context 'and group_max is 1' do
        let(:assignment) do
          build(:assignment, invalid_override: false, group_max: 1)
        end

        it 'returns false' do
          expect(assignment.group_assignment?).to be false
        end
      end
    end
  end

  describe '#add_group' do
    context 'when the group name is autogenerated' do
      before :each do
        @assignment = create(:assignment, group_name_autogenerated: true)
      end

      it 'adds a group and returns the new grouping' do
        expect(@assignment.add_group).to be_a Grouping
        expect(Group.count).to eq 1
      end
    end

    context 'when the the group name is not autogenerated' do
      before :each do
        @assignment = create(:assignment, group_name_autogenerated: false)
        @group_name = 'a_group_name'
      end

      it 'adds a group with the given name and returns the new grouping' do
        grouping = @assignment.add_group(@group_name)
        group = @assignment.groups.where(group_name: @group_name).first

        expect(grouping).to be_a Grouping
        expect(group).to be_a Group
      end

      context 'and a group with the same name exists' do
        before :each do
          @group = create(:group, group_name: @group_name)
        end

        context 'for this assignment' do
          before :each do
            create(:grouping, assignment: @assignment, group: @group)
          end

          it 'raises an exception' do
            expect { @assignment.add_group(@group_name) }.to raise_error
          end
        end

        context 'for another assignment' do
          before :each do
            assignment = create(:assignment)
            create(:grouping, assignment: assignment, group: @group)
          end

          it 'adds the group and returns the new grouping' do
            grouping = @assignment.add_group(@group_name)
            group = @assignment.groups.where(group_name: @group_name).first

            expect(grouping).to be_a Grouping
            expect(group).to be_a Group
          end
        end
      end
    end
  end

  describe '#valid_groupings and #invalid_groupings' do
    before :each do
      @assignment = create(:assignment)
      @groupings = (1..2).map { create(:grouping, assignment: @assignment) }
    end

    context 'when no groups are valid' do
      it '#valid_groupings returns an empty array' do
        expect(@assignment.valid_groupings).to eq []
      end

      it '#invalid_groupings returns all groupings' do
        expect(@assignment.invalid_groupings).to match_array(@groupings)
      end
    end

    context 'when one group is valid' do
      context 'due to admin_approval' do
        before :each do
          @groupings.first.update_attribute(:admin_approved, true)
        end

        it '#valid_groupings returns the valid group' do
          expect(@assignment.valid_groupings).to eq [@groupings.first]
        end

        it '#invalid_groupings returns other, invalid groups' do
          expect(@assignment.invalid_groupings)
            .to match_array(@groupings.drop(1))
        end
      end

      context 'due to meeting min size requirement' do
        before :each do
          create(:accepted_student_membership,
                 grouping: @groupings.first,
                 user: create(:student))
        end

        it '#valid_groupings returns the valid group' do
          expect(@assignment.valid_groupings).to eq [@groupings.first]
        end

        it '#invalid_groupings returns other, invalid groups' do
          expect(@assignment.invalid_groupings)
            .to match_array(@groupings.drop(1))
        end
      end
    end

    context 'when all groups are valid' do
      before :each do
        @groupings.each do |grouping|
          create(:accepted_student_membership,
                 grouping: grouping,
                 user: create(:student))
        end
      end

      it '#valid_groupings returns all groupings' do
        expect(@assignment.valid_groupings).to match_array(@groupings)
      end

      it '#invalid_groupings returns an empty array' do
        expect(@assignment.invalid_groupings).to eq []
      end
    end
  end

  describe '#grouped_students' do
    before :each do
      @assignment = create(:assignment)
      @grouping = create(:grouping, assignment: @assignment)
    end

    context 'when no students are grouped' do
      it 'returns an empty array' do
        expect(@assignment.grouped_students).to eq []
      end
    end

    context 'when students are grouped' do
      before :each do
        @student = create(:student)
        @membership = create(:accepted_student_membership,
                             user: @student,
                             grouping: @grouping)
      end

      describe 'one student' do
        it 'returns the student' do
          expect(@assignment.grouped_students).to eq [@student]
        end
      end

      describe 'more than one student' do
        before :each do
          @other_student = create(:student)
          @other_membership = create(:accepted_student_membership,
                                     user: @other_student,
                                     grouping: @grouping)
        end

        it 'returns the students' do
          expect(@assignment.grouped_students).to eq [@student, @other_student]
        end
      end
    end
  end

  describe '#ungrouped_students' do
    before :each do
      @assignment = create(:assignment)
      @grouping = create(:grouping, assignment: @assignment)
      @students = (1..2).map { create(:student) }
    end

    context 'when all students are ungrouped' do
      it 'returns all of the students' do
        expect(@assignment.ungrouped_students).to match_array(@students)
      end
    end

    context 'when no students are ungrouped' do
      before :each do
        @students.each do |student|
          create(:accepted_student_membership,
                 user: student,
                 grouping: @grouping)
        end
      end

      it 'returns an empty array' do
        expect(@assignment.ungrouped_students).to eq []
      end
    end
  end

  describe '#assigned_groupings and #unassigned_groupings' do
    before :each do
      @assignment = create(:assignment)
    end

    context 'when there are no groupings' do
      it '#assigned_groupings and #unassigned_groupings returns no groupings' do
        expect(@assignment.assigned_groupings).to eq []
        expect(@assignment.unassigned_groupings).to eq []
      end
    end

    context 'when there are multiple groupings' do
      before :each do
        @groupings = (1..2).map { create(:grouping, assignment: @assignment) }
      end

      context 'and no TAs have been assigned' do
        it '#assigned_groupings returns no groupings' do
          expect(@assignment.assigned_groupings).to eq []
        end

        it '#unassigned_groupings returns all groupings' do
          expect(@assignment.unassigned_groupings).to match_array(@groupings)
        end
      end

      context 'and multiple TAs are assigned to one grouping' do
        before :each do
          2.times do
            create(:ta_membership, grouping: @groupings[0], user: create(:ta))
          end
        end

        it '#assigned_groupings returns that grouping' do
          expect(@assignment.assigned_groupings).to eq [@groupings.first]
        end

        it '#unassigned_groupings returns the other groupings' do
          expect(@assignment.unassigned_groupings)
            .to match_array(@groupings.drop(1))
        end
      end

      context 'and all groupings have a TA assigned' do
        before :each do
          @groupings.each do |grouping|
            create(:ta_membership, grouping: grouping, user: create(:ta))
          end
        end

        it '#assigned_groupings returns all groupings' do
          expect(@assignment.assigned_groupings).to match_array(@groupings)
        end

        it '#unassigned_groupings returns no groupings' do
          expect(@assignment.unassigned_groupings).to eq []
        end
      end
    end
  end

  describe '#past_remark_due_date?' do
    context 'before the remark due date' do
      let(:assignment) { build(:assignment, remark_due_date: 1.days.from_now) }

      it 'returns false' do
        expect(assignment.past_remark_due_date?).to be false
      end
    end

    context 'after the remark due date' do
      let(:assignment) { build(:assignment, remark_due_date: 1.days.ago) }

      it 'returns true' do
        expect(assignment.past_remark_due_date?).to be true
      end
    end
  end

  describe '#groups_submitted' do
    before :each do
      @assignment = create(:assignment)
    end

    context 'when no groups have made a submission' do
      it 'returns an empty array' do
        expect(@assignment.groups_submitted).to eq []
      end
    end

    context 'when one group has submitted' do
      before :each do
        @grouping = create(:grouping, assignment: @assignment)
      end

      describe 'once' do
        before :each do
          create(:version_used_submission, grouping: @grouping)
        end

        it 'returns the group' do
          expect(@assignment.groups_submitted).to eq [@grouping]
        end
      end

      describe 'more than once' do
        before :each do
          create(:version_used_submission, grouping: @grouping)
          create(:version_used_submission, grouping: @grouping)
        end

        it 'returns one instance of the group' do
          expect(@assignment.groups_submitted).to eq [@grouping]
        end
      end
    end

    context 'when multiple groups have submitted' do
      before :each do
        @groupings = (1..2).map { create(:grouping, assignment: @assignment) }
        @groupings.each do |group|
          create(:version_used_submission, grouping: group)
        end
      end

      it 'returns those groups' do
        expect(@assignment.groups_submitted).to match_array(@groupings)
      end
    end
  end

  describe '#graded_submission_results' do
    before :each do
      @assignment = create(:assignment)
      @grouping = create(:grouping, assignment: @assignment)
      @submission = create(:version_used_submission, grouping: @grouping)
      @other_grouping = create(:grouping, assignment: @assignment)
      @other_submission =
        create(:version_used_submission, grouping: @other_grouping)
    end

    context 'when no submissions have been graded' do
      it 'returns an empty array' do
        expect(@assignment.graded_submission_results.size).to eq 0
      end
    end

    context 'when submission(s) have been graded' do
      before :each do
        @result = @submission.get_latest_result
        @result.marking_state = Result::MARKING_STATES[:complete]
        @result.save
      end

      describe 'one submission' do
        it 'returns the result' do
          expect(@assignment.graded_submission_results).to eq [@result]
        end
      end

      describe 'all submissions' do
        before :each do
          @other_result = @other_submission.get_latest_result
          @other_result.marking_state = Result::MARKING_STATES[:complete]
          @other_result.save
        end

        it 'returns all of the results' do
          expect(@assignment.graded_submission_results)
            .to eq [@result, @other_result]
        end
      end
    end
  end

  describe '#add_csv_group' do
    before :each do
      @assignment = create(:assignment)
    end

    context 'when the row is empty' do
      it 'does not add a Group or Grouping' do
        expect(Group.all).to eq []
        expect(Grouping.all).to eq []
      end
    end

    context 'when the row is not empty' do
      before :each do
        @students = (1..2).map { create(:student) }
        user_names = @students.map { |student| student.user_name }
        @row = ['group_name', 'repo_name'] + user_names
      end

      context 'and the group does not exist' do
        it 'adds a Group and an associated Grouping' do
          @assignment.add_csv_group(@row)
          group = Group.where(group_name: @row[0])
          grouping = group ? group.first.groupings : nil

          expect(group.size).to eq 1
          expect(grouping.size).to eq 1
        end

        it 'adds the StudentMemberships for the students' do
          @assignment.add_csv_group(@row)
          memberships = StudentMembership.where(user_id: @students)

          expect(memberships.size).to eq 2
        end
      end

      context 'and the group already exists' do
        before :each do
          @existing_group = create(:group, group_name: @row[0])
        end

        it 'does not add a new Group' do
          @assignment.add_csv_group(@row)
          expect(Group.all.size).to eq 1
        end

        it 'adds a Grouping to the existing Group' do
          @assignment.add_csv_group(@row)
          expect(Grouping.first.group).to eq @existing_group
        end
      end
    end
  end

  describe '#section_due_date' do
    context 'with SectionDueDates disabled' do
      before :each do
        @assignment = create(:assignment,
                             due_date: Time.now,
                             section_due_dates_type: false)
      end

      context 'when no section is specified' do
        it 'returns the due date of the assignment' do
          expect(@assignment.section_due_date(nil)).to eq @assignment.due_date
        end
      end

      context 'when a section is specified' do
        it 'returns the due date of the assignment' do
          section = create(:section)
          expect(@assignment.section_due_date(section))
            .to eq @assignment.due_date
        end
      end
    end

    context 'with SectionDueDates enabled' do
      before :each do
        @assignment = create(:assignment,
                             due_date: 1.days.ago,
                             section_due_dates_type: true)
      end

      context 'when no section is specified' do
        it 'returns the due date of the assignment' do
          expect(@assignment.section_due_date(nil).day).to eq 1.days.ago.day
        end
      end

      context 'when a section is specified' do
        before :each do
          @section = create(:section)
        end

        context 'that does not have a SectionDueDate' do
          it 'returns the due date of the assignment' do
            section_due_date = @assignment.section_due_date(@section)
            expect(section_due_date.day).to eq 1.days.ago.day
          end
        end

        context 'that has a SectionDueDate for another assignment' do
          before :each do
            SectionDueDate.create(section: @section,
                                  assignment: create(:assignment),
                                  due_date: 2.days.ago)
          end

          it 'returns the due date of the assignment' do
            section_due_date = @assignment.section_due_date(@section)
            expect(section_due_date.day).to eq 1.days.ago.day
          end
        end

        context 'that has a SectionDueDate for this assignment' do
          before :each do
            SectionDueDate.create(section: @section,
                                  assignment: @assignment,
                                  due_date: 2.days.ago)
          end

          it 'returns the due date of the section' do
            section_due_date = @assignment.section_due_date(@section)
            expect(section_due_date.day).to eq 2.days.ago.day
          end
        end
      end
    end
  end

  describe '#latest_due_date' do
    context 'when SectionDueDates are disabled' do
      before :each do
        @assignment = create(:assignment,
                             section_due_dates_type: false,
                             due_date: Time.now)
      end

      it 'returns the due date of the assignment' do
        expect(@assignment.latest_due_date).to eq @assignment.due_date
      end
    end

    context 'when SectionDueDates are enabled' do
      before :each do
        @assignment = create(:assignment,
                             section_due_dates_type: true,
                             due_date: Time.now)
      end

      context 'and there are no SectionDueDates' do
        it 'returns the due date of the assignment' do
          expect(@assignment.latest_due_date).to eq @assignment.due_date
        end
      end

      context 'and a SectionDueDate has the latest due date' do
        before :each do
          @section_due_date = SectionDueDate.create(section: create(:section),
                                                    assignment: @assignment,
                                                    due_date: 1.days.from_now)
        end

        it 'returns the due date of that SectionDueDate' do
          expect(@assignment.latest_due_date).to eq @section_due_date.due_date
        end
      end

      context 'and the assignment has the latest due date' do
        before :each do
          @section_due_date = SectionDueDate.create(section: create(:section),
                                                    assignment: @assignment,
                                                    due_date: 1.days.ago)
        end

        it 'returns the due date of the assignment' do
          expect(@assignment.latest_due_date).to eq @assignment.due_date
        end
      end
    end
  end

  describe '#past_due_date?' do
    context 'when the assignment is not past due' do
      before :each do
        @assignment = create(:assignment, due_date: 1.days.from_now)
      end

      context 'and SectionDueDates are disabled' do
        before :each do
          @assignment.update_attributes(section_due_dates_type: false)
        end

        it 'returns false' do
          expect(@assignment.past_due_date?).to be false
        end
      end

      context 'and there are SectionDueDates past due' do
        before :each do
          @assignment.update_attributes(section_due_dates_type: true)
          SectionDueDate.create(section: create(:section),
                                assignment: @assignment,
                                due_date: 1.days.ago)
        end

        it 'returns false' do
          pending 'pending discussion on intended functionality'
          expect(@assignment.past_due_date?).to be false
        end
      end
    end

    context 'when the assignment is past due' do
      before :each do
        @assignment = create(:assignment, due_date: 1.days.ago)
      end

      context 'and SectionDueDates are disabled' do
        before :each do
          @assignment.update_attributes(section_due_dates_type: false)
        end

        it 'returns true' do
          expect(@assignment.past_due_date?).to be true
        end
      end

      context 'and there is a SectionDueDate not past due' do
        before :each do
          @assignment.update_attributes(section_due_dates_type: true)
          SectionDueDate.create(section: create(:section),
                                assignment: @assignment,
                                due_date: 1.days.from_now)
        end

        it 'returns false' do
          expect(@assignment.past_due_date?).to be false
        end
      end
    end
  end

  describe '#section_past_due_date?' do
    context 'with SectionDueDates disabled' do
      before :each do
        @due_assignment = create(:assignment,
                                 section_due_dates_type: false,
                                 due_date: 1.days.ago)
        @not_due_assignment = create(:assignment,
                                     section_due_dates_type: false,
                                     due_date: 1.days.from_now)
      end

      context 'when no grouping is specified' do
        it 'returns based on due date of the assignment' do
          expect(@due_assignment.section_past_due_date?(nil)).to be true
          expect(@not_due_assignment.section_past_due_date?(nil)).to be false
        end
      end

      context 'when a grouping is specified' do
        it 'returns based on due date of the assignment' do
          grouping = create(:grouping)
          expect(@due_assignment.section_past_due_date?(grouping)).to be true
          expect(@not_due_assignment.section_past_due_date?(grouping))
            .to be false
        end
      end
    end

    context 'with SectionDueDates enabled' do
      before :each do
        @assignment = create(:assignment, section_due_dates_type: true)
      end

      context 'when no grouping is specified' do
        it 'returns based on due date of the assignment' do
          pending 'waiting on resolution for pending past_due_date example'
          @assignment.update_attributes(due_date: 1.days.ago)
          expect(@assignment.section_past_due_date?(nil)).to be true
          @assignment.update_attributes(due_date: 1.days.from_now)
          expect(@assignment.section_past_due_date?(nil)).to be false
        end
      end

      context 'when a grouping is specified' do
        before :each do
          @grouping = create(:grouping, assignment: @assignment)
          @section = create(:section)
          student = create(:student, section: @section)
          create(:inviter_student_membership,
                 user: student,
                 grouping: @grouping)
        end

        context 'that does not have an associated SectionDueDate' do
          it 'returns based on due date of the assignment' do
            @assignment.update_attributes(due_date: 1.days.ago)
            expect(@assignment.section_past_due_date?(@grouping)).to be true
            @assignment.update_attributes(due_date: 1.days.from_now)
            expect(@assignment.section_past_due_date?(@grouping)).to be false
          end
        end

        context 'that has an associated SectionDueDate' do
          before :each do
            @section_due_date = SectionDueDate.create(section: @section,
                                                      assignment: @assignment)
          end
          it 'returns based on the SectionDueDate of the grouping' do
            @section_due_date.update_attributes(due_date: 1.days.from_now)
            @assignment.update_attributes(due_date: 1.days.ago)
            expect(@assignment.section_past_due_date?(@grouping)).to be false

            @section_due_date.update_attributes(due_date: 1.days.ago)
            @assignment.update_attributes(due_date: 1.days.from_now)
            expect(@assignment.section_past_due_date?(@grouping)).to be true
          end
        end
      end
    end
  end

  describe '#what_past_due_date' do
    context 'with SectionDueDates disabled' do
      before :each do
        @assignment = create(:assignment, section_due_dates_type: false)
      end

      context 'when the assignment is past due' do
        it 'returns one name for the assignment' do
          @assignment.update_attributes(due_date: 1.days.ago)

          expect(@assignment.what_past_due_date).to eq ['Due Date']
        end
      end

      context 'when the assignment is not past due' do
        it 'returns an empty array' do
          @assignment.update_attributes(due_date: 1.days.from_now)

          expect(@assignment.what_past_due_date).to eq []
        end
      end
    end

    context 'with SectionDueDates enabled' do
      before :each do
        @assignment = create(:assignment, section_due_dates_type: true)
      end

      describe 'one SectionDueDate' do
        before :each do
          @section = create(:section)
          @section_due_date =
            SectionDueDate.create(section: @section, assignment: @assignment)
        end

        context 'that is past due' do
          it 'returns an array with the name of the section' do
            @section_due_date.update_attributes(due_date: 1.days.ago)

            expect(@assignment.what_past_due_date).to eq [@section.name]
          end
        end

        context 'that is not past due' do
          it 'returns an empty array' do
            @section_due_date.update_attributes(due_date: 1.days.from_now)

            expect(@assignment.what_past_due_date).to eq []
          end
        end
      end

      describe 'two SectionDueDates' do
        before :each do
          @sections = (1..2).map { create(:section) }
          @section_due_dates = @sections.map do |section|
            SectionDueDate.create(section: section, assignment: @assignment)
          end
          @section_names = @sections.map { |section| section.name }
        end

        context 'where both are past due' do
          it 'returns an array with both section names' do
            @section_due_dates.each do |section_due_date|
              section_due_date.update_attributes(due_date: 1.days.ago)
            end

            expect(@assignment.what_past_due_date).to match_array @section_names
          end
        end

        context 'where one is past due' do
          it 'returns an array with the name of that section' do
            @section_due_dates.first.update_attributes(due_date: 1.days.ago)
            @section_due_dates.last.update_attributes(due_date: 1.days.from_now)

            expect(@assignment.what_past_due_date).to eq [@section_names.first]
          end
        end

        context 'where neither is past due' do
          it 'returns an empty array' do
            @section_due_dates.each do |section_due_date|
              section_due_date.update_attributes(due_date: 1.days.from_now)
            end

            expect(@assignment.what_past_due_date).to eq []
          end
        end
      end
    end
  end

  context 'when before due with no submission rule' do
    before :each do
      @assignment = create(:assignment, due_date: 2.days.from_now)
    end

    it 'returns false for #past_collection_date?' do
      expect(@assignment.past_collection_date?).not_to be
    end
  end

  context 'when past due with no late submission rule' do
    context 'without sections' do
      before :each do
        @assignment = create(:assignment, due_date: 2.days.ago)
      end

      it 'returns true for past_collection_date?' do
        expect(@assignment.past_collection_date?).to be
      end
    end
  end

  describe '#update_results_stats' do
    before :each do
      allow(assignment).to receive(:total_mark).and_return(10)
    end

    context 'when no marks are found' do
      before :each do
        allow(Result).to receive(:student_marks_by_assignment).and_return([])
      end

      it 'returns false immediately' do
        expect(assignment.update_results_stats).to be_falsy
      end
    end

    context 'when even number of marks are found' do
      before :each do
        allow(Result).to receive(:student_marks_by_assignment).and_return(
          [0, 1, 4, 7])
        assignment.update_results_stats
      end

      it 'updates results_zeros' do
        expect(assignment.results_zeros).to eq 1
      end

      it 'updates results_fails' do
        expect(assignment.results_fails).to eq 3
      end

      it 'updates results_average' do
        expect(assignment.results_average).to eq 30
      end

      it 'updates results_median to the average of the two middle marks' do
        expect(assignment.results_median).to eq 25
      end

      context 'when total_mark is 0' do
        before :each do
          allow(assignment).to receive(:total_mark).and_return(0)
          assignment.update_results_stats
        end

        it 'updates results_average to 0' do
          expect(assignment.results_average).to eq 0
        end

        it 'updates results_median to 0' do
          expect(assignment.results_median).to eq 0
        end
      end
    end

    context 'when odd number of marks are found' do
      before :each do
        allow(Result).to receive(:student_marks_by_assignment).and_return(
          [0, 1, 4, 7, 9])
        assignment.update_results_stats
      end

      it 'updates results_median to the middle mark' do
        expect(assignment.results_median).to eq 40
      end
    end
  end
end
