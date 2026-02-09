describe InstructorPolicy do
  let(:role) { build(:instructor) }
  let(:context) { { role: role, real_user: role.user } }

  describe_rule :run_tests? do
    succeed 'with no additional context'
    context 'authorized with an assignment' do
      let(:context) { { role: role, assignment: assignment, real_user: role.user } }

      failed 'without tests enabled' do
        let(:assignment) { create(:assignment, assignment_properties_attributes: { enable_test: false }) }
      end
      context 'with tests enabled' do
        let(:assignment) { create(:assignment, assignment_properties_attributes: { enable_test: true }) }

        succeed 'when remote_autotest_settings exist' do
          before { assignment.update! remote_autotest_settings_id: 1 }
        end
        failed 'without test groups'
      end
    end

    context 'authorized with a submission' do
      let(:context) { { role: role, submission: result.submission, real_user: role.user } }

      failed 'with a released result' do
        let!(:result) { create(:released_result) }
      end
      succeed 'with a non-release result' do
        let!(:result) { create(:complete_result) }
      end
    end
  end

  describe_rule :manage_submissions? do
    succeed
  end

  describe_rule :manage_assessments? do
    succeed
  end

  describe_rule :destroy? do
    let(:context) { { role: role, real_user: role.user, user: role.user } }
    failed 'user is an end user' do
      let(:role) { create(:instructor) }
    end
    succeed 'user is an admin' do
      let(:role) { create(:admin_role) }
    end
  end

  describe_rule :manage_role_status? do
    let(:context) { { role: role, real_user: role.user, user: role.user } }
    failed 'user is an end user' do
      let(:role) { create(:instructor) }
    end
    succeed 'user is an admin' do
      let(:role) { create(:admin_role) }
    end
  end
end
