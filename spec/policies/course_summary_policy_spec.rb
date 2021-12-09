describe CourseSummaryPolicy do
  let(:context) { { role: role, real_user: role.end_user } }
  context 'role is an admin' do
    let(:role) { create :admin }
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
  context 'role is a ta' do
    let(:role) { create :ta }
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
  context 'role is a student' do
    let(:role) { create :student }
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
