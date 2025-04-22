describe UpdateRepoPermissionsJob do
  context 'when running as a background job' do
    let(:job_args) { ['MemoryRepository'] }

    before { redis.del('repo_permissions') }

    it_behaves_like 'background job'
  end

  describe '#perform' do
    it 'should delete the redis key when finished' do
      UpdateRepoPermissionsJob.perform_now('MemoryRepository')
      expect(redis.get('repo_permissions')).to be_nil
    end

    context 'when called with "MemoryRepository"' do
      it 'should call update_permissions_file' do
        expect(MemoryRepository).to receive(:update_permissions_file)
        UpdateRepoPermissionsJob.perform_now('MemoryRepository')
      end
    end

    context 'when called with "GitRepository"' do
      it 'should call update_permissions_file' do
        expect(GitRepository).to receive(:update_permissions_file)
        UpdateRepoPermissionsJob.perform_now('GitRepository')
      end
    end
  end
end
