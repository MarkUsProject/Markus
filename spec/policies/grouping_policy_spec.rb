describe GroupingPolicy do
  include PolicyHelper

  describe '#run_tests?' do

    context 'when the user is an admin' do
      context 'if the assignment policy fails' do
        it do
          user = build(:admin)
          grouping = build_stubbed(:grouping)
          expect(policy(grouping, user)).not_to pass :run_tests?, because_of: { AssignmentPolicy => :run_tests? }
        end
      end
      context 'if the assignment policy passes' do
        it do
          user = build(:admin)
          assignment = create(:assignment_for_instructor_tests)
          grouping = build_stubbed(:grouping, assignment: assignment)
          expect(policy(grouping, user)).to pass :run_tests?
        end
      end
    end

    context 'when the user is a TA' do
      it do
        user = build(:ta)
        grouping = build_stubbed(:grouping)
        expect(policy(grouping, user)).not_to pass :run_tests?, because_of: { AssignmentPolicy => :run_tests? }
      end
    end

    context 'when the user is a student' do
      context 'if the assignment policy fails' do
        it do
          user = build(:student)
          grouping = build_stubbed(:grouping)
          expect(policy(grouping, user)).not_to pass :run_tests?, because_of: { AssignmentPolicy => :run_tests? }
        end
      end
      context 'if the assignment policy passes' do
        context 'if the student is not a member of the group' do
          it do
            user = build(:student)
            assignment = create(:assignment_for_student_tests, unlimited_tokens: false)
            grouping = create(:grouping, assignment: assignment, test_tokens: 0)
            other_student = create(:student)
            create(:accepted_student_membership, user: other_student, grouping: grouping)
            expect(policy(grouping, user)).not_to pass :run_tests?, because_of: :member?
          end
        end
        context 'if the student is a member of the group' do
          context 'if a test run is in progress' do
            it do
              user = build(:student)
              assignment = create(:assignment_for_student_tests, unlimited_tokens: false)
              grouping = create(:grouping, assignment: assignment, test_tokens: 0)
              create(:accepted_student_membership, user: user, grouping: grouping)
              create(:test_run, user: user, grouping: grouping)
              expect(policy(grouping, user)).not_to pass :run_tests?, because_of: :not_in_progress?
            end
          end
          context 'if a test run is not in progress' do
            context 'if the student has tokens available' do
              it do
                user = build(:student)
                assignment = create(:assignment_for_student_tests, unlimited_tokens: false)
                grouping = create(:grouping, assignment: assignment, test_tokens: 1)
                create(:accepted_student_membership, user: user, grouping: grouping)
                test_run = create(:test_run, user: user, grouping: grouping)
                create(:test_script_result, test_run: test_run)
                expect(policy(grouping, user)).to pass :run_tests?
              end
            end
            context 'if the student has no tokens available' do
              context 'if the assignment has no unlimited tokens' do
                it do
                  user = build(:student)
                  assignment = create(:assignment_for_student_tests, unlimited_tokens: false)
                  grouping = create(:grouping, assignment: assignment, test_tokens: 0)
                  create(:accepted_student_membership, user: user, grouping: grouping)
                  test_run = create(:test_run, user: user, grouping: grouping)
                  create(:test_script_result, test_run: test_run)
                  expect(policy(grouping, user)).not_to pass :run_tests?, because_of: :tokens_available?
                end
              end
              context 'if the assignment has unlimited tokens' do
                it do
                  user = build(:student)
                  assignment = create(:assignment_for_student_tests, unlimited_tokens: true)
                  grouping = create(:grouping, assignment: assignment, test_tokens: 0)
                  create(:accepted_student_membership, user: user, grouping: grouping)
                  test_run = create(:test_run, user: user, grouping: grouping)
                  create(:test_script_result, test_run: test_run)
                  expect(policy(grouping, user)).to pass :run_tests?
                end
              end
            end
          end
        end
      end
    end
  end
end
