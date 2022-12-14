describe Ta do
  subject { create :ta }
  it { is_expected.to have_one(:grader_permission).dependent(:destroy) }
  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:course_id) }
  describe '#percentage_grades_array' do
    let(:assignment) { create(:assignment_with_criteria_and_results) }
    let(:ta) { create(:ta) }

    context 'when the TA is not assigned any groupings' do
      it 'returns no grades' do
        expect(ta.percentage_grades_array(assignment)).to eq []
      end
    end

    context 'when the TA is assigned some groupings' do
      let!(:ta_associations) do
        [create(:ta_membership, role: ta, grouping: assignment.groupings.first),
         create(:ta_membership, role: ta, grouping: assignment.groupings.second)]
      end

      context 'when TAs are not assigned criteria' do
        it 'returns the grades for their assigned groupings based on total marks' do
          expected = ta.groupings.where(assessment_id: assignment.id).map do |g|
            g.current_result.get_total_mark / assignment.max_mark * 100
          end

          actual = ta.percentage_grades_array(assignment)
          expect(actual.length).to eq 2
          expect(actual.sort).to eq expected.sort
        end
      end

      context 'when TAs are assigned specific criteria' do
        let!(:criterion1) { assignment.criteria.where(type: 'FlexibleCriterion').first }
        let!(:criterion2) { assignment.criteria.where(type: 'FlexibleCriterion').second }
        let!(:ta_criterion_associations) do
          assignment.update(assign_graders_to_criteria: true)
          [create(:criterion_ta_association, ta: ta, criterion: criterion1),
           create(:criterion_ta_association, ta: ta, criterion: criterion2)]
        end

        it 'returns the grades for their assigned groupings based on assigned criterion marks' do
          out_of = criterion1.max_mark + criterion2.max_mark

          expected = ta.groupings.where(assessment_id: assignment.id).map do |g|
            result = g.current_result
            subtotal = (
              result.marks.find_by(criterion: criterion1).mark +
              result.marks.find_by(criterion: criterion2).mark
            )
            subtotal / out_of * 100
          end

          actual = ta.percentage_grades_array(assignment)
          expect(actual.length).to eq 2
          expect(actual.sort).to eq expected.sort
        end
      end
    end
  end

  context 'Associated grader permission validation' do
    subject { create :ta }
    it { is_expected.to validate_presence_of :grader_permission }
  end

  context 'Ta model' do
    let(:user) { create(:ta) }
    it 'should create a ta' do
      expect(create(:ta)).to be_valid
    end
    it 'should create associated permissions' do
      expect(GraderPermission.exists?(user.grader_permission.id)).to be true
    end
    it 'does not allow admin users to be tas' do
      expect(build(:ta, user: create(:admin_user))).not_to be_valid
    end
    it 'does not allow autotest users to be tas' do
      expect(build(:ta, user: create(:autotest_user))).not_to be_valid
    end
  end
end
