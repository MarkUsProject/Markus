describe AssignmentPolicy do
  let(:policy) { described_class.new(assignment, user: user) }

  describe '#run_tests?' do
    subject { policy.apply(:run_tests?) }

    context 'when the user is a TA' do
      let(:user) { build(:ta) }
      let(:assignment) { build(:assignment) }
      it { is_expected.to eq false }
    end

    context 'when the user is an admin' do
      let(:user) { build(:admin) }

      context 'if enable_test is false' do
        let(:assignment) { build(:assignment, enable_test: false) }
        it { is_expected.to eq false }
      end

      context 'if enable_test is true' do
        let(:assignment) { create(:assignment, enable_test: true) }

        context 'if a test script is uploaded' do
          let!(:test_script) { create(:test_script, assignment: assignment, run_by_instructors: true) }
          it { is_expected.to eq true }
        end

        context 'if a test script is not uploaded' do
          it { is_expected.to eq false }
        end

        context 'if a test script is uploaded for students only' do
          let!(:test_script) { create(:test_script, assignment: assignment, run_by_students: true) }
          it { is_expected.to eq false }
        end
      end
    end

    context 'when the user is a student' do
      let(:user) { build(:student) }

      context 'if enable_test is false' do
        let(:assignment) { build(:assignment, enable_test: false) }
        it { is_expected.to eq false }
      end

      context 'if enable_test is true' do
        context 'if enable_student_tests is false' do
          let(:assignment) { build(:assignment, enable_test: true, enable_student_tests: false) }
          it { is_expected.to eq false }
        end

        context 'if enable_student_tests is true' do
          let(:assignment) do
            create(:assignment, enable_test: true, enable_student_tests: true, token_start_date: Time.current)
          end

          context 'if a test script is not uploaded' do
            it { is_expected.to eq false }
          end

          context 'if a test script is uploaded for instructors only' do
            let!(:test_script) { create(:test_script, assignment: assignment, run_by_instructors: true) }
            it { is_expected.to eq false }
          end

          context 'if a test script is uploaded' do
            let!(:test_script) { create(:test_script, assignment: assignment, run_by_students: true) }

            context 'if tokens are not released yet' do
              let(:assignment) do
                create(:assignment, enable_test: true, enable_student_tests: true,
                                    token_start_date: Time.current + 1.minute)
              end
              it { is_expected.to eq false }
            end

            context 'if tokens are released' do
              context 'if the due date has passed' do
                let(:assignment) do
                  create(:assignment, enable_test: true, enable_student_tests: true, token_start_date: Time.current,
                                      due_date: Time.current - 1.minute)
                end
                it { is_expected.to eq false }
              end

              context 'if the due date has not passed' do
                it { is_expected.to eq true }
              end
            end
          end
        end
      end
    end
  end
end
