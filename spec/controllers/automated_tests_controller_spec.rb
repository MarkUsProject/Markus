describe AutomatedTestsController do
  let(:assignment) { create :assignment }
  let(:admin) { create :admin }
  context 'GET download_files' do
    subject { get_as admin, :download_files, params: { assignment_id: assignment.id } }
    let(:content) { response.body }
    it_behaves_like 'zip file download'

    it 'should be successful' do
      subject
      expect(response.status).to eq(200)
    end
  end
  context 'GET download_specs' do
    context 'when the file exists' do
      let(:content) { '{"a":1}' }
      before :each do
        File.write(assignment.autotest_settings_file, content)
        get_as admin, :download_specs, params: { assignment_id: assignment.id }
      end
      it 'should download a file containing the content' do
        expect(response.body).to eq content
      end
      it 'should respond with a success' do
        expect(response.status).to eq 200
      end
    end
    context 'when the file does not exist' do
      before :each do
        FileUtils.rm_f(assignment.autotest_settings_file)
        get_as admin, :download_specs, params: { assignment_id: assignment.id }
      end
      it 'should download a file with an empty hash' do
        expect(response.body).to eq '{}'
      end
      it 'should respond with a success' do
        expect(response.status).to eq 200
      end
    end
  end
  context 'POST upload_specs' do
    before :each do
      File.write(assignment.autotest_settings_file, '')
      post_as admin, :upload_specs, params: { assignment_id: assignment.id, specs_file: file }
      file&.rewind
    end
    after :each do
      flash.now[:error] = nil
    end
    context 'a valid json file' do
      let(:file) { fixture_file_upload 'files/automated_tests/valid_json.json' }
      it 'should upload the file content' do
        expect(File.read(assignment.autotest_settings_file)).to eq file.read
      end
      it 'should return a success http status' do
        expect(response.status).to eq 204
      end
    end
    context 'an invalid json file' do
      let(:file) { fixture_file_upload 'files/automated_tests/invalid_json.json' }
      it 'should not upload the file content' do
        expect(File.read(assignment.autotest_settings_file)).to eq ''
      end
      it 'should flash an error message' do
        expect(flash.now[:error]).not_to be_empty
      end
      it 'should return a not_modified http status' do
        expect(response.status).to eq 422
      end
    end
    context 'nothing uploaded' do
      let(:file) { nil }
      it 'should not upload the file content' do
        expect(File.read(assignment.autotest_settings_file)).to eq ''
      end
      it 'should not flash an error message' do
        expect(flash.now[:error]).to be_nil
      end
      it 'should return a not_modified http status' do
        expect(response.status).to eq 422
      end
    end
  end
end
