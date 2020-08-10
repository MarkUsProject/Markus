describe KeyPairPolicy do
  include PolicyHelper

  subject { described_class.new(user: user) }
  let(:user) { create :admin }

  shared_examples 'vcs_submit_variation' do |force_pass: false, force_fail: false|
    let(:to_func) { force_pass || (!force_fail && should_pass) ? :to : :not_to }
    context 'no assignment' do
      let(:should_pass) { false }
      it { is_expected.send(to_func, pass(policy)) }
    end
    context 'assignment exists' do
      let!(:assignment) { create :assignment, **attrs }
      context 'vcs_submit is true' do
        context 'is_hidden is true' do
          let(:attrs) { { assignment_properties_attributes: { vcs_submit: true }, is_hidden: true } }
          let(:should_pass) { false }
          it { is_expected.send(to_func, pass(policy)) }
        end
        context 'is_hidden is false' do
          let(:attrs) { { assignment_properties_attributes: { vcs_submit: true }, is_hidden: false } }
          let(:should_pass) { true }
          it { is_expected.send(to_func, pass(policy)) }
        end
      end
      context 'vcs_submit is false' do
        context 'is_hidden is true' do
          let(:attrs) { { assignment_properties_attributes: { vcs_submit: false }, is_hidden: true } }
          let(:should_pass) { false }
          it { is_expected.send(to_func, pass(policy)) }
        end
        context 'is_hidden is false' do
          let(:attrs) { { assignment_properties_attributes: { vcs_submit: false }, is_hidden: false } }
          let(:should_pass) { false }
          it { is_expected.send(to_func, pass(policy)) }
        end
      end
    end
  end

  describe '#manage?', :keep_memory_repos do
    let(:policy) { :manage? }
    shared_examples 'user_variation' do |opts: {}|
      context 'as an admin' do
        let(:user) { create :admin }
        include_examples 'vcs_submit_variation', force_pass: opts[:pass_admin], force_fail: opts[:fail_admin]
      end
      context 'as a grader' do
        let(:user) { create :ta }
        include_examples 'vcs_submit_variation', force_pass: opts[:pass_grader], force_fail: opts[:fail_grader]
      end
      context 'as a student' do
        let(:user) { create :student }
        include_examples 'vcs_submit_variation', force_pass: opts[:pass_student], force_fail: opts[:fail_student]
      end
    end

    context 'with git enabled' do
      before :each do
        allow(Rails.configuration.x.repository).to receive(:type).and_return('git')
      end
      include_examples 'user_variation', opts: { pass_admin: true, pass_grader: true }
    end
    context 'with svn enabled' do
      before :each do
        allow(Rails.configuration.x.repository).to receive(:type).and_return('svn')
      end
      include_examples 'user_variation', opts: { fail_admin: true, fail_grader: true, fail_student: true }
    end
  end

  describe '#git_enabled?', :keep_memory_repos do
    context 'with git enabled' do
      before :each do
        allow(Rails.configuration.x.repository).to receive(:type).and_return('git')
      end
      it { is_expected.to pass(:git_enabled?) }
    end
    context 'with svn enabled' do
      before :each do
        allow(Rails.configuration.x.repository).to receive(:type).and_return('svn')
      end
      it { is_expected.not_to pass(:git_enabled?) }
    end
  end

  describe '#any_vcs_submit?' do
    let(:policy) { :any_vcs_submit? }
    include_examples 'vcs_submit_variation'
  end
end
