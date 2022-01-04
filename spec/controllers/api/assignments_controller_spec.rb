describe Api::AssignmentsController do
  let(:course) { create :course }
  let(:assignment) { create :assignment, course: course }
  context 'An unauthenticated request' do
    before :each do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index, params: { course_id: course.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a GET show request' do
      get :show, params: { id: assignment.id, course_id: course.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a POST create request' do
      post :create, params: { course_id: course.id }

      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a PUT update request' do
      put :update, params: { id: assignment.id, course_id: course.id }
      expect(response).to have_http_status(403)
    end
  end
  context 'An authenticated request requesting' do
    before :each do
      instructor = create :instructor, course: course
      instructor.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{instructor.api_key.strip}"
    end

    context 'GET index' do
      context 'expecting an xml response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/xml'
        end
        context 'with a single assignment' do
          before :each do
            assignment
            get :index, params: { course_id: course.id }
          end
          it 'should be successful' do
            expect(response.status).to eq(200)
          end
          it 'should return xml content' do
            expect(Hash.from_xml(response.body).dig('assignments', 'assignment', 'id')).to eq(assignment.id.to_s)
          end
          it 'should return all default fields' do
            keys = Hash.from_xml(response.body).dig('assignments', 'assignment').keys.map(&:to_sym).sort
            expect(keys).to eq(Api::AssignmentsController::DEFAULT_FIELDS.sort)
          end
        end
        context 'with a single assignment in a different course' do
          before do
            create :assignment, course: create(:course)
            get :index, params: { course_id: course.id }
          end
          it 'should be successful' do
            expect(response.status).to eq(200)
          end
          it 'should return empty content' do
            expect(Hash.from_xml(response.body)['assignments']).to be_nil
          end
        end
        context 'with multiple assignments' do
          before :each do
            5.times { create :assignment, course: course }
            get :index, params: { course_id: course.id }
          end
          it 'should return xml content about all assignments' do
            expect(Hash.from_xml(response.body).dig('assignments', 'assignment').length).to eq(5)
          end
          it 'should return all default fields for all assignments' do
            keys = Hash.from_xml(response.body).dig('assignments', 'assignment').map { |h| h.keys.map(&:to_sym).sort }
            expect(keys).to all(eq(Api::AssignmentsController::DEFAULT_FIELDS.sort))
          end
        end
        context 'with multiple assignments in a different course' do
          before :each do
            create_list :assignment, 5, course: create(:course)
            get :index, params: { course_id: course.id }
          end
          it 'should be successful' do
            expect(response.status).to eq(200)
          end
          it 'should return empty content' do
            expect(Hash.from_xml(response.body)['assignments']).to be_nil
          end
        end
      end
      context 'expecting a json response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/json'
        end
        context 'with a single assignment' do
          before :each do
            assignment
            get :index, params: { course_id: course.id }
          end
          it 'should be successful' do
            expect(response.status).to eq(200)
          end
          it 'should return json content' do
            expect(JSON.parse(response.body)&.first&.dig('id')).to eq(assignment.id)
          end
          it 'should return all default fields' do
            keys = JSON.parse(response.body)&.first&.keys&.map(&:to_sym)&.sort
            expect(keys).to eq(Api::AssignmentsController::DEFAULT_FIELDS.sort)
          end
        end
        context 'with a single assignment in a different course' do
          before do
            create :assignment, course: create(:course)
            get :index, params: { course_id: course.id }
          end
          it 'should be successful' do
            expect(response.status).to eq(200)
          end
          it 'should return empty content' do
            expect(JSON.parse(response.body)&.first&.dig('id')).to be_nil
          end
        end
        context 'with multiple assignments' do
          before :each do
            5.times { create :assignment, course: course }
            get :index, params: { course_id: course.id }
          end
          it 'should return xml content about all assignments' do
            expect(JSON.parse(response.body).length).to eq(5)
          end
          it 'should return all default fields for all assignments' do
            keys = JSON.parse(response.body).map { |h| h.keys.map(&:to_sym).sort }
            expect(keys).to all(eq(Api::AssignmentsController::DEFAULT_FIELDS.sort))
          end
        end
        context 'with a multiple assignments in a different course' do
          before do
            create_list :assignment, 5, course: create(:course)
            get :index, params: { course_id: course.id }
          end
          it 'should be successful' do
            expect(response.status).to eq(200)
          end
          it 'should return empty content' do
            expect(JSON.parse(response.body)&.first&.dig('id')).to be_nil
          end
        end
      end
    end
    context 'GET show' do
      context 'expecting an xml response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          get :show, params: { id: assignment.id, course_id: course.id }
        end
        it 'should be successful' do
          expect(response.status).to eq(200)
        end
        it 'should return xml content' do
          expect(Hash.from_xml(response.body).dig('assignment', 'id')).to eq(assignment.id.to_s)
        end
        it 'should return all default fields' do
          keys = Hash.from_xml(response.body)['assignment'].keys.map(&:to_sym).sort
          expect(keys).to eq(Api::AssignmentsController::DEFAULT_FIELDS.sort)
        end
      end
      context 'expecting a json response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/json'
          get :show, params: { id: assignment.id, course_id: course.id }
        end
        it 'should be successful' do
          expect(response.status).to eq(200)
        end
        it 'should return json content' do
          expect(JSON.parse(response.body)&.dig('id')).to eq(assignment.id)
        end
        it 'should return all default fields' do
          keys = JSON.parse(response.body)&.keys&.map(&:to_sym)&.sort
          expect(keys).to eq(Api::AssignmentsController::DEFAULT_FIELDS.sort)
        end
      end
      context 'requesting a non-existant assignment' do
        it 'should respond with 404' do
          get :show, params: { id: -1, course_id: course.id }
          expect(response.status).to eq(404)
        end
      end
      context 'requesting an assignment in a different course' do
        let(:assignment) { create :assignment, course: create(:course) }
        it 'should response with 403' do
          get :show, params: { id: assignment.id, course_id: assignment.course.id }
          expect(response.status).to eq(403)
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
          expect(response.status).to eq(201)
        end
        it 'should create an assignment' do
          expect(Assignment.find_by_short_identifier(params[:short_identifier])).to be_nil
          post :create, params: params
          expect(Assignment.find_by_short_identifier(params[:short_identifier])).not_to be_nil
        end
        context 'for a different course' do
          it 'should response with 403' do
            post :create, params: { **params, course_id: create(:course).id }
            expect(response.status).to eq(403)
          end
        end
      end
      context 'with all params' do
        it 'should respond with 201' do
          post :create, params: params
          expect(response.status).to eq(201)
        end
        it 'should create an assignment' do
          expect(Assignment.find_by_short_identifier(params[:short_identifier])).to be_nil
          post :create, params: params
          expect(Assignment.find_by_short_identifier(params[:short_identifier])).not_to be_nil
        end
      end
      context 'with missing params' do
        context 'missing short_id' do
          it 'should respond with 422' do
            post :create, params: params.slice(:description, :due_date, :course_id)
            expect(response.status).to eq(422)
          end
          it 'should not create an assignment' do
            post :create, params: params.slice(:description, :due_date, :course_id)
            expect(Assignment.find_by_description(params[:description])).to be_nil
          end
        end
        context 'missing description' do
          it 'should respond with 404' do
            post :create, params: params.slice(:short_identifier, :due_date, :course_id)
            expect(response.status).to eq(422)
          end
          it 'should not create an assignment' do
            post :create, params: params.slice(:short_identifier, :due_date, :course_id)
            expect(Assignment.find_by_short_identifier(params[:short_identifier])).to be_nil
          end
        end
        context 'missing due_date' do
          it 'should respond with 404' do
            post :create, params: params.slice(:short_identifier, :description, :course_id)
            expect(response.status).to eq(422)
          end
          it 'should not create an assignment' do
            post :create, params: params.slice(:short_identifier, :description, :course_id)
            expect(Assignment.find_by_short_identifier(params[:short_identifier])).to be_nil
          end
        end
      end
      context 'where short_identifier is already taken' do
        it 'should respond with 409' do
          post :create, params: { **params, short_identifier: (create :assignment, course: course).short_identifier }
          expect(response.status).to eq(409)
        end
      end
      context 'where due_date is invalid' do
        it 'should respond with 500' do
          post :create, params: { **params, due_date: 'not a real date' }
          expect(response.status).to eq(500)
        end
      end
      context 'where submission rule is invalid' do
        it 'should respond with 500' do
          post :create, params: { **full_params, submission_rule_interval: 'not a real interval' }
          expect(response.status).to eq(500)
        end
      end
    end
    context 'PUT update' do
      it 'should update an existing assignment' do
        new_desc = assignment.description + 'more!'
        put :update, params: { id: assignment.id, course_id: course.id, description: new_desc }
        expect(response.status).to eq(200)
      end
      it 'should not update a short identifier' do
        new_short_id = assignment.short_identifier + 'more!'
        put :update, params: { id: assignment.id, course_id: course.id, short_identifier: new_short_id }
        expect(response.status).to eq(500)
      end
      it 'should not update an assignment that does not exist' do
        new_desc = assignment.description + 'more!'
        put :update, params: { id: -1, course_id: course.id, description: new_desc }
        expect(response.status).to eq(404)
      end
      context 'for a different course' do
        let(:assignment) { create :assignment, course: create(:course) }
        it 'should response with 403' do
          new_desc = assignment.description + 'more!'
          put :update, params: { id: assignment.id, course_id: assignment.course.id, description: new_desc }
          expect(response.status).to eq(403)
        end
      end
    end
    context 'GET test_files' do
      subject { get :test_files, params: { id: assignment.id, course_id: course.id } }
      let(:content) { response.body }
      it_behaves_like 'zip file download'
      it 'should be successful' do
        subject
        expect(response.status).to eq(200)
      end
      context 'for a different course' do
        let(:assignment) { create :assignment, course: create(:course) }
        it 'should response with 403' do
          get :test_files, params: { id: assignment.id, course_id: assignment.course.id }
          expect(response.status).to eq(403)
        end
      end
    end
    context 'GET test_specs' do
      let(:set_env) { request.env['HTTP_ACCEPT'] = 'application/json' }
      context 'when a spec file exists' do
        let(:content) { '{"a":1}' }
        before :each do
          FileUtils.mkdir_p assignment.autotest_path
          File.write(assignment.autotest_settings_file, content)
          set_env
          get :test_specs, params: { id: assignment.id, course_id: course.id }
        end
        it 'should get the content of the test spec file' do
          expect(response.body).to eq content
        end
        it('should be successful') { expect(response.status).to eq 200 }
      end
      context 'when a spec file does not exists' do
        before :each do
          FileUtils.rm_f(assignment.autotest_settings_file)
          set_env
          get :test_specs, params: { id: assignment.id, course_id: course.id }
        end
        it 'should return an empty hash' do
          expect(response.body).to eq '{}'
        end
        it('should be successful') { expect(response.status).to eq 200 }
      end
      it 'should fail if the assignment does not exist' do
        get :test_specs, params: { id: -1, course_id: course.id }
        expect(response.status).to eq 404
      end
      context 'for a different course' do
        let(:assignment) { create :assignment, course: create(:course) }
        it 'should response with 403' do
          get :test_specs, params: { id: assignment.id, course_id: assignment.course.id }
          expect(response.status).to eq(403)
        end
      end
    end
    context 'POST update_test_specs' do
      before :each do
        FileUtils.mkdir_p assignment.autotest_path
        File.write(assignment.autotest_settings_file, '')
      end
      context 'when the content is nested parameters' do
        let(:content) { { a: { tester: 'python' }.stringify_keys }.stringify_keys }
        before :each do
          allow_any_instance_of(AutotestSpecsJob).to receive(:perform_now)
          post :update_test_specs, params: { id: assignment.id, course_id: course.id, specs: content }
        end
        it 'should write the content to the specs file' do
          expect(JSON.parse(File.read(assignment.autotest_settings_file))).to eq content
        end
        it('should be successful') { expect(response.status).to eq 204 }
      end
      context 'when the content is a json string' do
        let(:content) { { a: { tester: 'python' }.stringify_keys }.stringify_keys }
        before :each do
          allow_any_instance_of(AutotestSpecsJob).to receive(:perform_now)
          post :update_test_specs, params: { id: assignment.id, course_id: course.id, specs: JSON.dump(content) }
        end
        it 'should write the content to the specs file' do
          expect(JSON.parse(File.read(assignment.autotest_settings_file))).to eq content
        end
        it('should be successful') { expect(response.status).to eq 204 }
      end
      context 'when the content is not a json string' do
        let(:content) { 'abcd' }
        before :each do
          post :update_test_specs, params: { id: assignment.id, course_id: course.id, specs: content }
        end
        it 'should write the content to the specs file' do
          expect(File.read(assignment.autotest_settings_file)).to eq ''
        end
        it('should not be successful') { expect(response.status).to eq 422 }
      end
      it 'should fail if the assignment does not exist' do
        post :update_test_specs, params: { id: -1, course_id: course.id, specs: '123' }
        expect(response.status).to eq 404
      end
      context 'for a different course' do
        let(:assignment) { create :assignment, course: create(:course) }
        it 'should response with 403' do
          post :update_test_specs, params: { id: assignment.id, course_id: assignment.course.id, specs: '{}' }
          expect(response.status).to eq(403)
        end
      end
    end
  end
end
