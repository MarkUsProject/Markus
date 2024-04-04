describe Api::CoursePolicy do
  let(:user) { role.user }
  let(:role) { nil }
  let(:context) { { role: role, real_user: user } }

  describe_rule :index? do
    succeed 'user is an admin user' do
      let(:user) { build(:admin_user) }
    end
    failed 'user is a test server' do
      let(:user) { create(:autotest_user) }
      let(:role) { nil }
    end
    context 'user is an end user' do
      succeed 'with no role' do
        let(:user) { build(:end_user) }
      end
      succeed 'role is an instructor' do
        let(:role) { create(:instructor) }
      end
      succeed 'role is a ta' do
        let(:role) { create(:ta) }
      end
      succeed 'role is a student' do
        let(:role) { create(:student) }
      end
      context 'user has multiple roles' do
        let(:user) { create(:end_user) }
        let(:role) { nil }
        let(:course1) { create(:course) }
        let(:course2) { create(:course) }
        let(:course3) { create(:course) }
        succeed 'and at least one is an instructor role' do
          before do
            create(:instructor, user: user, course: course1)
            create(:ta, user: user, course: course2)
            create(:student, user: user, course: course3)
          end
        end
        succeed 'and none are instructor roles' do
          before do
            create(:ta, user: user, course: course1)
            create(:ta, user: user, course: course2)
            create(:student, user: user, course: course3)
          end
        end
      end
    end
  end
end
