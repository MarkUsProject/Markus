describe Period do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:hours) }
    it { is_expected.to have_db_column(:interval) }
    it { is_expected.to belong_to(:submission_rule) }

    it { is_expected.to allow_value(0).for(:hours) }
    it { is_expected.to allow_value(1).for(:hours) }
    it { is_expected.to allow_value(2).for(:hours) }
    it { is_expected.to allow_value(100).for(:hours) }
    it { is_expected.not_to allow_value(-1).for(:hours) }
    it { is_expected.not_to allow_value(-100).for(:hours) }
    it { is_expected.not_to allow_value(nil).for(:hours) }
  end

  context 'A penalty decay period' do
    before {@period = Period.create(submission_rule_type: 'PenaltyDecayPeriodSubmissionRule')}

    it 'validate presence of deduction' do
      #no deduction is set
      expect(@period.valid?).to be false
    end

    it 'validate numericality of deduction' do
      @period.deduction = 'string'
      expect(@period.valid?).to be false
    end

    it 'validate presence of interval' do
      #no interval is set
      expect(@period.valid?).to be false
    end

    it 'validate numericality of interval' do
      @period.interval = 'string'
      expect(@period.valid?).to be false
    end
  end

  context 'A penalty period' do
    before {@period = Period.create(submission_rule_type: 'PenaltyPeriodSubmissionRule')}

    it 'validate presence of deduction' do
      #no deduction is set
      expect(@period.valid?).to be false
    end

    it 'validate numericality of deduction' do
      @period.deduction = 'string'
      expect(@period.valid?).to be false
    end
  end
end
