describe Api::SubmissionFilesController do
  let(:course) { create(:course) }
  let(:assignment) { create(:assignment, course: course) }
  let(:grouping) { create(:grouping_with_inviter, assignment: assignment) }
  let(:group) { grouping.group }
  let(:file_content) { Array.new(2) { Faker::TvShows::HeyArnold.quote } }
  let(:file_names) { Array.new(2) { Faker::File.file_name(dir: '') } }
  let(:instructor) { create(:instructor, course: course) }

  shared_examples 'for a different course' do
    context 'instructor in a different course' do
      let(:instructor) { create(:instructor, course: create(:course)) }

      it 'should return a 403 error' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context 'An unauthenticated request' do
    before do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index, params: { assignment_id: assignment.id, group_id: group.id, course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a POST create request' do
      post :create, params: { assignment_id: assignment.id, group_id: group.id, course_id: course.id }

      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a PUT update request' do
      put :create, params: { assignment_id: assignment.id, group_id: group.id, course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'An authenticated request' do
    before do
      instructor.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{instructor.api_key.strip}"
      group.access_repo do |repo|
        txn = repo.get_transaction(grouping.inviter.user_name)
        file_content.each_with_index do |content, i|
          filepath = File.join(assignment.repository_folder, file_names[i])
          txn.add(filepath, content)
        end
        repo.commit(txn)
        Submission.generate_new_submission(grouping, repo.get_latest_revision)
      end
    end

    context 'POST create' do
      context 'when the file does not exist yet' do
        let(:filename) { 'v1/x/y/test.txt' }
        let(:content) { 'This is a test file' }
        let(:mime_type) { 'text/plain' }

        before do
          post :create, params: { assignment_id: assignment.id, group_id: group.id, filename: filename,
                                  mime_type: mime_type, file_content: content, course_id: course.id }
        end

        context 'when the file is plaintext' do
          it 'should create the file in the corresponding directory' do
            path = Pathname.new('v1/x/y')
            success, _messages = group.access_repo do |repo|
              file_path = Pathname.new(assignment.repository_folder).join path
              files = repo.get_latest_revision.files_at_path(file_path.to_s)
              files.key? File.basename(filename)
            end
            expect(success).to be_truthy
          end
        end

        context 'when the file is binary' do
          let(:filename) { 'v1/x/y/test.pdf' }
          let(:content) { file_fixture('submission_files/pdf.pdf') }
          let(:mime_type) { 'application/pdf' }

          it 'should create the file in the corresponding directory' do
            path = Pathname.new('v1/x/y')
            success, _messages = group.access_repo do |repo|
              file_path = Pathname.new(assignment.repository_folder).join path
              files = repo.get_latest_revision.files_at_path(file_path.to_s)
              files.key? File.basename(filename)
            end
            expect(success).to be_truthy
          end
        end

        it_behaves_like 'for a different course'
      end

      context 'when adding a file which is already exist' do
        before do
          post :create, params: { assignment_id: assignment.id, group_id: group.id,
                                  filename: 'v1/x/y/test.txt', mime_type: 'text',
                                  file_content: 'This is an updated test file', course_id: course.id }
        end

        it 'should replace the old file with the new one' do
          path = Pathname.new('v1/x/y')
          file_contents = ''
          group.access_repo do |repo|
            file_path = Pathname.new(assignment.repository_folder).join path
            file = repo.get_latest_revision.files_at_path(file_path.to_s)['test.txt']
            file_contents = repo.download_as_string(file)
          end
          content = 'This is an updated test file'
          expect(content).to eq(file_contents)
        end

        it_behaves_like 'for a different course'
      end
    end

    context 'POST create_folders' do
      before do
        post :create_folders, params: { assignment_id: assignment.id,
                                        group_id: group.id,
                                        folder_path: 'a/b/c',
                                        course_id: course.id }
      end

      it 'should be successful' do
        expect(response).to have_http_status(:created)
      end

      it 'should create folders in the corresponding directory' do
        path = Pathname.new('a/b/c')
        success, _messages = group.access_repo do |repo|
          file_path = Pathname.new(assignment.repository_folder).join path
          repo.get_latest_revision.path_exists?(file_path.to_s)
        end
        expect(success).to be_truthy
      end

      it_behaves_like 'for a different course'
      context 'when the folder is already exist' do
        before do
          post :create_folders, params: { assignment_id: assignment.id,
                                          group_id: group.id,
                                          folder_path: 'a/b/c',
                                          course_id: course.id }
        end

        it 'should return 500 error' do
          expect(response).to have_http_status(:internal_server_error)
        end
      end
    end

    context 'DELETE remove_file' do
      before do
        post :create, params: { assignment_id: assignment.id, group_id: group.id, filename: 'v1/x/y/test.txt',
                                mime_type: 'text', file_content: 'This is a test file', course_id: course.id }
      end

      describe 'when the file exists' do
        before do
          delete :remove_file, params: { assignment_id: assignment.id,
                                         group_id: group.id,
                                         filename: 'v1/x/y/test.txt',
                                         course_id: course.id }
        end

        it 'should remove the file' do
          path = Pathname.new('v1/x/y/test.txt')
          success, _messages = group.access_repo do |repo|
            folder_path = Pathname.new(assignment.repository_folder).join path
            repo.get_latest_revision.path_exists?(folder_path.to_s)
          end
          expect(success).to be_falsey
          expect(response).to have_http_status(:ok)
        end

        it_behaves_like 'for a different course'
      end

      describe 'when the file does not exist' do
        before do
          delete :remove_file, params: { assignment_id: assignment.id,
                                         group_id: group.id,
                                         filename: 'v1/x/y/task.txt',
                                         course_id: course.id }
        end

        it 'should return 500 error' do
          expect(response).to have_http_status(:internal_server_error)
        end

        it_behaves_like 'for a different course'
      end
    end

    context 'DELETE remove_folders' do
      before do
        post :create_folders, params: { assignment_id: assignment.id, group_id: group.id,
                                        folder_path: 'a/b/c', course_id: course.id }
      end

      describe 'when the folder exists' do
        before do
          delete :remove_folder, params: { assignment_id: assignment.id, group_id: group.id,
                                           folder_path: 'a/b/c', course_id: course.id }
        end

        it 'should remove the folders and its content' do
          path = Pathname.new('a/b/c')
          success, _messages = group.access_repo do |repo|
            folder_path = Pathname.new(assignment.repository_folder).join path
            repo.get_latest_revision.path_exists?(folder_path.to_s)
          end
          expect(success).to be_falsey
          expect(response).to have_http_status(:ok)
        end

        it_behaves_like 'for a different course'
      end

      describe 'when the folder does not exist' do
        before do
          delete :remove_folder, params: { assignment_id: assignment.id, group_id: group.id,
                                           folder_path: 'a/b/x', course_id: course.id }
        end

        it 'should return 500 error' do
          expect(response).to have_http_status(:internal_server_error)
        end
      end
    end

    context 'GET index' do
      let(:aid) { assignment.id }
      let(:gid) { group.id }
      let(:file_name) { nil }

      before do
        get :index, params: { assignment_id: aid, group_id: gid, filename: file_name, course_id: course.id }
      end

      it_behaves_like 'for a different course'
      context 'when no specific file is selected' do
        it 'should be successful' do
          expect(response).to have_http_status(:ok)
        end

        it 'should return a zip containing both files' do
          files = 0
          Zip::InputStream.open(StringIO.new(response.body)) do |io|
            while (entry = io.get_next_entry)
              files += 1 unless entry.name_is_directory?
            end
          end
          expect(files).to eq 2
        end

        it 'should return a zip with the content of both files' do
          content = []
          Zip::InputStream.open(StringIO.new(response.body)) do |io|
            while (entry = io.get_next_entry)
              content << io.read.strip.force_encoding('utf-8') unless entry.name_is_directory?
            end
          end
          expect(content).to match_array(file_content)
        end
      end

      context 'when a specific file is selected' do
        let(:file_name) { File.basename(file_names[0]) }

        it 'should be successful' do
          expect(response).to have_http_status(:ok)
        end

        it 'should return a non-zipped containing the content of a single file' do
          expect(response.body).to eq(file_content[0])
        end
      end

      context 'when a non-existant file is selected' do
        let(:file_name) { file_names.map { |f| File.basename f }.join }

        it 'should return a 422 error' do
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context 'when an assignment does not exist' do
        let(:aid) { assignment.id + 1 }

        it 'should return a 404 error' do
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when a group does not exist' do
        let(:gid) { group.id + 1 }

        it 'should return a 404 error' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
