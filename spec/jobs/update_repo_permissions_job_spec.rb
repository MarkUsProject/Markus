describe UpdateRepoPermissionsJob do
  context 'when running as a background job' do
    let(:job_args) { [] }
    before { Redis::Namespace.new(Rails.root.to_s).del('repo_permissions') }
    include_examples 'background job'
  end

  describe '#perform' do
    it 'should delete the redis key when finished' do
      UpdateRepoPermissionsJob.perform_now('MemoryRepository')
      expect(Redis::Namespace.new(Rails.root.to_s).get('authorized_keys')).to be_nil
    end

    context 'when called with "MemoryRepository"' do
      it 'should call update_permissions_file' do
        expect(MemoryRepository).to receive(:update_permissions_file)
        UpdateRepoPermissionsJob.perform_now('MemoryRepository')
      end
    end

    context 'when called with "SubversionRepository"' do
      it 'should call update_permissions_file' do
        expect(SubversionRepository).to receive(:update_permissions_file)
        UpdateRepoPermissionsJob.perform_now('SubversionRepository')
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
