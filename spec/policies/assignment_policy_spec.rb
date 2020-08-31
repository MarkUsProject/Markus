describe AssignmentPolicy do
  include PolicyHelper

  describe '#run_tests?' do
    subject { described_class.new(assignment, user: user) }

    shared_examples 'An authorized user running tests' do
      context 'user can view the test runs status and stop test' do
        let(:assignment) { build(:assignment) }
        it { is_expected.to pass :run_and_stop_test? }
      end
      context 'if enable_test is false' do
        let(:assignment) { build(:assignment) }
        it { is_expected.not_to pass :run_tests?, because_of: :enabled? }
      end

      context 'if enable_test is true' do
        let(:assignment) { build(:assignment, assignment_properties_attributes: { enable_test: true }) }

        context 'if a test group is not configured' do
          it { is_expected.not_to pass :run_tests?, because_of: :test_groups_exist? }
        end

        context 'if a test group is configured' do
          let(:assignment) { create(:assignment_for_tests) }
          it { is_expected.to pass :run_tests? }
        end
      end
    end

    context 'when the user is a grader and allowed to run tests' do
      let(:user) { create(:ta, run_tests: true) }
      include_examples 'An authorized user running tests'
    end

    context 'When the user is admin' do
      let!(:user) { build(:admin) }
      include_examples 'An authorized user running tests'
    end

    context 'When the user is TA and not allowed to run tests' do
      # By default all the grader permissions are set to false
      let(:user) { create(:ta) }
      let(:assignment) { create(:assignment_for_tests) }
      it { is_expected.not_to pass :run_tests?, because_of: :can_run_tests? }
      it { is_expected.not_to pass :run_and_stop_test? }
    end

    context 'when the user is a student' do
      let(:user) { create(:student) }

      context 'if enable_test is false' do
        let(:assignment) { build(:assignment) }
        it { is_expected.not_to pass :run_tests?, because_of: :enabled? }
      end

      context 'if enable_test is true' do
        context 'if enable_student_tests is false' do
          let(:assignment) do
            build(:assignment, assignment_properties_attributes: { enable_test: true, enable_student_tests: false })
          end
          it { is_expected.not_to pass :run_tests?, because_of: :enabled? }
        end

        context 'if enable_student_tests is true' do
          context 'if a test group is not configured' do
            let(:assignment) do
              create(:assignment, assignment_properties_attributes: { enable_test: true,
                                                                      enable_student_tests: true,
                                                                      token_start_date: Time.current })
            end
            it { is_expected.not_to pass :run_tests?, because_of: :test_groups_exist? }
          end

          context 'if a test group is configured' do
            context 'if tokens are not released yet' do
              let(:assignment) do
                create(:assignment_for_student_tests,
                       assignment_properties_attributes: { token_start_date: Time.current + 1.minute })
              end
              it { is_expected.not_to pass :run_tests?, because_of: :tokens_released? }
            end

            context 'if tokens are released' do
              let(:assignment) { create(:assignment_for_student_tests) }
              it { is_expected.to pass :run_tests? }
            end
          end
        end
      end
    end
  end

  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { create(:admin) }
    context 'Admin can view, manage, create, edit and update the assignments' do
      it { is_expected.to pass :manage? }
      it { is_expected.to pass :view_assessments? }
    end
  end

  describe 'When the user is grader' do
    subject { described_class.new(user: user) }
    let(:user) { create(:ta) }
    context 'Grader can view assessments' do
      it { is_expected.to pass :view_assessments? }
    end
    context 'When the grader is allowed to manage, create, edit and update the assignments' do
      let(:user) { create(:ta, manage_assessments: true) }
      it { is_expected.to pass :manage? }
    end
    context 'When the grader is not allowed to manage, create, edit and update the assignments' do
      it { is_expected.not_to pass :manage? }
    end
  end
end
