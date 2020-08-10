describe StarterFileEntry do
  it { is_expected.to belong_to(:starter_file_group) }
  it { is_expected.to have_many(:grouping_starter_file_entries) }
  it { is_expected.to have_many(:groupings).through(:grouping_starter_file_entries) }

  let(:starter_file_entry) { create :starter_file_entry }
  context 'more validations' do
    it 'should be valid when the entry exists on disk' do
      expect(starter_file_entry).to be_valid
    end
    it 'should not be valid when the entry does not exist on disk' do
      FileUtils.rm_rf(starter_file_entry.full_path)
      expect(starter_file_entry).not_to be_valid
    end
  end

  describe '#full_path' do
    it 'should return an absolute path to an entry on disk' do
      expect(starter_file_entry.full_path).to eq starter_file_entry.starter_file_group.path + starter_file_entry.path
      expect(starter_file_entry.full_path).to exist
    end
  end

  describe '#files_and_dirs' do
    context 'when the entry is a file' do
      it 'should contain only the top level entry' do
        expect(starter_file_entry.files_and_dirs).to contain_exactly(starter_file_entry.full_path)
      end
    end
    context 'when the entry is a folder' do
      let(:content) { { 'subdir/': nil, 'subdir2/': nil, 'subdir/file.txt': 'other content' } }
      let(:starter_file_entry) { create :starter_file_entry, is_file: false, extra_structure: content }
      it 'should contain the correct entries' do
        entries = content.keys.map { |c| (starter_file_entry.full_path + c.to_s).realpath }
        expect(starter_file_entry.files_and_dirs).to contain_exactly(starter_file_entry.full_path, *entries)
      end
    end
  end

  describe '#add_files_to_transaction' do
    let(:content) { { 'subdir': nil, 'subdir2': nil, 'subdir/file.txt': 'other content' } }
    let(:starter_file_entry) { create :starter_file_entry, is_file: false, extra_structure: content }
    let(:grouping) { create :grouping }
    let(:user) { create :admin }
    let(:expected_jobs) do
      repo_root_dir = starter_file_entry.starter_file_group.assignment.repository_folder
      content.map do |path, content|
        if content.nil?
          extra = { action: :add_path }
        else
          extra = { action: :add, file_data: content, mime_type: 'text/plain' }
        end
        { path: File.join(repo_root_dir, starter_file_entry.path, path.to_s), **extra }
      end + [{ action: :add_path, path: File.join(repo_root_dir, starter_file_entry.path) }]
    end
    it 'should add files to a transaction' do
      grouping.group.access_repo do |repo|
        txn = repo.get_transaction(user.user_name)
        starter_file_entry.add_files_to_transaction(txn)
        expect(txn.jobs).to contain_exactly(*expected_jobs)
      end
    end
  end

  describe '#add_files_to_zip_file' do
    let(:zip_path) { File.join(::Rails.root, 'tmp', 'test-file.zip') }
    let(:content) { { 'subdir': nil, 'subdir2': nil, 'subdir/file.txt': 'other content' } }
    let(:starter_file_entry) { create :starter_file_entry, is_file: false, extra_structure: content }
    it 'should add files to an open zip file' do
      FileUtils.rm_f(zip_path)
      Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
        starter_file_entry.add_files_to_zip_file(zip_file)
      end
      Zip::File.open(zip_path) do |zip_file|
        expect(zip_file.find_entry(File.join(starter_file_entry.path, 'subdir/'))).not_to be_nil
        expect(zip_file.find_entry(File.join(starter_file_entry.path, 'subdir2/'))).not_to be_nil
        expect(zip_file.find_entry(File.join(starter_file_entry.path, 'subdir/file.txt'))).not_to be_nil
      end
    end
  end
end
