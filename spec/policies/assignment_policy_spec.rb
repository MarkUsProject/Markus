describe AssignmentPolicy do
  include PolicyHelper

  describe '#run_tests?' do
    subject { described_class.new(assignment, user: user) }

    context 'when the user is an admin' do
      let(:user) { build(:admin) }

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

    context 'when the user is a TA' do
      let(:user) { build(:ta) }
      let(:assignment) { build(:assignment) }
      it { is_expected.not_to pass :run_tests?, because_of: :not_a_ta? }
    end

    context 'when the user is a student' do
      let(:user) { build(:student) }

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
end
