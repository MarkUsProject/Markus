describe AutomatedTestsController do
  let(:assignment) { create :assignment }
  let(:params) { { assignment_id: assignment.id } }
  shared_examples 'An authorized admin and grader managing automated testing' do
    include_examples 'An unauthorized user accessing student interface'
    context 'PUT update' do
      before { put_as user, :update, params: params }
      # TODO: write tests
    end
    context 'GET manage' do
      context 'Manage page' do
        before :each do
          get_as user, :manage, params: params
        end
        it 'User should be able to view the Automated Testing manage page' do
          expect(response.status).to eq(200)
        end
        it 'should render the assignment_content layout' do
          expect(response).to render_template('layouts/assignment_content')
        end
      end
      context 'Getting the test student grouping' do
        context 'When the assignment already has test grouping' do
          let(:test_student) { create(:test_student, user_name: User::TEST_STUDENT_USER_NAME) }
          let(:group) { create(:group, group_name: 'test_student_group') }
          let(:grouping) { create(:grouping, group: group, assignment: assignment) }
          let!(:membership) { create(:inviter_student_membership, user: test_student, grouping: grouping) }
          it 'should return the existing test grouping' do
            get_as user, :manage, params: params
            expect(assigns(:test_grouping)).to eq(grouping)
          end
          it 'the membership of the grouping should be same as the membership of the returned test grouping' do
            get_as user, :manage, params: params
            expect(assigns(:test_grouping).memberships.first).to eq(membership)
          end
        end
        context 'When there is no test grouping exists for the assignment' do
          before :each do
            get_as user, :manage, params: params
          end
          it 'should return a newly created test grouping' do
            expect(assigns(:test_grouping)).to be_valid
          end
          it 'should return a grouping which belongs to a test student' do
            user_id = assigns(:test_grouping).memberships.first.user_id
            user = TestStudent.find(user_id)
            expect(user.groupings.find_by(assessment_id: assignment.id)).to eq(assigns(:test_grouping))
          end
          it 'the grouping associated with the user should be a test student' do
            user_id = assigns(:test_grouping).memberships.first.user_id
            user = User.find(user_id)
            expect(user.is_a?(TestStudent)).to be true
          end
        end
      end
    end
    context 'GET populate_autotest_manager' do
      subject { get_as user, :populate_autotest_manager, params: params }
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
      before { get_as user, :download_file, params: params }
      # TODO: write tests
    end
    context 'GET download_files' do
      subject { get_as user, :download_files, params: params }
      let(:content) { response.body }
      it_behaves_like 'zip file download'
      it 'should be successful' do
        subject
        expect(response.status).to eq(200)
      end
    end
    context 'POST upload_files' do
      before { post_as user, :upload_files, params: params }
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
          get_as user, :download_specs, params: params
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
          get_as user, :download_specs, params: params
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
        post_as user, :upload_specs, params: { assignment_id: assignment.id, specs_file: file }
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
  shared_examples 'An unauthorized user managing automated testing' do
    context 'PUT update' do
      before { put_as user, :update, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET manage' do
      before { get_as user, :manage, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET populate_autotest_manager' do
      before { get_as user, :populate_autotest_manager, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET download_file' do
      before { get_as user, :download_file, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET download_files' do
      before { get_as user, :download_files, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'POST upload_files' do
      before { post_as user, :upload_files, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET download_specs' do
      before { get_as user, :download_specs, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'POST upload_specs' do
      before { post_as user, :upload_specs, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
  end
  shared_examples 'An unauthorized user accessing student interface' do
    context 'GET student_interface' do
      before { get_as user, :student_interface, params: { id: assignment.id } }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'POST execute_test_run' do
      before { post_as user, :execute_test_run, params: { id: assignment.id } }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET get_test_runs_students' do
      before { post_as user, :get_test_runs_students, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
  end
  context 'as a student' do
    let(:user) { create :student }
    context 'GET student_interface' do
      before { get_as user, :student_interface, params: params }
      # TODO: write tests
    end
    context 'POST execute_test_run' do
      before { post_as user, :execute_test_run, params: params }
      # TODO: write tests
    end
    context 'GET get_test_runs_students' do
      before { post_as user, :get_test_runs_students, params: params }
      # TODO: write tests
    end
    context 'When student trying to manage automated testing' do
      include_examples 'An unauthorized user managing automated testing'
    end
  end
  describe 'an authenticated admin' do
    let(:user) { create(:admin) }
    include_examples 'An authorized admin and grader managing automated testing'
  end

  describe 'When the grader is allowed to manage automated testing' do
    let(:user) { create(:ta, manage_assessments: true) }
    include_examples 'An authorized admin and grader managing automated testing'
  end

  describe 'When the grader is not allowed to manage automated testing' do
    # By default all the permissions are set to false for a grader
    let(:user) { create(:ta) }
    include_examples 'An unauthorized user managing automated testing'
    include_examples 'An unauthorized user accessing student interface'
  end
end
