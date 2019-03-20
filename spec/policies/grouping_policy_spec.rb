describe GroupingPolicy do
  include PolicyHelper

  describe '#run_tests?' do
    subject { described_class.new(grouping, user: user) }

    context 'when the user is an admin' do
      let(:user) { build(:admin) }

      context 'if the assignment policy fails' do
        let(:grouping) { build_stubbed(:grouping) }
        it { is_expected.not_to pass :run_tests?, because_of: { AssignmentPolicy => :run_tests? } }
      end

      context 'if the assignment policy passes' do
        let(:assignment) { create(:assignment_for_tests) }
        let(:grouping) { build_stubbed(:grouping, assignment: assignment) }
        it { is_expected.to pass :run_tests? }
      end
    end

    context 'when the user is a TA' do
      let(:user) { build(:ta) }
      let(:grouping) { build_stubbed(:grouping) }
      it { is_expected.not_to pass :run_tests?, because_of: { AssignmentPolicy => :run_tests? } }
    end

    context 'when the user is a student' do
      let(:user) { build(:student) }

      context 'if the assignment policy fails' do
        let(:grouping) { build_stubbed(:grouping) }
        it { is_expected.not_to pass :run_tests?, because_of: { AssignmentPolicy => :run_tests? } }
      end

      context 'if the assignment policy passes' do
        let(:assignment) { create(:assignment_for_student_tests, unlimited_tokens: false) }
        let(:grouping) { create(:grouping, assignment: assignment, test_tokens: 0) }

        context 'if the student is not a member of the group' do
          let(:other_student) { create(:student) }
          let!(:membership) { create(:accepted_student_membership, user: other_student, grouping: grouping) } # non-lazy
          it { is_expected.not_to pass :run_tests?, because_of: :member? }
        end

        context 'if the student is a member of the group' do
          let!(:membership) { create(:accepted_student_membership, user: user, grouping: grouping) } # non-lazy

          context 'if a test run is in progress' do
            let!(:test_run) { create(:test_run, user: user, grouping: grouping) } # non-lazy
            it { is_expected.not_to pass :run_tests?, because_of: :not_in_progress? }
          end

          context 'if a test run is not in progress' do
            let(:test_run) { create(:test_run, user: user, grouping: grouping) }
            let!(:test_group_result) { create(:test_group_result, test_run: test_run) } # non-lazy

            context 'if the student has tokens available' do
              let(:grouping) { create(:grouping, assignment: assignment, test_tokens: 1) }
              it { is_expected.to pass :run_tests? }
            end

            context 'if the student has no tokens available' do
              context 'if the assignment has no unlimited tokens' do
                it { is_expected.not_to pass :run_tests?, because_of: :tokens_available? }
              end

              context 'if the assignment has unlimited tokens' do
                let(:assignment) { create(:assignment_for_student_tests, unlimited_tokens: true) }
                it { is_expected.to pass :run_tests? }
              end
            end
          end
        end
      end
    end
  end
end
