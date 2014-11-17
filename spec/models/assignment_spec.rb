require 'spec_helper'

describe Assignment do

  # Associations
  it { is_expected.to have_many(:rubric_criteria).dependent(:destroy).order(:position) }
  it { is_expected.to have_many(:flexible_criteria).dependent(:destroy).order(:position) }
  it { is_expected.to have_many(:assignment_files).dependent(:destroy) }
  it { is_expected.to accept_nested_attributes_for(:assignment_files).allow_destroy(true) }
  it { is_expected.to have_many(:test_files).dependent(:destroy) }
  it { is_expected.to accept_nested_attributes_for(:test_files).allow_destroy(true) }
  it { is_expected.to have_many(:criterion_ta_associations).dependent(:destroy) }
  it { is_expected.to have_one(:submission_rule).dependent(:destroy) }
  it { is_expected.to accept_nested_attributes_for(:submission_rule).allow_destroy(true) }
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
  it { is_expected.to accept_nested_attributes_for(:assignment_stat).allow_destroy(true) }

  # Attributes
  it { is_expected.to validate_presence_of(:short_identifier) }
  it { is_expected.to validate_presence_of(:description) }
  it { is_expected.to validate_presence_of(:repository_folder) }
  it { is_expected.to validate_presence_of(:due_date) }
  it { is_expected.to validate_presence_of(:marking_scheme_type) }
  it { is_expected.to validate_presence_of(:group_min) }
  it { is_expected.to validate_presence_of(:group_max) }
  it { is_expected.to validate_presence_of(:notes_count) }

  it { is_expected.to validate_numericality_of(:group_min).is_greater_than(0) }
  it { is_expected.to validate_numericality_of(:group_max).is_greater_than(0) }
  it { is_expected.to validate_numericality_of(:tokens_per_day).is_greater_than_or_equal_to(0) }

  describe 'validation' do
    subject { create(:assignment) }

    it { is_expected.to validate_uniqueness_of(:short_identifier) }

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
        expect(@assignment.tas).to eq([])
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
          expect(@assignment.tas).to eq([@ta])
        end
      end

      describe 'more than one TA' do
        before :each do
          @other_ta = create(:ta)
          @ta_membership =
            create(:ta_membership, user: @other_ta, grouping: @grouping)
        end

        it 'returns all TAs' do
          expect(@assignment.tas).to eq([@ta, @other_ta])
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
        expect(assignment.group_assignment?).to be
      end
    end

    context 'when invalid_override is not allowed ' do
      context 'and group_max is greater than 1' do
        let(:assignment) do
          build(:assignment, invalid_override: false, group_max: 2)
        end

        it 'returns true' do
          expect(assignment.group_assignment?).to be
        end
      end

      context 'and group_max is 1' do
        let(:assignment) do
          build(:assignment, invalid_override: false, group_max: 1)
        end

        it 'returns false' do
          expect(assignment.group_assignment?).not_to be
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
        expect(@assignment.valid_groupings).to eq([])
      end

      it '#invalid_groupings returns all groupings' do
        expect(@assignment.invalid_groupings).to eq(@groupings)
      end
    end

    context 'when one group is valid' do
      context 'due to admin_approval' do
        before :each do
          @groupings.first.update_attribute(:admin_approved, true)
        end

        it '#valid_groupings returns the valid group' do
          expect(@assignment.valid_groupings).to eq([@groupings.first])
        end

        it '#invalid_groupings returns other, invalid groups' do
          expect(@assignment.invalid_groupings).to eq(@groupings.drop(1))
        end
      end

      context 'due to meeting min size requirement' do
        before :each do
          create(:accepted_student_membership,
                 grouping: @groupings.first,
                 user: create(:student))
        end

        it '#valid_groupings returns the valid group' do
          expect(@assignment.valid_groupings).to eq([@groupings.first])
        end

        it '#invalid_groupings returns other, invalid groups' do
          expect(@assignment.invalid_groupings).to eq(@groupings.drop(1))
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
        expect(@assignment.valid_groupings).to eq(@groupings)
      end

      it '#invalid_groupings returns an empty array' do
        expect(@assignment.invalid_groupings).to eq([])
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
        expect(@assignment.grouped_students).to eq([])
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
          expect(@assignment.grouped_students).to eq([@student])
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
          expect(@assignment.grouped_students).to eq([@student, @other_student])
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
        expect(@assignment.ungrouped_students).to eq(@students)
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
        expect(@assignment.ungrouped_students).to eq([])
      end
    end
  end

  describe '#past_remark_due_date?' do
    context 'before the remark due date' do
      let(:assignment) { build(:assignment, remark_due_date: 1.days.from_now) }

      it 'returns false' do
        expect(assignment.past_remark_due_date?).not_to be
      end
    end

    context 'after the remark due date' do
      let(:assignment) { build(:assignment, remark_due_date: 1.days.ago) }

      it 'returns true' do
        expect(assignment.past_remark_due_date?).to be
      end
    end
  end

  describe '#groups_submitted' do
    before :each do
      @assignment = create(:assignment)
    end

    context 'when no groups have made a submission' do
      it 'returns an empty array' do
        expect(@assignment.groups_submitted).to eq([])
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
          expect(@assignment.groups_submitted).to eq([@grouping])
        end
      end

      describe 'more than once' do
        before :each do
          create(:version_used_submission, grouping: @grouping)
          create(:version_used_submission, grouping: @grouping)
        end

        it 'returns one instance of the group' do
          expect(@assignment.groups_submitted).to eq([@grouping])
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
        expect(@assignment.groups_submitted).to eq(@groupings)
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
        expect(@assignment.graded_submission_results.size).to eq(0)
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
          expect(@assignment.graded_submission_results).to eq([@result])
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
            .to eq([@result, @other_result])
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
        expect(Group.all).to eq([])
        expect(Grouping.all).to eq([])
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
          expect(Grouping.first.group).to eq(@existing_group)
        end
      end
    end
  end

  context 'when before due with no submission rule' do
    before :each do
      @assignment = create(:assignment, due_date: 2.days.from_now)
    end

    it 'returns false for #past_due_date?' do
      expect(@assignment.past_due_date?).not_to be
    end

    it 'returns false for #past_collection_date?' do
      expect(@assignment.past_collection_date?).not_to be
    end

    it 'returns empty array #what_past_due_date' do
      expect(@assignment.what_past_due_date).to eq([])
    end
  end

  context 'when past due with no late submission rule' do
    context 'without sections' do
      before :each do
        @assignment = create(:assignment, due_date: 2.days.ago)
      end

      it 'returns only one due date' do
        expect(@assignment.what_past_due_date).to eq(['Due Date'])
      end

      it 'returns true for past_due_date?' do
        expect(@assignment.past_due_date?).to be
      end

      it 'returns true for past_collection_date?' do
        expect(@assignment.past_collection_date?).to be
      end

      it 'returns the latest_due_date' do
        expect(@assignment.latest_due_date.day).to eq(2.days.ago.day)
      end
    end

    context 'with sections' do
      before :each do
        @assignment = create(:assignment, due_date: 2.days.ago, section_due_dates_type: true)

        @section = Section.create(name: 'section_name')
        SectionDueDate.create(section: @section,
                              assignment: @assignment,
                              due_date: 1.days.ago)

        student = create(:student, section: @section)
        @grouping = create(:grouping, assignment: @assignment)
        create(:student_membership, grouping: @grouping,
                                    user: student,
                                    membership_status: StudentMembership::STATUSES[:inviter])
      end

      describe 'one section' do
        it 'returns the due date for the section' do
          expect(@assignment.section_due_date(@section).day).to eq(1.days.ago.day)
        end

        it 'returns true for section_past_due_date?' do
          expect(@assignment.section_past_due_date?(@grouping)).to be
        end

        it 'returns an array with the past section name' do
          expect(@assignment.what_past_due_date).to eq(%w(section_name))
        end
      end

      describe 'multiple sections' do
        before :each do
          @section2 = Section.create(name: 'section_name2')
          SectionDueDate.create(section: @section2,
                                assignment: @assignment,
                                due_date: 1.day.ago)
          student2 = create(:student, section: @section2)
          @grouping2 = create(:grouping, assignment: @assignment)
          create(:student_membership, grouping: @grouping2,
                                      user: student2,
                                      membership_status: StudentMembership::STATUSES[:inviter])
        end

        it 'returns an array with the past section names' do
          expect(@assignment.what_past_due_date).to eq(%w(section_name section_name2))
        end
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
