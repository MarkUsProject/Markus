describe KeyPairPolicy, keep_memory_repos: true do
  let(:context) { { real_user: user.user } }
  let(:user) { create :instructor }

  describe_rule :manage? do
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
end
