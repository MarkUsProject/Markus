describe UploadUsersJob do
  let(:course) { create :course }

  context 'when running as a background job' do
    let(:file) { fixture_file_upload 'students/students.csv' }
    let(:job_args) { [Student, course, File.read(file), nil] }
    include_examples 'background job'
  end
  context 'when run with a correctly formatted file' do
      let(:file) { fixture_file_upload 'students/students.csv' }
      let(:uploaded) { UploadUsersJob.perform_now(Student, course, File.read(file), nil) }
    it 'should not return any error' do
      expect(uploaded[:invalid_lines]).to be_empty
    end
    it 'should create users' do
      uploaded
      expect(User.count).to eq(File.read(file).lines.count)
    end
    it 'should create roles' do
      uploaded
      expect(Role.count).to eq(File.read(file).lines.count)
    end
  end

  context 'when getting a malformed csv' do
    let(:file) { fixture_file_upload 'bad_csv.csv' }
    let(:uploaded) { UploadUsersJob.perform_now(Student, course, File.read(file), nil) }
    it 'returns an error' do
      expect(uploaded[:invalid_lines]).to include('The selected file was improperly formed')
    end
  end
end
