describe Period do
  subject { create(:period, submission_rule: rule) }

  shared_examples 'has a course' do
    it 'should have a course' do
      expect(subject.course).to eq(rule.course)
    end
  end

  context 'A penalty decay period' do
    let(:rule) { create(:penalty_decay_period_submission_rule) }

    it { is_expected.to belong_to(:submission_rule) }
    it { is_expected.to validate_numericality_of(:hours).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:deduction).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:interval).is_greater_than(0) }

    it_behaves_like 'has a course'
  end

  context 'A penalty period' do
    let(:rule) { create(:penalty_period_submission_rule) }

    it { is_expected.to belong_to(:submission_rule) }
    it { is_expected.to validate_numericality_of(:hours).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:deduction).is_greater_than_or_equal_to(0) }
    it { is_expected.not_to validate_numericality_of(:interval) }

    it_behaves_like 'has a course'
  end

  context 'A grace penalty period' do
    let(:rule) { create(:grace_period_submission_rule) }

    it { is_expected.to belong_to(:submission_rule) }
    it { is_expected.to validate_numericality_of(:hours).is_greater_than(0) }
    it { is_expected.not_to validate_numericality_of(:deduction) }
    it { is_expected.not_to validate_numericality_of(:interval) }

    it_behaves_like 'has a course'
  end

  context 'A no late penalty period' do
    let(:rule) { create(:no_late_submission_rule) }

    it { is_expected.to belong_to(:submission_rule) }
    it { is_expected.to validate_numericality_of(:hours).is_greater_than(0) }
    it { is_expected.not_to validate_numericality_of(:deduction) }
    it { is_expected.not_to validate_numericality_of(:interval) }

    it_behaves_like 'has a course'
  end

  context 'Multiple penalty decay periods' do
    let(:rule) { create(:penalty_period_submission_rule) }
    let!(:period) { create(:period, id: 2, submission_rule: rule) }
    let!(:period2) { create(:period, id: 3, deduction: 0.25, interval: 0.25, hours: 0.25, submission_rule: rule) }
    let!(:period3) { create(:period, id: 1, deduction: 1, interval: 1, hours: 10, submission_rule: rule) }

    it 'returns the periods in order' do
      expect(rule.reload.periods).to eq [period3, period, period2]
    end
  end
end
