describe Membership do
  it { is_expected.to belong_to :role }
  it { is_expected.to belong_to :grouping }
  it { is_expected.to have_many :grace_period_deductions }
  it { is_expected.to have_one(:course) }
end
