describe ApplicationJob do
  describe '.accesses_repositories_in_bulk' do
    # jobs need a class name to determine their queue
    let(:job_class) do
      stub_const('BulkAccessTestJob', Class.new(ApplicationJob))
      BulkAccessTestJob.class_eval do
        accesses_repositories_in_bulk

        def perform
          Repository.get_class.track_bulk_access
        end
      end
      BulkAccessTestJob
    end

    it 'performs the job inside a bulk_access block' do
      stub_const('Repository::AbstractRepository::BULK_ACCESS_RELEASE_INTERVAL', 1)
      # repository accesses only trigger releases inside a bulk_access block
      expect(GC).to receive(:start).once
      job_class.perform_now
    end
  end

  [AutoMatchJob, CreateGroupsJob, DownloadSubmissionsJob, SplitPdfJob, SubmissionsJob].each do |job|
    it "#{job} accesses repositories in bulk" do
      expect(job.__callbacks[:perform].map(&:kind)).to include(:around)
    end
  end
end
