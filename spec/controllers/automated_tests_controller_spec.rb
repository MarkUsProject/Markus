describe AutomatedTestsController do
  let(:assignment) { create :assignment }
  let(:params) { { assignment_id: assignment.id } }
  context 'as an admin' do
    let(:admin) { create :admin }

    context 'PUT update' do
      before { put_as admin, :update, params: params }
      # TODO: write tests
    end
    context 'GET manage' do
      before { get_as admin, :manage, params: params }
      # TODO: write tests
    end
    context 'GET student_interface' do
      before { get_as admin, :student_interface, params: { id: 1 } }
      # TODO: write tests
    end
    context 'POST execute_test_run' do
      before { post_as admin, :execute_test_run, params: { id: 1 } }
      # TODO: write tests
    end
    context 'GET get_test_runs_students' do
      before { post_as admin, :get_test_runs_students, params: params }
      # TODO: write tests
    end
    context 'GET populate_autotest_manager' do
      subject { get_as admin, :populate_autotest_manager, params: params }
      let(:settings_content) { '{}' }
      before do
        allow(AutotestTestersJob).to receive(:perform_later) { AutotestTestersJob.new }
        file = fixture_file_upload('files/automated_tests/minimal_testers.json')
        File.write(File.join(Rails.configuration.x.autotest.client_dir, 'testers.json'), file.read)
        File.write(assignment.autotest_settings_file, settings_content)
      end
      after do
        FileUtils.rm_f File.join(Rails.configuration.x.autotest.client_dir, 'testers.json')
        FileUtils.rm_f assignment.autotest_settings_file
      end
      it 'should respond with success' do
        subject
        expect(response.status).to eq 200
      end
      context 'testers.json does not exist' do
        before { FileUtils.rm_rf File.join(Rails.configuration.x.autotest.client_dir, 'testers.json') }
        it 'should call the AutotestTestersJob' do
          expect(AutotestTestersJob).to receive(:perform_later)
          subject
        end
        it 'should return an empty schema' do
          subject
          expect(JSON.parse(response.body)['schema']).to eq({})
        end
        it 'should flash a notice' do
          subject
          expect(flash[:notice]).not_to be_nil
        end
      end
      context 'tests.json does exist' do
        before { allow_any_instance_of(AutomatedTestsHelper).to receive(:fill_in_schema_data!) }
        it 'should return the schema from the file' do
          file_content = JSON.parse(fixture_file_upload('files/automated_tests/minimal_testers.json').read)
          subject
          expect(JSON.parse(response.body)['schema']).to eq(file_content)
        end
      end
      context 'settings file does not exist' do
        before { FileUtils.rm_rf assignment.autotest_settings_file }
        it 'should return empty form data' do
          subject
          expect(JSON.parse(response.body)['formData']).to eq({})
        end
      end
      context 'settings file does exist' do
        let(:settings_content) { '{"a": 2}' }
        it 'should return the settings content as form data' do
          subject
          expect(JSON.parse(response.body)['formData']).to eq(JSON.parse(settings_content))
        end
      end
      context 'assignment data' do
        let(:properties) do
          { enable_test: true,
            enable_student_tests: true,
            tokens_per_period: 10,
            token_period: 24,
            token_start_date: Time.now.strftime('%Y-%m-%d %l:%M %p'),
            non_regenerating_tokens: false,
            unlimited_tokens: false }
        end
        before { assignment.update!(properties) }
        it 'should include assignment data' do
          subject
          expect(JSON.parse(response.body).slice(*properties.keys.map(&:to_s))).to eq(properties.transform_keys(&:to_s))
        end
      end
      context 'files data' do
        it 'should include assignment files' do
          allow_any_instance_of(Assignment).to receive(:autotest_files).and_return ['file.txt']
          subject
          url = download_file_assignment_automated_tests_url(assignment_id: assignment.id, file_name: 'file.txt')
          data = [{ key: 'file.txt', size: 1, url: url }.transform_keys(&:to_s)]
          expect(JSON.parse(response.body)['files']).to eq(data)
        end
        it 'should include directories' do
          allow_any_instance_of(Assignment).to receive(:autotest_files).and_return ['some_dir']
          allow_any_instance_of(Pathname).to receive(:directory?).and_return true
          subject
          data = [{ key: 'some_dir/' }.transform_keys(&:to_s)]
          expect(JSON.parse(response.body)['files']).to eq(data)
        end
        it 'should include nested files' do
          allow_any_instance_of(Assignment).to receive(:autotest_files).and_return %w[some_dir some_dir/file.txt]
          allow_any_instance_of(Pathname).to receive(:directory?).and_wrap_original do |m, *_args|
            m.receiver.basename.to_s == 'some_dir'
          end
          subject
          url = download_file_assignment_automated_tests_url(assignment_id: assignment.id,
                                                             file_name: 'some_dir/file.txt')
          data = [{ key: 'some_dir/' }, { key: 'some_dir/file.txt', size: 1, url: url }]
          expect(JSON.parse(response.body)['files']).to eq(data.map { |h| h.transform_keys(&:to_s) })
        end
      end
    end
    context 'GET download_file' do
      before { get_as admin, :download_file, params: params }
      # TODO: write tests
    end
    context 'GET download_files' do
      subject { get_as admin, :download_files, params: params }
      let(:content) { response.body }
      it_behaves_like 'zip file download'
      it 'should be successful' do
        subject
        expect(response.status).to eq(200)
      end
    end
    context 'POST upload_files' do
      before { post_as admin, :upload_files, params: params }
      after { FileUtils.rm_r assignment.autotest_files_dir }
      context 'uploading a zip file' do
        let(:zip_file) { fixture_file_upload(File.join('/files', 'test_zip.zip'), 'application/zip') }
        let(:unzip) { 'true' }
        let(:params) { { assignment_id: assignment.id, unzip: unzip, new_files: [zip_file], path: '' } }
        let(:tree) { assignment.autotest_files }
        context 'when unzip if false' do
          let(:unzip) { 'false' }
          it 'should just upload the zip file as is' do
            expect(tree).to include('test_zip.zip')
          end
          it 'should not upload any other files' do
            expect(tree.length).to eq 1
          end
        end
        it 'should not upload the zip file' do
          expect(tree).not_to include('test_zip.zip')
        end
        it 'should upload the outer dir' do
          expect(tree).to include('test_zip')
        end
        it 'should upload the inner dir' do
          expect(tree).to include('test_zip/zip_subdir')
        end
        it 'should upload a file in the outer dir' do
          expect(tree).to include('test_zip/Shapes.java')
        end
        it 'should upload a file in the inner dir' do
          expect(tree).to include('test_zip/zip_subdir/TestShapes.java')
        end
      end
    end
    context 'GET download_specs' do
      context 'when the file exists' do
        let(:content) { '{"a":1}' }
        before :each do
          File.write(assignment.autotest_settings_file, content)
          get_as admin, :download_specs, params: params
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
          get_as admin, :download_specs, params: params
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
          expect(response.status).to eq 200
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
  context 'as a student' do
    let(:student) { create :student }
    context 'PUT update' do
      before { put_as student, :update, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'GET manage' do
      before { get_as student, :manage, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'GET student_interface' do
      before { get_as student, :student_interface, params: params }
      # TODO: write tests
    end
    context 'POST execute_test_run' do
      before { post_as student, :execute_test_run, params: params }
      # TODO: write tests
    end
    context 'GET get_test_runs_students' do
      before { post_as student, :get_test_runs_students, params: params }
      # TODO: write tests
    end
    context 'GET populate_autotest_manager' do
      before { get_as student, :populate_autotest_manager, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'GET download_file' do
      before { get_as student, :download_file, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'GET download_files' do
      before { get_as student, :download_files, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'POST upload_files' do
      before { post_as student, :upload_files, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'GET download_specs' do
      before { get_as student, :download_specs, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'POST upload_specs' do
      before { post_as student, :upload_specs, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
  end
  context 'as a grader' do
    let(:grader) { create :ta }
    context 'PUT update' do
      before { put_as grader, :update, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'GET manage' do
      before { get_as grader, :manage, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'GET student_interface' do
      before { get_as grader, :student_interface, params: { id: 1 } }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'POST execute_test_run' do
      before { post_as grader, :execute_test_run, params: { id: 1 } }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'GET get_test_runs_students' do
      before { post_as grader, :get_test_runs_students, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'GET populate_autotest_manager' do
      before { get_as grader, :populate_autotest_manager, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'GET download_file' do
      before { get_as grader, :download_file, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'GET download_files' do
      before { get_as grader, :download_files, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'POST upload_files' do
      before { post_as grader, :upload_files, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'GET download_specs' do
      before { get_as grader, :download_specs, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
    context 'POST upload_specs' do
      before { post_as grader, :upload_specs, params: params }
      it('should respond with 404') { expect(response.status).to eq 404 }
    end
  end
end
