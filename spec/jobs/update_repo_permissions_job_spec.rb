describe UpdateRepoPermissionsJob do
  context 'when running as a background job' do
    let(:job_args) { ['MemoryRepository'] }

    before { redis.del('repo_permissions') }

    it_behaves_like 'background job'
  end

  context 'when the repository class does not exist' do
    let(:job) { UpdateRepoPermissionsJob.new('NotARepository') }

    it 'stores the error in the job status' do
      expect { job.perform_now }.to raise_error(NameError)
      expect(job.status.to_h).to include(
        status: :failed,
        exception: { class: 'NameError', message: 'uninitialized constant NotARepository' }
      )
    end
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
