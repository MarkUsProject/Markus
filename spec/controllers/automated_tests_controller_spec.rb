describe AutomatedTestsController do
  include AutomatedTestsHelper

  # TODO: add 'role is from a different course' shared tests to each route test below
  let(:assignment) { create :assignment }
  let(:params) { { course_id: assignment.course.id, assignment_id: assignment.id } }
  before do
    allow_any_instance_of(AutotestSetting).to(
      receive(:send_request!).and_return(OpenStruct.new(body: { api_key: 'someapikey' }.to_json))
    )
    course = create(:course)
    course.autotest_setting = create(:autotest_setting)
    course.save
  end
  shared_examples 'An authorized instructor and grader managing automated testing' do
    include_examples 'An unauthorized role accessing student interface'
    context 'PUT update' do
      before { put_as role, :update, params: params }
      # TODO: write tests
    end
    context 'GET manage' do
      before :each do
        get_as role, :manage, params: params
      end
      it 'role should be able to view the Automated Testing manage page' do
        expect(response.status).to eq(200)
      end
      it 'should render the assignment_content layout' do
        expect(response).to render_template('layouts/assignment_content')
      end
    end
    context 'GET populate_autotest_manager' do
      subject { get_as role, :populate_autotest_manager, params: params }
      before do
        file = fixture_file_upload('automated_tests/minimal_testers.json')
        assignment.course.autotest_setting.update!(schema: file.read)
      end
      it 'should respond with success' do
        subject
        expect(response.status).to eq 200
      end
      context 'tests.json does exist' do
        before { allow_any_instance_of(AutomatedTestsHelper).to receive(:fill_in_schema_data!) }
        it 'should return the schema from the file' do
          file_content = JSON.parse(fixture_file_upload('automated_tests/minimal_testers.json').read)
          subject
          expect(JSON.parse(response.body)['schema']).to eq(file_content)
        end
      end
      context 'the assignment has no test settings' do
        it 'should return empty form data' do
          subject
          expect(JSON.parse(response.body)['formData']).to eq({})
        end
      end
      context 'the assignment has test settings' do
        let(:settings_content) { { 'a' => 2 } }
        it 'should return the settings content as form data' do
          assignment.update!(autotest_settings: settings_content)
          subject
          expect(JSON.parse(response.body)['formData']).to eq(settings_content)
        end
      end
      context 'assignment data' do
        let(:properties) do
          { enable_test: true,
            enable_student_tests: true,
            tokens_per_period: 10,
            token_period: 24,
            token_start_date: Time.current.strftime('%Y-%m-%d %l:%M %p'),
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
          current_time = Time.utc(2021)
          allow_any_instance_of(Assignment).to receive(:autotest_files).and_return ['file.txt']
          allow_any_instance_of(Pathname).to receive(:exist?).and_return true
          allow(File).to receive(:mtime).and_return current_time
          role.update(time_zone: 'UTC')
          subject
          url = download_file_course_assignment_automated_tests_url(assignment.course,
                                                                    assignment,
                                                                    file_name: 'file.txt')
          data = [{ key: 'file.txt', submitted_date: I18n.l(current_time),
                    size: 1, url: url }.transform_keys(&:to_s)]
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
          current_time = Time.utc(2021)
          allow(File).to receive(:mtime).and_return current_time
          allow_any_instance_of(Assignment).to receive(:autotest_files).and_return %w[some_dir some_dir/file.txt]
          allow_any_instance_of(Pathname).to receive(:exist?).and_return true
          allow_any_instance_of(Pathname).to receive(:directory?).and_wrap_original do |m, *_args|
            m.receiver.basename.to_s == 'some_dir'
          end
          role.update(time_zone: 'UTC')
          subject
          url = download_file_course_assignment_automated_tests_url(assignment.course,
                                                                    assignment,
                                                                    file_name: 'some_dir/file.txt')
          data = [{ key: 'some_dir/' }, { key: 'some_dir/file.txt',
                                          submitted_date: I18n.l(current_time),
                                          size: 1, url: url }]
          expect(JSON.parse(response.body)['files']).to eq(data.map { |h| h.transform_keys(&:to_s) })
        end
      end
    end
    context 'GET download_file' do
      before { get_as role, :download_file, params: params }
      # TODO: write tests
    end
    context 'GET download_files' do
      subject { get_as role, :download_files, params: params }
      let(:content) { response.body }
      it_behaves_like 'zip file download'
      it 'should be successful' do
        subject
        expect(response.status).to eq(200)
      end
      context 'non empty automated test files' do
        before :each do
          FileUtils.rm_rf(assignment.autotest_files_dir)
          create_automated_test(assignment)
        end
        after :each do
          # Clear uploaded autotest files to prepare for next test
          FileUtils.rm_rf(assignment.autotest_files_dir)
        end
        it 'should receive the appropriate files' do
          subject
          received_content = []
          Zip::InputStream.open(StringIO.new(content)) do |io|
            while (entry = io.get_next_entry)
              unless entry.name_is_directory?
                received_content << {
                  name: entry.name,
                  file_content: entry.get_input_stream.read
                }
              end
            end
          end
          expected_content = [{
            name: File.join('Helpers', 'test_helpers.py'),
            file_content: "def initialize_tests()\n\treturn True"
          }, {
            name: 'tests.py',
            file_content: "def sample_test()\n\tassert True == True"
          }]
          expect(received_content).to match_array(expected_content)
        end
      end
    end
    context 'POST upload_files' do
      before do
        FileUtils.rm_r assignment.autotest_files_dir
        post_as role, :upload_files, params: params
      end
      after { FileUtils.rm_r assignment.autotest_files_dir }
      context 'uploading a zip file' do
        let(:params) do
          { course_id: assignment.course.id, assignment_id: assignment.id,
            unzip: unzip, new_files: [zip_file], path: '' }
        end
        let(:tree) { assignment.autotest_files }
        context 'when unzip if false' do
          let(:unzip) { 'false' }
          let(:zip_file) { fixture_file_upload('test_zip.zip', 'application/zip') }
          it 'should just upload the zip file as is' do
            expect(tree).to include('test_zip.zip')
          end
          it 'should not upload any other files' do
            expect(tree.length).to eq 1
          end
        end
        context 'when unzip is true' do
          let(:unzip) { 'true' }
          context 'when the zip file contains entries for all subdirectories and files' do
            let(:zip_file) do
              fixture_file_upload('zip_file_with_dirs_and_files.zip', 'application/zip')
            end
            it 'should not upload the zip file' do
              expect(tree).not_to include('zip_file_with_dirs_and_files.zip')
            end
            it 'should upload the outer dir' do
              expect(tree).to include('zip_file_with_dirs_and_files')
            end
            it 'should upload the inner dir' do
              expect(tree).to include('zip_file_with_dirs_and_files/zip_subdir')
            end
            it 'should upload a file in the outer dir' do
              expect(tree).to include('zip_file_with_dirs_and_files/Shapes.java')
            end
            it 'should upload a file in the inner dir' do
              expect(tree).to include('zip_file_with_dirs_and_files/zip_subdir/TestShapes.java')
            end
          end
          context 'when the zip file contains entries for files only' do
            let(:zip_file) { fixture_file_upload('zip_file_with_files.zip', 'application/zip') }
            it 'should upload the outer dir' do
              expect(tree).to include('zip_file_with_files')
            end
            it 'should upload a file in the outer dir' do
              expect(tree).to include('zip_file_with_files/TestShapes.java')
            end
          end
        end
      end
    end
    context 'GET download_specs' do
      context 'when the assignment has test settings' do
        let(:content) { { 'a' => 1 } }
        before :each do
          assignment.update!(autotest_settings: content)
        end
        it 'should download a file containing the content' do
          get_as role, :download_specs, params: params
          expect(JSON.parse(response.body)).to eq content
        end
        it 'should respond with a success' do
          get_as role, :download_specs, params: params
          expect(response.status).to eq 200
        end
        context 'when there is a test_group_id specified' do
          let(:content) { { testers: [{ test_data: [10] }] } }
          before do
            create(:test_group, assignment: assignment, id: 10)
          end
          it 'should remove the test_group_id' do
            get_as role, :download_specs, params: params
            test_group_settings = JSON.parse(response.body)['testers'].first['test_data'].first['extra_info']
            expect(test_group_settings).to_not have_key('test_group_id')
          end
        end
      end
      context 'when the assignment does not have test settings' do
        before :each do
          get_as role, :download_specs, params: params
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
        post_as role, :upload_specs, params: { course_id: assignment.course.id,
                                               assignment_id: assignment.id,
                                               specs_file: file }
        file&.rewind
        assignment.reload
      end
      after :each do
        flash.now[:error] = nil
      end
      context 'a valid json file' do
        let(:file) { fixture_file_upload 'automated_tests/valid_json.json' }
        it 'should upload the file content' do
          expect(autotest_settings_for(assignment)).to eq JSON.parse(file.read)
        end
        it 'should return a success http status' do
          expect(response.status).to eq 200
        end
      end
      context 'an invalid json file' do
        let(:file) { fixture_file_upload 'automated_tests/invalid_json.json' }
        it 'should not update the assignment test settings' do
          expect(assignment.reload.autotest_settings).to be nil
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
        it 'should not update the assignment test settings' do
          expect(assignment.reload.autotest_settings).to be nil
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
  shared_examples 'An unauthorized role managing automated testing' do
    context 'PUT update' do
      before { put_as role, :update, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET manage' do
      before { get_as role, :manage, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET populate_autotest_manager' do
      before { get_as role, :populate_autotest_manager, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET download_file' do
      before { get_as role, :download_file, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET download_files' do
      before { get_as role, :download_files, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'POST upload_files' do
      before { post_as role, :upload_files, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET download_specs' do
      before { get_as role, :download_specs, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'POST upload_specs' do
      before { post_as role, :upload_specs, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
  end
  shared_examples 'An unauthorized role accessing student interface' do
    context 'GET student_interface' do
      before do
        get_as role, :student_interface, params: { course_id: assignment.course.id, assignment_id: assignment.id }
      end
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'POST execute_test_run' do
      before do
        post_as role, :execute_test_run, params: { course_id: assignment.course.id, assignment_id: assignment.id }
      end
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET get_test_runs_students' do
      before { post_as role, :get_test_runs_students, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
  end
  context 'as a student' do
    let(:role) { create :student }
    context 'GET student_interface' do
      before { get_as role, :student_interface, params: params }
      # TODO: write tests
    end
    context 'POST execute_test_run' do
      before { post_as role, :execute_test_run, params: params }
      # TODO: write tests
    end
    context 'GET get_test_runs_students' do
      before { post_as role, :get_test_runs_students, params: params }
      # TODO: write tests
    end
    context 'When student trying to manage automated testing' do
      include_examples 'An unauthorized role managing automated testing'
    end
  end
  describe 'an authenticated instructor' do
    let(:role) { create(:instructor) }
    include_examples 'An authorized instructor and grader managing automated testing'
  end

  describe 'When the grader is allowed to manage automated testing' do
    let(:role) { create(:ta, manage_assessments: true) }
    include_examples 'An authorized instructor and grader managing automated testing'
  end

  describe 'When the grader is not allowed to manage automated testing' do
    # By default all the permissions are set to false for a grader
    let(:role) { create(:ta) }
    include_examples 'An unauthorized role managing automated testing'
    include_examples 'An unauthorized role accessing student interface'
  end
end
