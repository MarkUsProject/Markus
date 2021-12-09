describe Api::CoursePolicy do
  let(:user) { role.end_user }
  let(:context) { { role: role, real_user: user } }

  describe_rule :index? do
    failed 'user is a test server' do
      let(:user) { create :autotest_user }
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
      let(:user) { create :end_user }
      let(:role) { nil }
      let(:course1) { create :course }
      let(:course2) { create :course }
      let(:course3) { create :course }
      succeed 'and at least one is an admin role' do
        before do
          create :admin, end_user: user, course: course1
          create :ta, end_user: user, course: course2
          create :student, end_user: user, course: course3
        end
      end
      failed 'and none are admin roles' do
        before do
          create :ta, end_user: user, course: course1
          create :ta, end_user: user, course: course2
          create :student, end_user: user, course: course3
        end
      end
    end
  end
end
