shared_examples 'zip file download' do
  let(:dirs) { [] }
  let(:files) { {} }
  before :each do
    FileUtils.mkdir_p assignment.autotest_files_dir
    dirs.each { |dir_path| FileUtils.mkdir_p File.join(assignment.autotest_files_dir, dir_path) }
    files.each do |file_path, content|
      File.write(File.join(assignment.autotest_files_dir, file_path.to_s), content)
    end
    subject
  end
  after :each do
    FileUtils.rm_rf assignment.autotest_files_dir
  end
  context 'when there are no test files' do
    it 'should return a zip containing no files' do
      check_zip_file_count(content, 0, 0)
    end
  end
  context 'when there is a single test file' do
    let(:files) { { 'test.txt': 'test_content' } }
    it 'should return a zip containing one file' do
      check_zip_file_count(content, 1, 0)
    end
    it 'should have files that contain the correct content' do
      check_file_content(content, ['test_content'])
    end
  end
  context 'when there is a single test directory' do
    let(:dirs) { ['test_dir'] }
    it 'should return a zip containing one file' do
      check_zip_file_count(content, 0, 1)
    end
  end
  context 'when there is a file in a subdirectory' do
    let(:dirs) { ['test_dir'] }
    let(:files) { { 'test_dir/test.txt': 'test_content' } }
    it 'should return a zip containing one file and one directory' do
      check_zip_file_count(content, 1, 1)
    end
    it 'should have files that contain the correct content' do
      check_file_content(content, ['test_content'])
    end
  end
end

def check_zip_file_count(content, file_count, dir_count)
  files, dirs = 0, 0
  Zip::InputStream.open(StringIO.new(content)) do |io|
    while (entry = io.get_next_entry)
      if entry.name_is_directory?
        dirs += 1
      else
        files += 1
      end
    end
  end
  expect(files).to eq file_count
  expect(dirs).to eq dir_count
end

def check_file_content(content, expected_file_content)
  file_content = []
  Zip::InputStream.open(StringIO.new(content)) do |io|
    while (entry = io.get_next_entry)
      file_content << io.read.strip.force_encoding('utf-8') unless entry.name_is_directory?
    end
  end
  expect(file_content).to contain_exactly(*expected_file_content)
end
