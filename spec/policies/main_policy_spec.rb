describe MainPolicy do
  let(:context) { { user: user } }

  describe_rule :login_as? do
    succeed 'user is admin' do
      let(:user) { create :admin }
    end
    succeed 'real user is admin logged in as ta' do
      let(:context) { { user: create(:ta), real_user: create(:admin) } }
    end
    succeed 'real user is admin logged in as student' do
      let(:context) { { user: create(:student), real_user: create(:admin) } }
    end
    failed 'real user is not admin' do
      let(:context) { { user: create(:student), real_user: create(:student) } }
    end
  end

  describe_rule :manage? do
    succeed 'user is admin' do
      let(:user) { create :admin }
    end
    succeed 'user is ta' do
      let(:user) { create :ta }
    end
    succeed 'user is student' do
      let(:user) { create :student }
    end
    failed 'user is not a user' do
      let(:user) { 'not a user' }
    end
  end
end
