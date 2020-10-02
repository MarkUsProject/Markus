describe AdminPolicy do
  include PolicyHelper
  subject { described_class.new(user, user: user, **context) }
  let(:user) { build(:admin) }
  let(:context) { {} }

  describe '#run_tests?' do
    context 'with no additional context' do
      it { is_expected.to pass :run_tests? }
    end
    context 'authorized with an assignment' do
      let(:context) { { assignment: assignment } }
      context 'without tests enabled' do
        let!(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: false } }
        it { is_expected.not_to pass :run_tests?, because_of: { AssignmentPolicy => :tests_enabled? } }
      end
      context 'with tests enabled' do
        let!(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: true } }
        context 'with test groups' do
          let!(:test_group) { create :test_group, assignment: assignment }
          it { is_expected.to pass :run_tests? }
        end
        context 'without test groups' do
          it { is_expected.not_to pass :run_tests?, because_of: { AssignmentPolicy => :test_groups_exist? } }
        end
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
    it { is_expected.to pass :manage_submissions? }
  end

  describe '#manage_assessments?' do
    it { is_expected.to pass :manage_assessments? }
  end
end
