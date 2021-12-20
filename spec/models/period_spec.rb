describe Period do
  subject { create :period, submission_rule: rule }

  shared_examples 'has a course' do
    it 'should have a course' do
      expect(subject.course).to eq(rule.course)
    end
  end

  context 'A penalty decay period' do
    let(:rule) { create :penalty_decay_period_submission_rule }
    it { is_expected.to belong_to(:submission_rule) }
    it { is_expected.to validate_numericality_of(:hours).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:deduction).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:interval).is_greater_than(0) }
    include_examples 'has a course'
  end

  context 'A penalty period' do
    let(:rule) { create :penalty_period_submission_rule }
    it { is_expected.to belong_to(:submission_rule) }
    it { is_expected.to validate_numericality_of(:hours).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:deduction).is_greater_than_or_equal_to(0) }
    it { is_expected.not_to validate_numericality_of(:interval) }
    include_examples 'has a course'
  end

  context 'A grace penalty period' do
    let(:rule) { create :grace_period_submission_rule }
    it { is_expected.to belong_to(:submission_rule) }
    it { is_expected.to validate_numericality_of(:hours).is_greater_than(0) }
    it { is_expected.not_to validate_numericality_of(:deduction) }
    it { is_expected.not_to validate_numericality_of(:interval) }
    include_examples 'has a course'
  end

  context 'A no late penalty period' do
    let(:rule) { create :no_late_submission_rule }
    it { is_expected.to belong_to(:submission_rule) }
    it { is_expected.to validate_numericality_of(:hours).is_greater_than(0) }
    it { is_expected.not_to validate_numericality_of(:deduction) }
    it { is_expected.not_to validate_numericality_of(:interval) }
    include_examples 'has a course'
  end
end
