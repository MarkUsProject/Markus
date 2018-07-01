describe Membership do

  it { should belong_to :user }
  it { should belong_to :grouping }
  it { should have_many :grace_period_deductions }

end
