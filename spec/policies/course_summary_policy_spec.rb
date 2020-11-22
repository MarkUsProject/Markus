describe CourseSummaryPolicy do
  let(:context) { { user: user } }
  context 'user is an admin' do
    let(:user) { create :admin }
    describe_rule :manage? do
      succeed
    end
    describe_rule :populate? do
      succeed
    end
    describe_rule :index? do
      succeed
    end
  end
  context 'user is a ta' do
    let(:user) { create :ta }
    describe_rule :manage? do
      failed
    end
    describe_rule :populate? do
      succeed
    end
    describe_rule :index? do
      succeed
    end
  end
  context 'user is a student' do
    let(:user) { create :student }
    describe_rule :manage? do
      failed
    end
    describe_rule :populate? do
      succeed
    end
    describe_rule :index? do
      succeed
    end
  end
end
