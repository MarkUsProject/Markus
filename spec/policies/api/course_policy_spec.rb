describe Api::CoursePolicy do
  let(:user) { role.human }
  let(:context) { { role: role, user: user } }

  describe_rule :index? do
    failed 'user is a test server' do
      let(:user) { create :test_server }
      let(:role) { nil }
    end
    succeed 'role is an admin' do
      let(:role) { create :admin }
    end
    failed 'role is a ta' do
      let(:role) { create :ta }
    end
    failed 'role is a student' do
      let(:role) { create :student }
    end
    context 'user has multiple roles' do
      let(:user) { create :human }
      let(:role) { nil }
      succeed 'and at least one is an admin role' do
        before do
          create :admin, human: user
          create :ta, human: user
          create :student, human: user
        end
      end
      failed 'and none are admin roles' do
        before do
          create :ta, human: user
          create :ta, human: user
          create :student, human: user
        end
      end
    end
  end
end
