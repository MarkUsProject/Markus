describe Period do
  describe 'validations' do
    subject { create :period }
    it { is_expected.to have_db_column(:interval) }
    it { is_expected.to belong_to(:submission_rule) }

    it { is_expected.to allow_value(0).for(:hours) }
    it { is_expected.to allow_value(1).for(:hours) }
    it { is_expected.to allow_value(2).for(:hours) }
    it { is_expected.to allow_value(100).for(:hours) }
    it { is_expected.not_to allow_value(-1).for(:hours) }
    it { is_expected.not_to allow_value(-100).for(:hours) }
    it { is_expected.not_to allow_value(nil).for(:hours) }
    it { is_expected.not_to allow_value('').for(:hours) }
  end

  context 'A penalty decay period' do
    let(:rule) { create :penalty_decay_period_submission_rule }
    let(:period) { create :period, submission_rule: rule }

    it 'validate presence of deduction' do
      period.deduction = nil
      expect(period.valid?).to be false
    end

    it 'validate numericality of deduction' do
      period.deduction = 'string'
      expect(period.valid?).to be false
    end

    it 'validate presence of interval' do
      period.interval = nil
      expect(period.valid?).to be false
    end

    it 'validate numericality of interval' do
      period.interval = 'string'
      expect(period.valid?).to be false
    end
  end

  context 'A penalty period' do
    let(:rule) { create :penalty_period_submission_rule }
    let(:period) { create :period, submission_rule: rule }

    it 'validate presence of deduction' do
      period.deduction = nil
      expect(period.valid?).to be false
    end

    it 'validate numericality of deduction' do
      period.deduction = 'string'
      expect(period.valid?).to be false
    end
  end
end
