describe GroupingPolicy do
  let(:policy) { described_class.new(grouping, user: user) }

  # stub a passing AssociationPolicy
  def stub_assignment_policy_true(policy, assignment)
    allow(policy).to receive(:check?).and_call_original
    allow(policy).to receive(:check?).with(:run_tests?, assignment).and_return(true)
  end

  # stub a failing AssociationPolicy
  def stub_assignment_policy_false(policy, assignment)
    allow(policy).to receive(:check?).and_call_original
    allow(policy).to receive(:check?).with(:run_tests?, assignment).and_return(false)
  end

  describe '#run_tests?' do
    subject { policy.apply(:run_tests?) }

    context 'when the user is an admin' do
      let(:user) { build(:admin) }
      let(:grouping) { build_stubbed(:grouping) }

      context 'if AssignmentPolicy#run_tests? returns false' do
        before(:each) { stub_assignment_policy_false(policy, grouping.assignment) }
        it { is_expected.to eq false }
      end

      context 'if AssignmentPolicy#run_tests? returns true' do
        before(:each) { stub_assignment_policy_true(policy, grouping.assignment) }
        it { is_expected.to eq true }
      end

    end

    context 'when the user is a TA' do
      let(:user) { build(:ta) }
      let(:grouping) { build_stubbed(:grouping) }
      it { is_expected.to eq false }
    end

    context 'when the user is a student' do
      let(:user) { build(:student) }

      context 'if AssignmentPolicy#run_tests? returns false' do
        let(:grouping) { build_stubbed(:grouping) }
        before(:each) { stub_assignment_policy_false(policy, grouping.assignment) }
        it { is_expected.to eq false }
      end

      context 'if AssignmentPolicy#run_tests? returns true' do
        let(:assignment) { create(:assignment, unlimited_tokens: false) }
        let(:grouping) { create(:grouping, assignment: assignment, test_tokens: 0) }
        before(:each) { stub_assignment_policy_true(policy, grouping.assignment) }

        context 'if the student is not a member of the group' do
          let(:other_student) { create(:student) }
          let(:membership) { create(:accepted_student_membership, user: other_student, grouping: grouping) }
          it { is_expected.to eq false }
        end

        context 'if the student is a member of the group' do
          let(:membership) { create(:accepted_student_membership, user: user, grouping: grouping) }
          let(:test_run) { create(:test_run, user: user, grouping: grouping) }

          context 'if a test run is in progress' do
            it { is_expected.to eq false }
          end

          context 'if a test run is not in progress' do
            let(:test_script_result) { create(:test_script_result, test_run: test_run) }

            context 'if the student has tokens available' do
              let(:grouping) { create(:grouping, assignment: assignment, test_tokens: 1) }
              it { is_expected.to eq true }
            end

            context 'if the student has no tokens available' do

              context 'if the assignment has no unlimited tokens' do
                it { is_expected.to eq false }
              end

              context 'if the assignment has unlimited tokens' do
                let(:assignment) { create(:assignment, unlimited_tokens: true) }
                it { is_expected.to eq true }
              end
            end
          end
        end
      end
    end
  end
end
