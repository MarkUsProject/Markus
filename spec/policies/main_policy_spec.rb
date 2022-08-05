describe MainPolicy do
  let(:context) { { real_user: user.user } }

  describe_rule :manage? do
    succeed 'user is instructor' do
      let(:user) { create :instructor }
    end
    succeed 'user is ta' do
      let(:user) { create :ta }
    end
    succeed 'user is student' do
      let(:user) { create :student }
    end
  end
end
