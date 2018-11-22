describe AssignmentPolicy do
  include PolicyHelper

  describe '#run_tests?' do
    subject { described_class.new(assignment, user: user) }

    context 'when the user is an admin' do
      let(:user) { build(:admin) }

      context 'if enable_test is false' do
        let(:assignment) { build(:assignment, enable_test: false) }
        it { is_expected.not_to pass :run_tests?, because_of: :enabled? }
      end

      context 'if enable_test is true' do
        let(:assignment) { build(:assignment, enable_test: true) }

        context 'if a test script is not uploaded' do
          it { is_expected.not_to pass :run_tests?, because_of: :test_scripts_uploaded? }
        end

        context 'if a test script is uploaded for students only' do
          let!(:test_script) { create(:test_script, assignment: assignment, run_by_students: true) } # non-lazy
          it { is_expected.not_to pass :run_tests?, because_of: :test_scripts_uploaded? }
        end

        context 'if a test script is uploaded' do
          let(:assignment) { create(:assignment_for_instructor_tests) }
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
        let(:assignment) { build(:assignment, enable_test: false) }
        it { is_expected.not_to pass :run_tests?, because_of: :enabled? }
      end

      context 'if enable_test is true' do
        context 'if enable_student_tests is false' do
          let(:assignment) { build(:assignment, enable_test: true, enable_student_tests: false) }
          it { is_expected.not_to pass :run_tests?, because_of: :enabled? }
        end

        context 'if enable_student_tests is true' do
          context 'if a test script is not uploaded' do
            let(:assignment) do
              create(:assignment, enable_test: true, enable_student_tests: true, token_start_date: Time.current)
            end
            it { is_expected.not_to pass :run_tests?, because_of: :test_scripts_uploaded? }
          end

          context 'if a test script is uploaded for instructors only' do
            let(:assignment) do
              create(:assignment_for_instructor_tests, enable_student_tests: true, token_start_date: Time.current)
            end
            it { is_expected.not_to pass :run_tests?, because_of: :test_scripts_uploaded? }
          end

          context 'if a test script is uploaded' do
            context 'if tokens are not released yet' do
              let(:assignment) { create(:assignment_for_student_tests, token_start_date: Time.current + 1.minute) }
              it { is_expected.not_to pass :run_tests?, because_of: :tokens_released? }
            end

            context 'if tokens are released' do
              context 'if the due date has passed' do
                let(:assignment) { create(:assignment_for_student_tests, due_date: Time.current - 1.minute) }
                it { is_expected.not_to pass :run_tests?, because_of: :before_due_date? }
              end

              context 'if the due date has not passed' do
                let(:assignment) { create(:assignment_for_student_tests) }
                it { is_expected.to pass :run_tests? }
              end
            end
          end
        end
      end
    end
  end
end
