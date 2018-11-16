describe SubmissionPolicy do
  let(:policy) { described_class.new(submission, user: user) }

  # stub a passing AssociationPolicy (the order of allow calls matters)
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

      context 'if AssignmentPolicy#run_tests? returns false' do
        let(:submission) { build_stubbed(:submission) }
        before(:each) { stub_assignment_policy_false(policy, submission.grouping.assignment) }
        it { is_expected.to eq false }
      end

      context 'if AssignmentPolicy#run_tests? returns true' do
        let(:submission) { create(:submission) }
        before(:each) { stub_assignment_policy_true(policy, submission.grouping.assignment) }

        context 'if marks are released' do
          let(:result) { submission.current_result }
          before(:each) do
            # a submission after_create callback created the result, which has to be modified here
            result.marking_state = Result::MARKING_STATES[:complete]
            result.released_to_students = true
            result.save!
          end
          it { is_expected.to eq false }
        end

        context 'if marks are not released' do
          it { is_expected.to eq true }
        end
      end

    end

    context 'when the user is a TA' do
      let(:user) { build(:ta) }
      let(:submission) { build_stubbed(:submission) }
      it { is_expected.to eq false }
    end

    context 'when the user is a student' do
      let(:user) { build(:student) }
      let(:submission) { build_stubbed(:submission) }
      it { is_expected.to eq false }
    end
  end
end
