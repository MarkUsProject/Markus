describe UserPolicy do
  let(:context) { { user: user } }
  describe_rule :manage? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    failed 'user is a ta' do
      let(:user) { create(:ta) }
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end
  describe_rule :destroy? do
    failed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    failed 'user is a ta' do
      let(:user) { create(:ta) }
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end

  describe_rule :reset_api_key? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    failed 'user is a ta' do
      let(:user) { create(:ta) }
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end
end
