describe StudentPolicy do
  include PolicyHelper
  subject { described_class.new(user, user: user, **context) }
  let(:user) { create :student }
  let(:context) { {} }

  describe '#run_tests?' do
    context 'with no additional context' do
      it { is_expected.not_to pass :run_tests? }
    end
    context 'authorized with an assignment' do
      let(:context) { { assignment: assignment } }
      let!(:assignment) { create :assignment, assignment_properties_attributes: assignment_attrs }
      context 'without student tests enabled' do
        let(:assignment_attrs) { { token_start_date: 1.hour.ago, enable_student_tests: false } }
        it { is_expected.not_to pass :run_tests?, because_of: { AssignmentPolicy => :student_tests_enabled? } }
      end
      context 'when tokens have not been released yet' do
        let(:assignment_attrs) { { token_start_date: 1.hour.from_now, enable_student_tests: true } }
        it { is_expected.not_to pass :run_tests?, because_of: { AssignmentPolicy => :tokens_released? } }
      end
      context 'when student tests are enabled and tokens have been released' do
        context 'when there are tokens' do
          let(:assignment_attrs) { { token_start_date: 1.hour.ago, enable_student_tests: true, tokens_per_period: 1 } }
          it { is_expected.to pass :run_tests? }
        end
        context 'when there are unlimited tokens' do
          let(:assignment_attrs) { { token_start_date: 1.hour.ago, enable_student_tests: true, unlimited_tokens: true } }
          it { is_expected.to pass :run_tests? }
        end
        context 'when there are no tokens available' do
          let(:assignment_attrs) { { token_start_date: 1.hour.ago, enable_student_tests: true } }
          it { is_expected.not_to pass :run_tests?, because_of: { AssignmentPolicy => :student_tests_enabled? } }
        end
      end
    end
    context 'authorized with a grouping' do
      let(:context) { { grouping: grouping } }
      context 'when the user is a member' do
        let(:grouping) { create :grouping_with_inviter, inviter: user, test_tokens: 1 }
        it { is_expected.to pass :run_tests? }
        context 'when there is a test in progress' do
          it do
            allow(grouping).to receive(:student_test_run_in_progress?).and_return true
            is_expected.not_to pass :run_tests?, because_of: { GroupingPolicy => :not_in_progress? }
          end
        end
        context 'when there are no tokens available' do
          let(:grouping) { create :grouping_with_inviter, inviter: user, test_tokens: 0 }
          it { is_expected.not_to pass :run_tests?, because_of: { GroupingPolicy => :tokens_available? } }
        end
        context 'when the due date has passed' do
          let(:assignment) { create :assignment, due_date: 1.day.ago }
          let(:grouping) { create :grouping_with_inviter, assignment: assignment, inviter: user, test_tokens: 1 }
          it { is_expected.not_to pass :run_tests?, because_of: { GroupingPolicy => :before_due_date? } }
        end
      end
      context 'when the user is not a member' do
        let(:grouping) { create :grouping_with_inviter, test_tokens: 1 }
        it { is_expected.not_to pass :run_tests?, because_of: { GroupingPolicy => :member? } }
      end
    end
    context 'authorized with a submission' do
      let(:context) { { submission: result.submission } }
      context 'with a released result' do
        let!(:result) { create :released_result }
        it { is_expected.not_to pass :run_tests?, because_of: { SubmissionPolicy => :before_release? } }
      end
      context 'with a non-release result' do
        let!(:result) { create :complete_result }
        it { is_expected.to pass :run_tests? }
      end
    end
  end

  describe '#manage_submissions?' do
    it { is_expected.not_to pass :manage_submissions? }
  end

  describe '#manage_assessments?' do
    it { is_expected.not_to pass :manage_assessments? }
  end
end
