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
