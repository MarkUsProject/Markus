describe Membership do

  it { should belong_to :user }
  it { should belong_to :grouping }
  it { should have_many :grace_period_deductions }

  it { should validate_presence_of(:user_id).with_message('needs a user id') }
  it { should validate_presence_of(:grouping_id).with_message('needs a grouping id') }

end
