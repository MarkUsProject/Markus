describe Api::FeedbackFilesController do
  let(:course) { create(:course) }
  let(:instructor) { create(:instructor, course: course) }
  let(:assignment) { create(:assignment, course: course) }
  let(:grouping) { create(:grouping_with_inviter_and_submission, assignment: assignment) }
  let(:feedback_files) { create_list(:feedback_file, 3, submission: grouping.submissions.first) }
  let(:test_group_result) { create(:test_group_result) }
  let(:feedback_files_with_test_run) do
    create_list(:feedback_file_with_test_run, 3, test_group_result: test_group_result)
  end

  context 'An unauthenticated request' do
    before do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index, params: { assignment_id: grouping.assignment.id, group_id: grouping.group.id, course_id: course.id }
      expect(response).to have_http_status :forbidden
    end

    it 'should fail to authenticate a GET show request' do
      get :show, params: { id: feedback_files.first.id, course_id: course.id }
      expect(response).to have_http_status :forbidden
    end

    it 'should fail to authenticate a POST create request' do
      post :create, params: { assignment_id: grouping.assignment.id, group_id: grouping.group.id, course_id: course.id }
      expect(response).to have_http_status :forbidden
    end

    it 'should fail to authenticate a PUT update request' do
      put :update, params: { id: feedback_files.first.id, course_id: course.id }
      expect(response).to have_http_status :forbidden
    end

    it 'should fail to authenticate a DELETE destroy request' do
      delete :destroy, params: { id: feedback_files.first.id, course_id: course.id }
      expect(response).to have_http_status :forbidden
    end
  end

  context 'An authenticated request' do
    before do
      instructor.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{instructor.api_key.strip}"
    end

    context 'GET index' do
      context 'expecting an xml response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          feedback_files
        end

        it 'should be successful if required parameters are present' do
          get :index, params: {
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id,
            course_id: course.id
          }
          expect(response).to have_http_status :success
        end

        it 'should return info about feedback files if grouping_id and assignment_id are specified' do
          get :index, params: {
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id,
            course_id: course.id
          }
          ids = Hash.from_xml(response.body).dig('feedback_files', 'feedback_file').map { |h| h['id'].to_i }
          expect(ids).to match_array(feedback_files.pluck(:id)) # rubocop:disable Rails/PluckId
        end
      end

      context 'expecting an json response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/json'
          feedback_files
        end

        it 'should be successful if required parameters are present' do
          get :index, params: {
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id,
            course_id: course.id
          }
          expect(response).to have_http_status :success
        end

        it 'should return info about feedback files if grouping_id and assignment_id are specified' do
          get :index, params: {
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id,
            course_id: course.id
          }
          expect(
            response.parsed_body.pluck('id')
          ).to match_array(feedback_files.pluck(:id)) # rubocop:disable Rails/PluckId
        end
      end

      context 'when feedback files with no submission exist' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/json'
          feedback_files
          feedback_files_with_test_run
        end

        it 'should not return info about feedback files if not related to the submission' do
          get :index, params: {
            group_id: grouping.group.id,
            assignment_id: grouping.assignment.id,
            course_id: course.id
          }
          expect(
            response.parsed_body.pluck('id')
          ).not_to include(*feedback_files_with_test_run.pluck(:id)) # rubocop:disable Rails/PluckId
        end
      end
    end

    context 'GET show' do
      context 'expecting an xml response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          get :show, params: { id: feedback_files.first.id, course_id: course.id }
        end

        it 'should be successful' do
          expect(response).to have_http_status :success
        end

        it 'should return the file content' do
          expect(response.body).to eq(feedback_files.first.file_content)
        end
      end

      context 'expecting an json response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/json'
          get :show, params: { id: feedback_files.first.id, course_id: course.id }
        end

        it 'should be successful' do
          expect(response).to have_http_status :success
        end

        it 'should return the file content' do
          expect(response.body).to eq(feedback_files.first.file_content)
        end
      end
    end

    context 'POST create' do
      let(:filename) { 'helloworld.txt' }

      context 'when creating a new feedback_file' do
        it 'should be successful' do
          post :create, params: { group_id: grouping.group.id, assignment_id: grouping.assignment.id,
                                  filename: filename, mime_type: 'text/plain', file_content: 'abcd',
                                  course_id: course.id }
          expect(response).to have_http_status :created
        end

        it 'should create a new feedback_file' do
          post :create, params: { group_id: grouping.group.id, assignment_id: grouping.assignment.id,
                                  filename: filename, mime_type: 'text/plain', file_content: 'abcd',
                                  course_id: course.id }
          expect(FeedbackFile.find_by(filename: filename)).not_to be_nil
        end
      end

      context 'when trying to create a feedback_file with a name that already exists' do
        it 'should raise a 409 error' do
          post :create, params: { group_id: grouping.group.id, assignment_id: grouping.assignment.id,
                                  filename: feedback_files.first.filename, mime_type: 'text/plain',
                                  file_content: 'a', course_id: course.id }
          expect(response).to have_http_status :conflict
        end
      end

      context 'when trying to create a feedback file larger than the course size limit' do
        let(:file_content) { SecureRandom.alphanumeric(course.max_file_size + 10) }

        before do
          course.update!(max_file_size: 1000)
        end

        it 'should raise a 413 error' do
          post :create, params: { group_id: grouping.group.id, assignment_id: grouping.assignment.id,
                                  filename: filename, mime_type: 'text/plain',
                                  file_content: file_content, course_id: course.id }
          expect(response).to have_http_status :payload_too_large
        end
      end
    end

    context 'PUT update' do
      let(:feedback_file) { feedback_files.first }

      context 'when updating an existing feedback_file' do
        it 'should update a filename' do
          put :update, params: { group_id: grouping.group.id, assignment_id: grouping.assignment.id,
                                 id: feedback_file.id, filename: 'abc.txt', file_content: 'def main(): pass',
                                 course_id: course.id }
          expect(response).to have_http_status :success
          feedback_file.reload
          expect(feedback_file.filename).to eq('abc.txt')
        end

        it 'should update file content' do
          put :update, params: { group_id: grouping.group.id, assignment_id: grouping.assignment.id,
                                 id: feedback_file.id, file_content: 'def main(): pass', course_id: course.id }
          expect(response).to have_http_status :success
          feedback_file.reload
          expect(feedback_file.file_content).to eq('def main(): pass')
        end
      end

      context 'when updating a user that does not exist' do
        it 'should raise a 404 error' do
          put :update, params: { group_id: grouping.group.id, assignment_id: grouping.assignment.id,
                                 id: feedback_file.id + 100, filename: 'abc.txt', course_id: course.id }
          expect(response).to have_http_status :not_found
        end
      end
    end
  end
end
