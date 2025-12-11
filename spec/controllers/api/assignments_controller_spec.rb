describe Api::AssignmentsController do
  include AutomatedTestsHelper

  let(:course) { create(:course) }
  let(:assignment) { create(:assignment, course: course) }

  shared_examples 'GET #index' do
    let(:assignment_different_course) { create(:assignment, course: create(:course)) }
    let(:assignments) { create_list(:assignment, 5, course: course) }
    let(:assignments_different_course) { create_list(:assignment, 5, course: create(:course)) }

    context 'when expecting an xml response' do
      before do
        request.env['HTTP_ACCEPT'] = 'application/xml'
      end

      context 'with a single assignment' do
        it 'should be successful' do
          assignment
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(:ok)
        end

        it 'should return xml content' do
          assignment
          get :index, params: { course_id: course.id }
          expect(Hash.from_xml(response.body).dig('assignments', 'assignment', 'id')).to eq(assignment.id.to_s)
        end

        it 'should return all default fields' do
          assignment
          get :index, params: { course_id: course.id }
          keys = Hash.from_xml(response.body).dig('assignments', 'assignment').keys.map(&:to_sym)
          expect(keys).to match_array Api::AssignmentsController::DEFAULT_FIELDS
        end
      end

      context 'with a single assignment in a different course' do
        it 'should be successful' do
          assignment_different_course
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(:ok)
        end

        it 'should return empty content' do
          assignment_different_course
          get :index, params: { course_id: course.id }
          expect(Hash.from_xml(response.body)['assignments']).to be_nil
        end
      end

      context 'with multiple assignments' do
        it 'should be successful' do
          assignments
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(:ok)
        end

        it 'should return xml content about all assignments' do
          assignments
          get :index, params: { course_id: course.id }
          expect(Hash.from_xml(response.body).dig('assignments', 'assignment').length).to eq(5)
        end

        it 'should return all default fields for all assignments' do
          assignments
          get :index, params: { course_id: course.id }
          keys = Hash.from_xml(response.body).dig('assignments', 'assignment').map { |h| h.keys.map(&:to_sym) }
          expect(keys).to all(match_array(Api::AssignmentsController::DEFAULT_FIELDS))
        end
      end

      context 'with multiple assignments in a different course' do
        it 'should be successful' do
          assignments_different_course
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(:ok)
        end

        it 'should return empty content' do
          assignments_different_course
          get :index, params: { course_id: course.id }
          expect(Hash.from_xml(response.body)['assignments']).to be_nil
        end
      end
    end

    context 'expecting a json response' do
      before do
        request.env['HTTP_ACCEPT'] = 'application/json'
      end

      context 'with a single assignment' do
        it 'should be successful' do
          assignment
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(:ok)
        end

        it 'should return json content' do
          assignment
          get :index, params: { course_id: course.id }
          expect(response.parsed_body&.first&.dig('id')).to eq(assignment.id)
        end

        it 'should return all default fields' do
          assignment
          get :index, params: { course_id: course.id }
          keys = response.parsed_body&.first&.keys&.map(&:to_sym)
          expect(keys).to match_array Api::AssignmentsController::DEFAULT_FIELDS
        end
      end

      context 'with a single assignment in a different course' do
        it 'should be successful' do
          assignment_different_course
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(:ok)
        end

        it 'should return empty content' do
          assignment_different_course
          get :index, params: { course_id: course.id }
          expect(response.parsed_body&.first&.dig('id')).to be_nil
        end
      end

      context 'with multiple assignments' do
        it 'should be successful' do
          assignments
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(:ok)
        end

        it 'should return json content about all assignments' do
          assignments
          get :index, params: { course_id: course.id }
          expect(response.parsed_body.length).to eq(5)
        end

        it 'should return all default fields for all assignments' do
          assignments
          get :index, params: { course_id: course.id }
          keys = response.parsed_body.map { |h| h.keys.map(&:to_sym) }
          expect(keys).to all(match_array(Api::AssignmentsController::DEFAULT_FIELDS))
        end
      end

      context 'with multiple assignments in a different course' do
        it 'should be successful' do
          assignment_different_course
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(:ok)
        end

        it 'should return empty content' do
          assignment_different_course
          get :index, params: { course_id: course.id }
          expect(response.parsed_body).to be_empty
        end
      end
    end
  end

  context 'An unauthenticated request' do
    before do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index, params: { course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a GET show request' do
      get :show, params: { id: assignment.id, course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a POST create request' do
      post :create, params: { course_id: course.id }

      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a PUT update request' do
      put :update, params: { id: assignment.id, course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a DELETE destroy request' do
      delete :destroy, params: { id: assignment.id, course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'An authenticated instructor request requesting' do
    let!(:instructor) { create(:instructor, course: course) }

    before do
      instructor.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{instructor.api_key.strip}"
    end

    context 'GET #index' do
      it_behaves_like 'GET #index'

      context 'with a single hidden assignment' do
        let(:assignment_hidden) { create(:assignment, course: course, is_hidden: true) }

        it 'should be successful' do
          assignment_hidden
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(:ok)
        end

        it 'should return xml content' do
          assignment_hidden
          get :index, params: { course_id: course.id }
          expect(Hash.from_xml(response.body).dig('assignments', 'assignment', 'id')).to eq(assignment_hidden.id.to_s)
        end

        it 'should return all default fields' do
          assignment_hidden
          get :index, params: { course_id: course.id }
          keys = Hash.from_xml(response.body).dig('assignments', 'assignment').keys.map(&:to_sym)
          expect(keys).to match_array Api::AssignmentsController::DEFAULT_FIELDS
        end
      end
    end

    context 'GET show' do
      context 'expecting an xml response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          get :show, params: { id: assignment.id, course_id: course.id }
        end

        it 'should be successful' do
          expect(response).to have_http_status(:ok)
        end

        it 'should return xml content' do
          expect(Hash.from_xml(response.body).dig('assignment', 'id')).to eq(assignment.id.to_s)
        end

        it 'should return all default fields' do
          keys = Hash.from_xml(response.body)['assignment'].keys.map(&:to_sym)
          expect(keys).to match_array Api::AssignmentsController::DEFAULT_FIELDS
        end
      end

      context 'expecting a json response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/json'
          get :show, params: { id: assignment.id, course_id: course.id }
        end

        it 'should be successful' do
          expect(response).to have_http_status(:ok)
        end

        it 'should return json content' do
          expect(response.parsed_body&.dig('id')).to eq(assignment.id)
        end

        it 'should return all default fields' do
          keys = response.parsed_body&.keys&.map(&:to_sym)
          expect(keys).to match_array Api::AssignmentsController::DEFAULT_FIELDS
        end
      end

      context 'requesting a non-existant assignment' do
        it 'should respond with 404' do
          get :show, params: { id: -1, course_id: course.id }
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'requesting an assignment in a different course' do
        let(:assignment) { create(:assignment, course: create(:course)) }

        it 'should response with 403' do
          get :show, params: { id: assignment.id, course_id: assignment.course.id }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'POST create' do
      let(:params) do
        { short_identifier: 'A0', description: 'something', due_date: Time.current, course_id: course.id }
      end
      let(:full_params) do
        { short_identifier: 'A0', message: 'Test Message', course_id: course.id,
          description: 'Test', due_date: '2012-03-26 18:04:39',
          assignment_properties_attributes: {
            tokens_per_period: 13, repository_folder: 'Folder',
            allow_web_submits: false, display_grader_names_to_students: true,
            enable_test: true, assign_graders_to_criteria: true,
            student_form_groups: true, group_name_autogenerated: false,
            submission_rule_deduction: 10, submission_rule_hours: 11,
            submission_rule_interval: 12, remark_due_date: '2012-03-26 18:04:39',
            group_max: 3, submission_rule_type: 'PenaltyDecayPeriod',
            group_min: 2, remark_message: 'Remark',
            allow_remarks: false, non_regenerating_tokens: false,
            unlimited_tokens: false, token_period: 1.0,
            token_start_date: '2012-03-25 18:04:39'
          } }
      end

      context 'with minimal required params' do
        it 'should respond with 201' do
          post :create, params: params
          expect(response).to have_http_status(:created)
        end

        it 'should create an assignment' do
          expect(Assignment.find_by(short_identifier: params[:short_identifier])).to be_nil
          post :create, params: params
          expect(Assignment.find_by(short_identifier: params[:short_identifier])).not_to be_nil
        end

        context 'for a different course' do
          it 'should response with 403' do
            post :create, params: { **params, course_id: create(:course).id }
            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      context 'with all params' do
        it 'should respond with 201' do
          post :create, params: params
          expect(response).to have_http_status(:created)
        end

        it 'should create an assignment' do
          expect(Assignment.find_by(short_identifier: params[:short_identifier])).to be_nil
          post :create, params: params
          expect(Assignment.find_by(short_identifier: params[:short_identifier])).not_to be_nil
        end
      end

      context 'with missing params' do
        context 'missing short_id' do
          it 'should respond with 422' do
            post :create, params: params.slice(:description, :due_date, :course_id)
            expect(response).to have_http_status(:unprocessable_content)
          end

          it 'should not create an assignment' do
            post :create, params: params.slice(:description, :due_date, :course_id)
            expect(Assignment.find_by(description: params[:description])).to be_nil
          end
        end

        context 'missing description' do
          it 'should respond with 404' do
            post :create, params: params.slice(:short_identifier, :due_date, :course_id)
            expect(response).to have_http_status(:unprocessable_content)
          end

          it 'should not create an assignment' do
            post :create, params: params.slice(:short_identifier, :due_date, :course_id)
            expect(Assignment.find_by(short_identifier: params[:short_identifier])).to be_nil
          end
        end

        context 'missing due_date' do
          it 'should respond with 404' do
            post :create, params: params.slice(:short_identifier, :description, :course_id)
            expect(response).to have_http_status(:unprocessable_content)
          end

          it 'should not create an assignment' do
            post :create, params: params.slice(:short_identifier, :description, :course_id)
            expect(Assignment.find_by(short_identifier: params[:short_identifier])).to be_nil
          end
        end
      end

      context 'where short_identifier is already taken' do
        it 'should respond with 409' do
          post :create, params: { **params, short_identifier: create(:assignment, course: course).short_identifier }
          expect(response).to have_http_status(:conflict)
        end
      end

      context 'where due_date is invalid' do
        it 'should respond with 500' do
          post :create, params: { **params, due_date: 'not a real date' }
          expect(response).to have_http_status(:internal_server_error)
        end
      end

      context 'where submission rule is invalid' do
        it 'should respond with 500' do
          post :create, params: { **full_params, submission_rule_interval: 'not a real interval' }
          expect(response).to have_http_status(:internal_server_error)
        end
      end
    end

    context 'PUT update' do
      it 'should update an existing assignment' do
        new_desc = assignment.description + 'more!'
        put :update, params: { id: assignment.id, course_id: course.id, description: new_desc }
        expect(response).to have_http_status(:ok)
      end

      it 'should not update a short identifier' do
        new_short_id = assignment.short_identifier + 'more!'
        put :update, params: { id: assignment.id, course_id: course.id, short_identifier: new_short_id }
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'should not update an assignment that does not exist' do
        new_desc = assignment.description + 'more!'
        put :update, params: { id: -1, course_id: course.id, description: new_desc }
        expect(response).to have_http_status(:not_found)
      end

      context 'for a different course' do
        let(:assignment) { create(:assignment, course: create(:course)) }

        it 'should response with 403' do
          new_desc = assignment.description + 'more!'
          put :update, params: { id: assignment.id, course_id: assignment.course.id, description: new_desc }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'GET test_files' do
      subject { get :test_files, params: { id: assignment.id, course_id: course.id } }

      let(:content) { response.body }

      it_behaves_like 'zip file download'
      it 'should be successful' do
        subject
        expect(response).to have_http_status(:ok)
      end

      context 'for a different course' do
        let(:assignment) { create(:assignment, course: create(:course)) }

        it 'should response with 403' do
          get :test_files, params: { id: assignment.id, course_id: assignment.course.id }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'GET test_specs' do
      let(:set_env) { request.env['HTTP_ACCEPT'] = 'application/json' }

      context 'when the assignment has test settings' do
        let(:content) { { 'a' => 1 } }

        before do
          assignment.update!(autotest_settings: content)
          set_env
          get :test_specs, params: { id: assignment.id, course_id: course.id }
        end

        it 'should get the content of the test spec file' do
          expect(response.body).to eq content.to_json
        end

        it('should be successful') { expect(response).to have_http_status :ok }
      end

      context 'when the assignment has no test settings' do
        before do
          set_env
          get :test_specs, params: { id: assignment.id, course_id: course.id }
        end

        it 'should return an empty hash' do
          expect(response.body).to eq '{}'
        end

        it('should be successful') { expect(response).to have_http_status :ok }
      end

      it 'should fail if the assignment does not exist' do
        get :test_specs, params: { id: -1, course_id: course.id }
        expect(response).to have_http_status :not_found
      end

      context 'for a different course' do
        let(:assignment) { create(:assignment, course: create(:course)) }

        it 'should response with 403' do
          get :test_specs, params: { id: assignment.id, course_id: assignment.course.id }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'POST update_test_specs' do
      context 'when the content is nested parameters' do
        let(:content) { { a: { tester: 'python' }.stringify_keys }.stringify_keys.to_json }

        before do
          allow_any_instance_of(AutotestSpecsJob).to receive(:update_settings)
          post :update_test_specs, params: { id: assignment.id, course_id: course.id, specs: content }
          assignment.reload
        end

        it 'should update the assignment autotest settings' do
          expect(autotest_settings_for(assignment)).to eq JSON.parse(content)
        end

        it('should be successful') { expect(response).to have_http_status :no_content }
      end

      context 'when the content is a json string' do
        let(:content) { { a: { tester: 'python' }.stringify_keys }.stringify_keys.to_json }

        before do
          allow_any_instance_of(AutotestSpecsJob).to receive(:update_settings)
          post :update_test_specs, params: { id: assignment.id, course_id: course.id, specs: JSON.dump(content) }
          assignment.reload
        end

        it 'should update the assignment autotest settings' do
          expect(autotest_settings_for(assignment)).to eq content
        end

        it('should be successful') { expect(response).to have_http_status :no_content }
      end

      context 'when the content is not a json string' do
        let(:content) { 'abcd' }

        before do
          post :update_test_specs, params: { id: assignment.id, course_id: course.id, specs: content }
        end

        it 'should not update the assignment autotest settings' do
          expect(autotest_settings_for(assignment)).to eq({})
        end

        it('should not be successful') { expect(response).to have_http_status :unprocessable_content }
      end

      it 'should fail if the assignment does not exist' do
        post :update_test_specs, params: { id: -1, course_id: course.id, specs: '123' }
        expect(response).to have_http_status :not_found
      end

      context 'for a different course' do
        let(:assignment) { create(:assignment, course: create(:course)) }

        it 'should response with 403' do
          post :update_test_specs, params: { id: assignment.id, course_id: assignment.course.id, specs: '{}' }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'POST submit_file' do
      it 'responds with 403' do
        post :submit_file, params: { id: assignment.id, filename: 'v1/x/y/test.txt', mime_type: 'text',
                                     file_content: 'This is a test file', course_id: course.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'DELETE assignment' do
      it 'should successfully delete assignment because the assignment has no groups' do
        expect(assignment.groups).to be_empty
        delete :destroy, params: { id: assignment.id, course_id: course.id }
        expect(response).to have_http_status(:ok)
        expect(Assignment.exists?(assignment.id)).to be(false)
      end

      it 'fails to delete assignment because assignment has groups' do
        create(:grouping, assignment: assignment, start_time: nil)
        expect(assignment.groups).not_to be_empty
        original_size = Assignment.all.length
        delete :destroy, params: { id: assignment.id, course_id: course.id }
        expect(response).to have_http_status(:conflict)
        expect(Assignment.all.length).to eq(original_size)
        expect(assignment.persisted?).to be(true)
      end

      it 'fails to delete assignment because of invalid id' do
        assignment # since lazy let is used for creating an assignment, it is invoked here to trigger its execution
        original_size = Assignment.all.length
        # Since we only have one assignment, it is guaranteed that assignment.id + 1 is an invalid id
        delete :destroy, params: { id: assignment.id + 1, course_id: course.id }
        expect(response).to have_http_status(:not_found)
        expect(Assignment.all.length).to eq(original_size)
        expect(assignment.persisted?).to be(true)
      end
    end
  end

  context 'An authenticated student request' do
    let(:student) { create(:student, course: course) }

    before do
      student.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{student.api_key.strip}"
    end

    context 'GET #index' do
      it_behaves_like 'GET #index'

      context 'with a single hidden assignment' do
        let(:assignment_hidden) { create(:assignment, course: course, is_hidden: true) }

        it 'should be successful' do
          assignment_hidden
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(:ok)
        end

        it 'should return empty content' do
          assignment_hidden
          get :index, params: { course_id: course.id }
          expect(Hash.from_xml(response.body)['assignments']).to be_nil
        end
      end
    end

    context 'POST submit_file' do
      subject do
        post :submit_file, params: { id: assignment.id, filename: filename, mime_type: 'text',
                                     file_content: 'This is a test file', course_id: course.id }
      end

      let(:student) { create(:grouping_with_inviter, assignment: assignment).inviter }
      let(:filename) { 'v1/x/y/test.txt' }

      before do
        assignment.update(api_submit: true)
      end

      describe 'group creation' do
        context 'when the student is not yet in a group' do
          let(:student) { create(:student, course: course) }

          it 'creates a new group for the student' do
            subject
            expect(student.accepted_groupings.where(assessment_id: assignment.id).first).not_to be_nil
          end

          it 'creates a working alone group' do
            subject
            student_group = student.accepted_groupings.where(assessment_id: assignment.id).first
            expect(student_group.group.group_name).to eq(student.user_name)
          end
        end

        context 'when student is already in a group' do
          it 'does not create a new group for the student' do
            subject
            expect(student.accepted_groupings.where(assessment_id: assignment.id).count).to eq(1)
          end
        end
      end

      describe 'file submission' do
        shared_examples 'submits successfully' do
          it 'responds with 201' do
            subject
            expect(response).to have_http_status(:created)
          end

          it 'submits a file' do
            subject
            path = Pathname.new('v1/x/y')
            submitted_file = nil
            student.accepted_grouping_for(assignment.id).group.access_repo do |repo|
              file_path = Pathname.new(assignment.repository_folder).join path
              files = repo.get_latest_revision.files_at_path(file_path.to_s)
              submitted_file = files.keys.first
            end
            expect(submitted_file).to eq('test.txt')
          end
        end

        shared_examples 'does not submit' do
          it 'does not submit a file' do
            subject
            path = Pathname.new('v1/x/y')
            submitted_file = nil
            student.accepted_grouping_for(assignment.id).group.access_repo do |repo|
              file_path = Pathname.new(assignment.repository_folder).join path
              files = repo.get_latest_revision.files_at_path(file_path.to_s)
              submitted_file = files.keys.first
            end
            expect(submitted_file).to be_nil
          end
        end

        context 'when the file does not exist yet' do
          it_behaves_like 'submits successfully'
        end

        context 'when the file already exists' do
          it 'replaces the file' do
            subject
            expected_content = 'Updated Content'
            post :submit_file, params: { id: assignment.id, filename: 'v1/x/y/test.txt', mime_type: 'text',
                                         file_content: expected_content, course_id: course.id }
            received_file_content = nil
            path = Pathname.new('v1/x/y')
            student.accepted_grouping_for(assignment.id).group.access_repo do |repo|
              file_path = Pathname.new(assignment.repository_folder).join path
              file = repo.get_latest_revision.files_at_path(file_path.to_s)['test.txt']
              received_file_content = repo.download_as_string(file)
            end
            expect(received_file_content).to eq(expected_content)
          end
        end

        context 'when the instructor has disabled API submission' do
          before do
            assignment.update(api_submit: false)
          end

          it 'responds with 403' do
            subject
            expect(response).to have_http_status(:forbidden)
          end

          it_behaves_like 'does not submit'
        end

        context 'when the assignment is hidden' do
          before do
            assignment.update(is_hidden: true)
          end

          it 'responds with 403' do
            subject
            expect(response).to have_http_status(:forbidden)
          end

          it_behaves_like 'does not submit'
        end

        context 'when the assignment requires submission of only required files' do
          before do
            assignment.update(only_required_files: true)
          end

          context 'the file is not required' do
            before { create(:assignment_file, assessment_id: assignment.id) }

            it 'responds with 422' do
              subject
              expect(response).to have_http_status(:unprocessable_content)
            end

            it_behaves_like 'does not submit'
          end

          context 'the file is required' do
            before { create(:assignment_file, filename: 'v1/x/y/test.txt', assessment_id: assignment.id) }

            it_behaves_like 'submits successfully'
          end
        end

        context 'when the filename is invalid' do
          let(:filename) { '../hello' }

          it 'responds with 422' do
            subject
            expect(response).to have_http_status(:unprocessable_content)
          end

          it 'does not create a temporary file' do
            expect(Tempfile).not_to receive(:new)
            subject
          end
        end
      end
    end

    context 'DELETE destroy' do
      it 'should fail to authenticate a DELETE destroy request' do
        delete :destroy, params: { id: assignment.id, course_id: course.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context 'An authenticated ta request' do
    let!(:ta) { create(:ta, course: course) }

    before do
      ta.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{ta.api_key.strip}"
    end

    context 'GET #index' do
      it_behaves_like 'GET #index'

      context 'with a single hidden assignment' do
        let(:assignment_hidden) { create(:assignment, course: course, is_hidden: true) }

        it 'should be successful' do
          assignment_hidden
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(:ok)
        end

        it 'should return xml content' do
          assignment_hidden
          get :index, params: { course_id: course.id }
          expect(Hash.from_xml(response.body).dig('assignments', 'assignment', 'id')).to eq(assignment_hidden.id.to_s)
        end

        it 'should return all default fields' do
          assignment_hidden
          get :index, params: { course_id: course.id }
          keys = Hash.from_xml(response.body).dig('assignments', 'assignment').keys.map(&:to_sym)
          expect(keys).to match_array Api::AssignmentsController::DEFAULT_FIELDS
        end
      end
    end

    context 'DELETE destroy' do
      it 'should fail to authenticate a DELETE destroy request' do
        delete :destroy, params: { id: assignment.id, course_id: course.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
