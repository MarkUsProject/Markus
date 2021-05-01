describe Api::FeedbackFilesController do
  let(:admin) { create :admin }
  let(:grouping) { create :grouping_with_inviter_and_submission }
  let(:feedback_files) { create_list :feedback_file, 3, submission: grouping.submissions.first }
  let(:test_run) { create :test_run, grouping: grouping, user: admin }
  let(:feedback_files_with_test_run) { create_list :feedback_file_with_test_run, 3, test_run: test_run }

  context 'An unauthenticated request' do
    before :each do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index, params: { assignment_id: grouping.assignment.id, group_id: grouping.group.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a GET show request' do
      get :show, params: { id: 1, assignment_id: grouping.assignment.id, group_id: grouping.group.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a POST create request' do
      post :create, params: { assignment_id: grouping.assignment.id, group_id: grouping.group.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a PUT update request' do
      put :create, params: { id: 1, assignment_id: grouping.assignment.id, group_id: grouping.group.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a DELETE destroy request' do
      delete :destroy, params: { id: 1, assignment_id: grouping.assignment.id, group_id: grouping.group.id }
      expect(response).to have_http_status(403)
    end
  end

  context 'An authenticated request' do
    before :each do
      admin.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{admin.api_key.strip}"
    end

    context 'GET index' do
      context 'expecting an xml response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          feedback_files
          feedback_files_with_test_run
        end
        it 'should be successful if required parameters are present' do
          get :index, params: {
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id
          }
          expect(response.status).to eq(200)
        end
        it 'should return info about feedback files if grouping_id and assignment_id are specified' do
          get :index, params: {
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id
          }
          ids = Hash.from_xml(response.body).dig('feedback_files', 'feedback_file').map { |h| h['id'].to_i }
          expect(ids).to contain_exactly(*feedback_files.pluck(:id))
        end
        it 'should return info about feedback files if test_run_id is additionally specified' do
          get :index, params: {
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id,
            test_run_id: test_run.id
          }
          ids = Hash.from_xml(response.body).dig('feedback_files', 'feedback_file').map { |h| h['id'].to_i }
          expect(ids).to contain_exactly(*feedback_files_with_test_run.pluck(:id))
        end
      end
      context 'expecting an json response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/json'
          feedback_files
          feedback_files_with_test_run
        end
        it 'should be successful if required parameters are present' do
          get :index, params: {
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id
          }
          expect(response.status).to eq(200)
        end
        it 'should return info about feedback files if grouping_id and assignment_id are specified' do
          get :index, params: {
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id
          }
          expect(JSON.parse(response.body).map { |h| h['id'] }).to contain_exactly(*feedback_files.pluck(:id))
        end
        it 'should return info about feedback files if test_run_id is additionally specified' do
          get :index, params: {
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id,
            test_run_id: test_run.id
          }
          expected_ids = feedback_files_with_test_run.pluck(:id)
          expect(JSON.parse(response.body).map { |h| h['id'] }).to contain_exactly(*expected_ids)
        end
      end
    end

    context 'GET show' do
      context 'expecting an xml response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/xml'
        end
        it 'should be successful' do
          get :show, params: {
            id: feedback_files.first.id,
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id
          }
          expect(response.status).to eq(200)
        end
        it 'should return the file content' do
          get :show, params: {
            id: feedback_files.first.id,
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id
          }
          expect(response.body).to eq(feedback_files.first.file_content)
        end
        it 'should return the file content when test_run_id is additionally specified' do
          get :show, params: {
            id: feedback_files_with_test_run.first.id,
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id,
            test_run_id: test_run.id
          }
          expect(response.body).to eq(feedback_files_with_test_run.first.file_content)
        end
      end
      context 'expecting an json response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/json'
        end
        it 'should be successful' do
          get :show, params: {
            id: feedback_files.first.id,
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id
          }
          expect(response.status).to eq(200)
        end
        it 'should return the file content' do
          get :show, params: {
            id: feedback_files.first.id,
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id
          }
          expect(response.body).to eq(feedback_files.first.file_content)
        end
        it 'should return the file content when test_run_id is additionally specified' do
          get :show, params: {
            id: feedback_files_with_test_run.first.id,
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id,
            test_run_id: test_run.id
          }
          expect(response.body).to eq(feedback_files_with_test_run.first.file_content)
        end
      end
    end

    context 'POST create' do
      let(:filename) { 'helloworld.txt' }
      context 'when creating a new feedback_file' do
        it 'should be successful' do
          post :create, params: { group_id: grouping.group.id, assignment_id: grouping.assignment.id,
                                  filename: filename, mime_type: 'text/plain', file_content: 'abcd' }
          expect(response.status).to eq(201)
        end
        it 'should create a new feedback_file' do
          post :create, params: { group_id: grouping.group.id, assignment_id: grouping.assignment.id,
                                  filename: filename, mime_type: 'text/plain', file_content: 'abcd' }
          expect(FeedbackFile.find_by_filename(filename)).not_to be_nil
        end
      end
      context 'when trying to create a feedback_file with a name that already exists' do
        it 'should raise a 409 error' do
          post :create, params: { group_id: grouping.group.id, assignment_id: grouping.assignment.id,
                                  filename: feedback_files.first.filename, mime_type: 'text/plain', file_content: 'a' }
          expect(response.status).to eq(409)
        end
      end
    end

    context 'PUT update' do
      let(:feedback_file) { feedback_files.first }
      context 'when updating an existing feedback_file' do
        it 'should update a filename' do
          put :update, params: { group_id: grouping.group.id, assignment_id: grouping.assignment.id,
                                 id: feedback_file.id, filename: 'abc.txt', file_content: 'def main(): pass' }
          expect(response.status).to eq(200)
          feedback_file.reload
          expect(feedback_file.filename).to eq('abc.txt')
        end
        it 'should update file content' do
          put :update, params: { group_id: grouping.group.id, assignment_id: grouping.assignment.id,
                                 id: feedback_file.id, file_content: 'def main(): pass' }
          expect(response.status).to eq(200)
          feedback_file.reload
          expect(feedback_file.file_content).to eq('def main(): pass')
        end
      end
      context 'when updating a user that does not exist' do
        it 'should raise a 404 error' do
          put :update, params: { group_id: grouping.group.id, assignment_id: grouping.assignment.id,
                                 id: feedback_file.id + 100, filename: 'abc.txt' }
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
