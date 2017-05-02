describe Membership do

  it { should belong_to :user }
  it { should belong_to :grouping }
  it { should have_many :grace_period_deductions }

  it do
    should validate_presence_of(:user_id)
    .with_message('needs a user id')
  end

  it do
    should validate_presence_of(:grouping_id)
    .with_message('needs a grouping id')
  end

  context 'StudentMembership is inviter' do
    before { @membership = StudentMembership.create(membership_status: StudentMembership::STATUSES[:inviter]) }

    it 'be inviter' do
      assert @membership.inviter?
    end

  end

  context 'StudentMembership is not inviter' do
    before { @membership = StudentMembership.create(membership_status: StudentMembership::STATUSES[:accepted]) }

    it 'not be inviter' do
      assert !@membership.inviter?
    end

  end

end
