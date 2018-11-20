describe AssignmentPolicy do
  include PolicyHelper

  describe '#run_tests?' do

    context 'when the user is an admin' do
      context 'if enable_test is false' do
        it do
          user = build(:admin)
          assignment = build(:assignment, enable_test: false)
          expect(apply_policy(assignment, user, :run_tests?)).to be false
        end
      end
      context 'if enable_test is true' do
        context 'if a test script is not uploaded' do
          it do
            user = build(:admin)
            assignment = create(:assignment, enable_test: true)
            expect(apply_policy(assignment, user, :run_tests?)).to be false
          end
        end
        context 'if a test script is uploaded for students only' do
          it do
            user = build(:admin)
            assignment = create(:assignment, enable_test: true)
            create(:test_script, assignment: assignment, run_by_students: true)
            expect(apply_policy(assignment, user, :run_tests?)).to be false
          end
        end
        context 'if a test script is uploaded' do
          it do
            user = build(:admin)
            assignment = create(:assignment, enable_test: true)
            create(:test_script, assignment: assignment, run_by_instructors: true)
            expect(apply_policy(assignment, user, :run_tests?)).to be true
          end
        end
      end
    end

    context 'when the user is a TA' do
      it do
        user = build(:ta)
        assignment = build(:assignment)
        expect(apply_policy(assignment, user, :run_tests?)).to be false
      end
    end

    context 'when the user is a student' do
      context 'if enable_test is false' do
        it do
          user = build(:student)
          assignment = build(:assignment, enable_test: false)
          expect(apply_policy(assignment, user, :run_tests?)).to be false
        end
      end
      context 'if enable_test is true' do
        context 'if enable_student_tests is false' do
          it do
            user = build(:student)
            assignment = build(:assignment, enable_test: true, enable_student_tests: false)
            expect(apply_policy(assignment, user, :run_tests?)).to be false
          end
        end
        context 'if enable_student_tests is true' do
          context 'if a test script is not uploaded' do
            it do
              user = build(:student)
              assignment = create(:assignment, enable_test: true, enable_student_tests: true,
                                  token_start_date: Time.current)
              expect(apply_policy(assignment, user, :run_tests?)).to be false
            end
          end
          context 'if a test script is uploaded for instructors only' do
            it do
              user = build(:student)
              assignment = create(:assignment, enable_test: true, enable_student_tests: true,
                                  token_start_date: Time.current)
              create(:test_script, assignment: assignment, run_by_instructors: true)
              expect(apply_policy(assignment, user, :run_tests?)).to be false
            end
          end
          context 'if a test script is uploaded' do
            context 'if tokens are not released yet' do
              it do
                user = build(:student)
                assignment = create(:assignment, enable_test: true, enable_student_tests: true,
                                    token_start_date: Time.current + 1.minute)
                create(:test_script, assignment: assignment, run_by_students: true)
                expect(apply_policy(assignment, user, :run_tests?)).to be false
              end
            end
            context 'if tokens are released' do
              context 'if the due date has passed' do
                it do
                  user = build(:student)
                  assignment = create(:assignment, enable_test: true, enable_student_tests: true,
                                      token_start_date: Time.current, due_date: Time.current - 1.minute)
                  create(:test_script, assignment: assignment, run_by_students: true)
                  expect(apply_policy(assignment, user, :run_tests?)).to be false
                end
              end
              context 'if the due date has not passed' do
                it do
                  user = build(:student)
                  assignment = create(:assignment, enable_test: true, enable_student_tests: true,
                                      token_start_date: Time.current)
                  create(:test_script, assignment: assignment, run_by_students: true)
                  expect(apply_policy(assignment, user, :run_tests?)).to be true
                end
              end
            end
          end
        end
      end
    end
  end
end
