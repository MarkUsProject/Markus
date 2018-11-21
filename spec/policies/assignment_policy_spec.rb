describe AssignmentPolicy do
  include PolicyHelper

  describe '#run_tests?' do

    context 'when the user is an admin' do
      context 'if enable_test is false' do
        it do
          user = build(:admin)
          assignment = build(:assignment, enable_test: false)
          expect(policy(assignment, user)).not_to pass :run_tests?, because_of: :enabled?
        end
      end
      context 'if enable_test is true' do
        context 'if a test script is not uploaded' do
          it do
            user = build(:admin)
            assignment = create(:assignment, enable_test: true)
            expect(policy(assignment, user)).not_to pass :run_tests?, because_of: :test_scripts_uploaded?
          end
        end
        context 'if a test script is uploaded for students only' do
          it do
            user = build(:admin)
            assignment = create(:assignment, enable_test: true)
            create(:test_script, assignment: assignment, run_by_students: true)
            expect(policy(assignment, user)).not_to pass :run_tests?, because_of: :test_scripts_uploaded?
          end
        end
        context 'if a test script is uploaded' do
          it do
            user = build(:admin)
            assignment = create(:assignment_for_instructor_tests)
            expect(policy(assignment, user)).to pass :run_tests?
          end
        end
      end
    end

    context 'when the user is a TA' do
      it do
        user = build(:ta)
        assignment = build(:assignment)
        expect(policy(assignment, user)).not_to pass :run_tests?, because_of: :not_a_ta?
      end
    end

    context 'when the user is a student' do
      context 'if enable_test is false' do
        it do
          user = build(:student)
          assignment = build(:assignment, enable_test: false)
          expect(policy(assignment, user)).not_to pass :run_tests?, because_of: :enabled?
        end
      end
      context 'if enable_test is true' do
        context 'if enable_student_tests is false' do
          it do
            user = build(:student)
            assignment = build(:assignment, enable_test: true, enable_student_tests: false)
            expect(policy(assignment, user)).not_to pass :run_tests?, because_of: :enabled?
          end
        end
        context 'if enable_student_tests is true' do
          context 'if a test script is not uploaded' do
            it do
              user = build(:student)
              assignment = create(:assignment, enable_test: true, enable_student_tests: true,
                                  token_start_date: Time.current)
              expect(policy(assignment, user)).not_to pass :run_tests?, because_of: :test_scripts_uploaded?
            end
          end
          context 'if a test script is uploaded for instructors only' do
            it do
              user = build(:student)
              assignment = create(:assignment_for_instructor_tests, enable_student_tests: true,
                                  token_start_date: Time.current)
              expect(policy(assignment, user)).not_to pass :run_tests?, because_of: :test_scripts_uploaded?
            end
          end
          context 'if a test script is uploaded' do
            context 'if tokens are not released yet' do
              it do
                user = build(:student)
                assignment = create(:assignment_for_student_tests, token_start_date: Time.current + 1.minute)
                expect(policy(assignment, user)).not_to pass :run_tests?, because_of: :tokens_released?
              end
            end
            context 'if tokens are released' do
              context 'if the due date has passed' do
                it do
                  user = build(:student)
                  assignment = create(:assignment_for_student_tests, due_date: Time.current - 1.minute)
                  expect(policy(assignment, user)).not_to pass :run_tests?, because_of: :before_due_date?
                end
              end
              context 'if the due date has not passed' do
                it do
                  user = build(:student)
                  assignment = create(:assignment_for_student_tests)
                  expect(policy(assignment, user)).to pass :run_tests?
                end
              end
            end
          end
        end
      end
    end
  end
end
