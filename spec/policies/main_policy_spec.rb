describe MainPolicy do
  let(:context) { { real_user: user.human } }

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
  end
end
