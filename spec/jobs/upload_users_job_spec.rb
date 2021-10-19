describe UploadUsersJob do
  let(:course) { create :course }

  context 'when running as a background job' do
    it 'runs successfully as a background job' do
      file = 'spec/fixtures/files/students/students.csv'
      let!(:job_args) { [Student, course, File.read(file), nil] }
      include_examples 'background job'
    end
  end
  context 'when run with a correctly formatted file' do
    before :each do
      @file = 'spec/fixtures/files/students/students.csv'
      @uploaded = UploadUsersJob.perform_now(Student, course, File.read(@file), nil)
    end
    it 'should not return any error' do
      expect(@uploaded[:invalid_lines]).to be_empty
    end
    it 'should create users' do
      expect(User.count).to eq(File.read(@file).lines.count)
    end
    it 'should create roles' do
      expect(Role.count).to eq(File.read(@file).lines.count)
    end
  end

  context 'when getting a malformed csv' do
    file = 'spec/fixtures/files/bad_csv.csv'
    it 'returns an error' do
      uploaded = UploadUsersJob.perform_now(Student, course, File.read(file), nil)
      expect(uploaded[:invalid_lines]).to include('The selected file was improperly formed')
    end
  end
end
