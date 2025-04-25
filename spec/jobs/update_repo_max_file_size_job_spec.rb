describe UpdateRepoMaxFileSizeJob do
  let(:course) { create(:course, max_file_size: rand(0..5_000_000_000)) }

  context 'when running as a background job' do
    let(:job_args) { [course.id] }

    it_behaves_like 'background job'
  end

  context 'updating required files' do
    before do
      allow(Settings.repository).to receive(:type).and_return('git')
      allow(Repository.get_class).to receive(:purge_all).and_return nil
    end

    after { FileUtils.rm_r(Dir.glob(File.join(Repository::ROOT_DIR, '*'))) }

    let!(:groups) { create_list(:group, 3, course: course) }

    it 'should update every repo' do
      count = 0
      allow_any_instance_of(Repository::Transaction).to receive(:replace) { count += 1 }
      UpdateRepoMaxFileSizeJob.perform_now(course.id)
      expect(count).to eq groups.length
    end

    it 'should update the .max_file_size file' do
      allow_any_instance_of(Repository::Transaction).to receive(:replace) do |_txn, *args|
        expect(args[0]).to eq '.max_file_size'
      end
      UpdateRepoMaxFileSizeJob.perform_now(course.id)
    end

    it 'should send the correct file content' do
      allow_any_instance_of(Repository::Transaction).to receive(:replace) do |_txn, *args|
        expect(args[1]).to eq course.max_file_size.to_s
      end
      UpdateRepoMaxFileSizeJob.perform_now(course.id)
    end
  end
end
