describe TaPolicy do
  let(:context) { { role: role, real_user: role.user } }
  let(:record) { role }

  describe_rule :run_tests? do
    failed 'without run_tests permissions' do
      let(:role) { create :ta, run_tests: false }
    end
    succeed 'with run_tests permissions' do
      let(:role) { create :ta, run_tests: true }
      context 'authorized with an assignment' do
        let(:context) { { role: role, real_user: role.user, assignment: assignment } }
        failed 'without tests enabled' do
          let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: false } }
        end
        context 'with tests enabled' do
          let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: true } }
          succeed 'with test groups' do
            let!(:test_group) { create :test_group, assignment: assignment }
          end
          failed 'without test groups'
        end
      end
      context 'authorized with a submission' do
        let(:context) { { role: role, real_user: role.user, submission: result.submission } }
        failed 'with a released result' do
          let(:result) { create :released_result }
        end
        succeed 'with a non-release result' do
          let(:result) { create :complete_result }
        end
      end
    end
  end

  describe_rule :manage_submissions? do
    succeed 'with manage_submissions permissions' do
      let(:role) { create :ta, manage_submissions: true }
    end
    failed 'without manage_submissions permissions' do
      let(:role) { create :ta, manage_submissions: false }
    end
  end

  describe_rule :manage_assessments? do
    succeed 'with manage_assessments permissions' do
      let(:role) { create :ta, manage_assessments: true }
    end
    failed 'without manage_assessments permissions' do
      let(:role) { create :ta, manage_assessments: false }
    end
  end

  describe_rule :manage_user_status? do
    let(:context) { { role: role, real_user: role.user, user: role.user } }
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    failed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
    succeed 'user is an admin' do
      let(:role) { create :admin_role }
    end
  end
end
