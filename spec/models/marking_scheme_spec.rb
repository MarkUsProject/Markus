describe MarkingScheme do
  subject { build(:marking_scheme) }
  it { is_expected.to have_many :marking_weights }
  it { is_expected.to belong_to :course }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:course_id) }

  describe 'students_weighted_grade_distribution_array' do
    let!(:assignment) { create(:assignment_with_criteria_and_results) }
    let!(:marking_scheme) { create(:marking_scheme, assessments: [assignment]) }
    let(:instructor) { create(:instructor) }

    context 'when the current user is an instructor' do
      it 'generates the correct weighted grade distribution array' do
        intervals = 20
        grade_distribution_array = marking_scheme.students_weighted_grade_distribution_array(instructor, intervals)

        expect(grade_distribution_array).to have_key :data
        expect(grade_distribution_array).to have_key :max
        expect(grade_distribution_array[:data].length).to eq intervals + 1
        expect(grade_distribution_array[:max]).to be_between(0, 100)
      end
    end
  end
end
