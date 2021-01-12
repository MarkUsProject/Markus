describe KeyPairPolicy, keep_memory_repos: true do
  let(:context) { { user: user } }
  let(:user) { create :admin }

  describe_rule :view? do
    succeed 'repo type is git and key storage is enabled' do
      before do
        allow(Settings.repository).to receive(:type).and_return('git')
        allow(Settings).to receive(:enable_key_storage).and_return(true)
      end
    end
    failed 'repo type is not git' do
      before do
        allow(Settings.repository).to receive(:type).and_return('svn')
        allow(Settings).to receive(:enable_key_storage).and_return(true)
      end
    end
    failed 'key storage is not enabled' do
      before do
        allow(Settings.repository).to receive(:type).and_return('git')
        allow(Settings).to receive(:enable_key_storage).and_return(false)
      end
    end
  end

  describe_rule :manage? do
    context 'repo type is git and key storage is enabled' do
      before do
        allow(Settings.repository).to receive(:type).and_return('git')
        allow(Settings).to receive(:enable_key_storage).and_return(true)
      end
      succeed 'when the user is an admin'
      succeed 'when the user is a ta' do
        let(:user) { create :ta }
      end
      context 'when the user is a student' do
        let(:user) { create :student }
        succeed 'when there is a unhidden assignment with vcs_submit allowed' do
          before { create :assignment, is_hidden: false, assignment_properties_attributes: { vcs_submit: true } }
        end
        failed 'when there is a hidden assignment with vcs_submit allowed' do
          before { create :assignment, is_hidden: true, assignment_properties_attributes: { vcs_submit: true } }
        end
        failed 'when there is an unhidden assignment with vcs_submit not allowed' do
          before { create :assignment, is_hidden: false, assignment_properties_attributes: { vcs_submit: false } }
        end
      end
    end
    failed 'repo type is not git' do
      before do
        allow(Settings.repository).to receive(:type).and_return('svn')
        allow(Settings).to receive(:enable_key_storage).and_return(true)
      end
    end
    failed 'key storage is not enabled' do
      before do
        allow(Settings.repository).to receive(:type).and_return('git')
        allow(Settings).to receive(:enable_key_storage).and_return(false)
      end
    end
  end
end
