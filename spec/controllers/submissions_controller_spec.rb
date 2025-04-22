describe SubmissionsController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  let(:course) { Course.first || create(:course) }

  shared_examples 'An authorized instructor and grader accessing #set_result_marking_state' do
    describe '#set_result_marking_state' do
      let(:marking_state) { Result::MARKING_STATES[:complete] }
      let(:released_to_students) { false }
      let(:new_marking_state) { Result::MARKING_STATES[:incomplete] }

      before do
        @current_result = grouping.current_result
        @current_result.update!(marking_state: marking_state, released_to_students: released_to_students)
        post_as role, :set_result_marking_state, params: { course_id: course.id,
                                                           assignment_id: @assignment.id,
                                                           groupings: [grouping.id],
                                                           marking_state: new_marking_state }
        @current_result.reload
      end

      context 'when the marking state is complete' do
        let(:new_marking_state) { Result::MARKING_STATES[:incomplete] }

        it 'should be able to bulk set the marking state to incomplete' do
          expect(@current_result.marking_state).to eq new_marking_state
        end

        it 'should be successful' do
          expect(response).to have_http_status(:success)
        end

        context 'when the result is released' do
          let(:released_to_students) { true }

          it 'should not be able to bulk set the marking state to complete' do
            expect(@current_result.marking_state).not_to eq new_marking_state
          end

          it 'should still respond as a success' do
            expect(response).to have_http_status(:success)
          end

          it 'should flash an error messages' do
            expect(flash[:error].size).to be 1
          end
        end
      end

      context 'when the marking state is incomplete' do
        let(:marking_state) { Result::MARKING_STATES[:incomplete] }
        let(:new_marking_state) { Result::MARKING_STATES[:complete] }

        it 'should be able to bulk set the marking state to complete' do
          expect(@current_result.marking_state).to eq new_marking_state
        end

        it 'should be successful' do
          expect(response).to have_http_status(:success)
        end
      end
    end
  end

  before do
    stub_const('SAMPLE_FILE_CONTENT', 'sample file content'.freeze)
    stub_const('SAMPLE_ERROR_MESSAGE', 'sample error message'.freeze)
    stub_const('SAMPLE_COMMENT', 'sample comment'.freeze)
    stub_const('SAMPLE_FILE_NAME', 'file.java'.freeze)
  end

  describe 'A student working alone' do
    before do
      @group = create(:group)
      @assignment = create(:assignment, course: @group.course)
      @grouping = create(:grouping,
                         group: @group,
                         assignment: @assignment)
      @membership = create(:student_membership,
                           membership_status: 'inviter',
                           grouping: @grouping)
      @student = @membership.role
    end

    it 'should be rejected if it is a scanned assignment' do
      assignment = create(:assignment_for_scanned_exam)
      create(:grouping_with_inviter, inviter: @student, assignment: assignment)
      get_as @student, :file_manager, params: { course_id: course.id, assignment_id: assignment.id }
      expect(response).to have_http_status :forbidden
    end

    it 'should be rejected if it is a timed assignment and the student has not yet started' do
      assignment = create(:timed_assignment)
      create(:grouping_with_inviter, inviter: @student, assignment: assignment)
      get_as @student, :file_manager, params: { course_id: course.id, assignment_id: assignment.id }
      expect(response).to have_http_status :forbidden
    end

    it 'should not be rejected if it is a timed assignment and the student has started' do
      assignment = create(:timed_assignment)
      create(:grouping_with_inviter, inviter: @student, assignment: assignment, start_time: 10.minutes.ago)
      get_as @student, :file_manager, params: { course_id: course.id, assignment_id: assignment.id }
      expect(response).to have_http_status(:success)
    end

    it 'should be able to add and access files' do
      file1 = fixture_file_upload('Shapes.java', 'text/java')
      file2 = fixture_file_upload('TestShapes.java', 'text/java')

      expect(@student).to have_accepted_grouping_for(@assignment.id)
      post_as @student, :update_files,
              params: { course_id: course.id, assignment_id: @assignment.id, new_files: [file1, file2] }

      expect(response).to have_http_status :ok

      # update_files action assert assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      expect(assigns(:assignment)).not_to be_nil
      expect(assigns(:grouping)).not_to be_nil
      expect(assigns(:path)).not_to be_nil
      expect(assigns(:revision)).not_to be_nil
      expect(assigns(:files)).not_to be_nil

      # Check to see if the file was added
      @grouping.group.access_repo do |repo|
        revision = repo.get_latest_revision
        files = revision.files_at_path(@assignment.repository_folder)
        expect(files['Shapes.java']).not_to be_nil
        expect(files['TestShapes.java']).not_to be_nil
      end
    end

    it 'should check for MIME type and extension that match' do
      expect(@student).to have_accepted_grouping_for(@assignment.id)

      valid_file = fixture_file_upload('docx_file.docx',
                                       'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
      content_type = Marcel::MimeType.for Pathname.new(valid_file)
      file_extension = File.extname(valid_file.original_filename).downcase
      expected_mime_type = Marcel::MimeType.for extension: file_extension

      expect(content_type).to eq(expected_mime_type)

      post_as @student, :update_files,
              params: { course_id: course.id, assignment_id: @assignment.id, new_files: [valid_file] }
      expect(response).to have_http_status :ok

      # Check to see if the file was added
      @grouping.group.access_repo do |repo|
        revision = repo.get_latest_revision
        files = revision.files_at_path(@assignment.repository_folder)
        expect(files['docx_file.docx']).not_to be_nil
      end
    end

    it 'should check for MIME type and extension that do not match' do
      expect(@student).to have_accepted_grouping_for(@assignment.id)

      invalid_file = fixture_file_upload('docx_renamed_to_pdf.pdf')
      content_type = Marcel::MimeType.for(Pathname.new(invalid_file))
      file_extension = File.extname(invalid_file.original_filename).downcase
      expected_mime_type = Marcel::MimeType.for(extension: file_extension)

      expect(content_type).not_to eq(expected_mime_type)

      post_as @student, :update_files,
              params: { course_id: course.id, assignment_id: @assignment.id, new_files: [invalid_file] }

      expect(response).to have_http_status :ok
      sample_warning_message = I18n.t('student.submission.file_extension_mismatch', extension: file_extension)
      flash[:warning] = I18n.t('student.submission.file_extension_mismatch', extension: file_extension)
      expect(flash[:warning]).to eq sample_warning_message

      # Check to see if the file was added
      @grouping.group.access_repo do |repo|
        revision = repo.get_latest_revision
        files = revision.files_at_path(@assignment.repository_folder)
        expect(files['docx_renamed_to_pdf.pdf']).not_to be_nil
      end
    end

    it 'cannot add files outside the repository when an invalid path is given' do
      file = fixture_file_upload('Shapes.java', 'text/java')
      bad_path = '../../'
      post_as @student, :update_files,
              params: { course_id: course.id, assignment_id: @assignment.id, new_files: [file], path: bad_path }

      expect(response).to have_http_status :bad_request
      expect(File).not_to exist(File.join(@grouping.group.repo_path, @grouping.assignment.repository_folder,
                                          bad_path, 'Shapes.java'))
    end

    it 'cannot add folders outside the repository assignment folder' do
      dir = '../hello'
      post_as @student, :update_files,
              params: { course_id: course.id, assignment_id: @assignment.id, new_folders: [dir], path: '/' }

      expect(response).to have_http_status :unprocessable_entity
      expect(Dir).not_to exist(File.join(@grouping.group.repo_path, @grouping.assignment.repository_folder,
                                         dir))
    end

    it 'cannot delete files outside the repository assignment folder' do
      post_as @student, :update_files,
              params: { course_id: course.id, assignment_id: @assignment.id,
                        delete_files: ['../../../../../LICENSE'], path: '/' }

      expect(response).to have_http_status :unprocessable_entity
      expect(File).to exist(
        File.expand_path(File.join(@grouping.group.repo_path, '../../../../../LICENSE'))
      )
    end

    it 'cannot delete folders outside the repository assignment folder' do
      post_as @student, :update_files,
              params: { course_id: course.id, assignment_id: @assignment.id,
                        delete_folders: ['../../../../../doc'], path: '/' }

      expect(response).to have_http_status :unprocessable_entity
      expect(Dir).to exist(
        File.expand_path(File.join(@grouping.group.repo_path, '../../../../../doc'))
      )
    end

    context 'submitting a url' do
      describe 'should add url files' do
        before do
          @assignment.update!(url_submit: true)
        end

        it 'returns ok response' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_url: 'https://www.youtube.com/watch?v=dtGs7Fy8ISo', url_text: 'youtube' }
          expect(response).to have_http_status :ok
        end

        it 'added a new file' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_url: 'https://www.youtube.com/watch?v=dtGs7Fy8ISo', url_text: 'youtube' }
          @grouping.group.access_repo do |repo|
            revision = repo.get_latest_revision
            files = revision.files_at_path(@assignment.repository_folder)
            expect(files['youtube.markusurl']).not_to be_nil
          end
        end

        it 'with the correct content' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_url: 'https://www.youtube.com/watch?v=dtGs7Fy8ISo', url_text: 'youtube' }
          @grouping.group.access_repo do |repo|
            revision = repo.get_latest_revision
            files = revision.files_at_path(@assignment.repository_folder)
            file_content = repo.download_as_string(files['youtube.markusurl'])
            expect(file_content).to eq('https://www.youtube.com/watch?v=dtGs7Fy8ISo')
          end
        end
      end

      describe 'should reject url with no name' do
        before do
          @assignment.update!(url_submit: true)
        end

        it 'returns a bad request' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_url: 'https://www.youtube.com/watch?v=dtGs7Fy8ISo' }
          expect(response).to have_http_status :bad_request
        end

        it 'does not add a new file' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_url: 'https://www.youtube.com/watch?v=dtGs7Fy8ISo' }
          @grouping.group.access_repo do |repo|
            revision = repo.get_latest_revision
            files = revision.files_at_path(@assignment.repository_folder)
            expect(files['youtube.markusurl']).to be_nil
          end
        end
      end

      describe 'should reject invalid url' do
        before do
          @assignment.update!(url_submit: true)
        end

        it 'returns a bad request' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_url: 'Not a url', url_text: 'youtube' }
          expect(response).to have_http_status :bad_request
        end

        it 'does not add a new file' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_url: 'Not a url', url_text: 'youtube' }
          @grouping.group.access_repo do |repo|
            revision = repo.get_latest_revision
            files = revision.files_at_path(@assignment.repository_folder)
            expect(files['youtube.markusurl']).to be_nil
          end
        end
      end

      describe 'should reject url when option is disabled' do
        it 'returns a bad request' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_url: 'https://www.youtube.com/watch?v=dtGs7Fy8ISo', url_text: 'youtube' }
          expect(response).to have_http_status :bad_request
        end

        it 'does not add a new file' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_url: 'https://www.youtube.com/watch?v=dtGs7Fy8ISo', url_text: 'youtube' }
          @grouping.group.access_repo do |repo|
            revision = repo.get_latest_revision
            files = revision.files_at_path(@assignment.repository_folder)
            expect(files['youtube.markusurl']).to be_nil
          end
        end
      end
    end

    context 'when the grouping is invalid' do
      it 'should not be able to add files' do
        @assignment.update!(group_min: 2, group_max: 3)
        file1 = fixture_file_upload('Shapes.java', 'text/java')
        file2 = fixture_file_upload('TestShapes.java', 'text/java')

        expect(@student).to have_accepted_grouping_for(@assignment.id)
        post_as @student, :update_files,
                params: { course_id: course.id, assignment_id: @assignment.id, new_files: [file1, file2] }

        expect(response).to have_http_status :bad_request

        # Check that the files were not added
        @grouping.group.access_repo do |repo|
          revision = repo.get_latest_revision
          files = revision.files_at_path(@assignment.repository_folder)
          expect(files['Shapes.java']).to be_nil
          expect(files['TestShapes.java']).to be_nil
        end
      end
    end

    context 'when only required files can be submitted' do
      before do
        @assignment.update(
          only_required_files: true,
          assignment_files_attributes: [{ filename: 'Shapes.java' }]
        )
      end

      it 'should be able to add and access files when uploading only required files' do
        file1 = fixture_file_upload('Shapes.java', 'text/java')

        post_as @student, :update_files,
                params: { course_id: course.id, assignment_id: @assignment.id, new_files: [file1] }

        expect(response).to have_http_status :ok

        # Check to see if the file was added
        @grouping.group.access_repo do |repo|
          revision = repo.get_latest_revision
          files = revision.files_at_path(@assignment.repository_folder)
          expect(files['Shapes.java']).not_to be_nil
        end
      end

      it 'should not be able to add and access files when uploading at least one non-required file' do
        file1 = fixture_file_upload('Shapes.java', 'text/java')
        file2 = fixture_file_upload('TestShapes.java', 'text/java')

        post_as @student, :update_files,
                params: { course_id: course.id, assignment_id: @assignment.id, new_files: [file1, file2] }

        expect(response).to have_http_status :unprocessable_entity

        # Check to see if the file was added
        @grouping.group.access_repo do |repo|
          revision = repo.get_latest_revision
          files = revision.files_at_path(@assignment.repository_folder)
          expect(files['Shapes.java']).to be_nil
          expect(files['TestShapes.java']).to be_nil
        end
      end

      context 'when creating a folder with required files' do
        let(:tree) do
          @grouping.group.access_repo do |repo|
            repo.get_latest_revision.tree_at_path(@assignment.repository_folder)
          end
        end

        before do
          @assignment.update!(
            only_required_files: true,
            assignment_files_attributes: [{ filename: 'test_zip/zip_subdir/TestShapes.java' }]
          )
        end

        it 'uploads a directory and returns a success' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_folders: ['test_zip'] }
          expect(response).to have_http_status :ok
        end

        it 'commits a single directory' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_folders: ['test_zip'] }
          expect(tree['test_zip']).not_to be_nil
        end

        it 'uploads a subdirectory' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_folders: ['test_zip'] }
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_folders: ['test_zip/zip_subdir'] }
          expect(response).to have_http_status :ok
        end

        it 'commits a subdirectory' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_folders: ['test_zip'] }
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_folders: ['test_zip/zip_subdir'] }
          expect(tree['test_zip/zip_subdir']).not_to be_nil
        end

        context 'when testing with a git repo', keep_memory_repos: true do
          before { allow(Settings.repository).to receive(:type).and_return('git') }
          after { FileUtils.rm_r(Dir.glob(File.join(Repository::ROOT_DIR, '*'))) }

          it 'displays a failure message when attempting to create a subdirectory with no parent' do
            post_as @student, :update_files,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              new_folders: ['test_zip/zip_subdir'] }

            expect(flash[:error]).not_to be_empty
          end
        end

        it 'does not upload a non required directory and returns a failure' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_folders: ['bad_folder'] }
          expect(response).to have_http_status :unprocessable_entity
        end

        it 'does not commit the non required directory' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_folders: ['bad_folder'] }
          expect(tree['bad_folder']).to be_nil
        end

        it 'does not upload a non required subdirectory' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_folders: ['bad_folder/bad_subdirectory'] }
          expect(response).to have_http_status :unprocessable_entity
        end

        it 'does not commit a non required subdirectory' do
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_folders: ['bad_folder/bad_subdirectory'] }
          expect(tree['bad_folder/bad_subdirectory']).to be_nil
        end
      end

      context 'when folders are required and uploading a zip file' do
        let(:unzip) { 'true' }

        before do
          @assignment.update!(
            only_required_files: true,
            assignment_files_attributes: [{ filename: 'test_zip/zip_subdir/TestShapes.java' },
                                          { filename: 'test_zip/Shapes.java' }]
          )
        end

        it 'should be able to create required folders' do
          zip_file = fixture_file_upload('test_zip.zip', 'application/zip')
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_files: [zip_file], unzip: unzip }

          expect(response).to have_http_status :ok
        end

        it 'uploads the outer directory' do
          zip_file = fixture_file_upload('test_zip.zip', 'application/zip')
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_files: [zip_file], unzip: unzip }
          tree = @grouping.group.access_repo do |repo|
            repo.get_latest_revision.tree_at_path(@assignment.repository_folder)
          end
          expect(tree['test_zip']).not_to be_nil
        end

        it 'uploads the inner directory' do
          zip_file = fixture_file_upload('test_zip.zip', 'application/zip')
          post_as @student, :update_files,
                  params: { course_id: course.id, assignment_id: @assignment.id,
                            new_files: [zip_file], unzip: unzip }
          tree = @grouping.group.access_repo do |repo|
            repo.get_latest_revision.tree_at_path(@assignment.repository_folder)
          end
          expect(tree['test_zip/zip_subdir']).not_to be_nil
        end
      end
    end

    context 'uploads a .git file' do
      let(:unzip) { 'true' }

      it 'should not be allowed' do
        post_as @student, :update_files,
                params: { course_id: course.id, assignment_id: @assignment.id,
                          new_files: ['.git'] }
        expect(response).to have_http_status :unprocessable_entity
      end

      it 'should not be allowed in a zip file' do
        zip_file = fixture_file_upload('test_zip_git_file.zip', 'application/zip')
        post_as @student, :update_files,
                params: { course_id: course.id, assignment_id: @assignment.id, new_files: [zip_file], unzip: unzip }
        expect(response).to have_http_status :unprocessable_entity
      end

      it 'should not create a .git file in the repo' do
        zip_file = fixture_file_upload('test_zip_git_file.zip', 'application/zip')
        post_as @student, :update_files,
                params: { course_id: course.id, assignment_id: @assignment.id,
                          new_files: [zip_file], unzip: unzip }
        tree = @grouping.group.access_repo do |repo|
          repo.get_latest_revision.tree_at_path(@assignment.repository_folder)
        end
        expect(tree['test_zip_git_file']).to be_nil
      end
    end

    context 'uploads a .git folder' do
      let(:unzip) { 'true' }

      it 'should not be allowed' do
        post_as @student, :update_files,
                params: { course_id: course.id, assignment_id: @assignment.id,
                          new_folders: ['.git'] }
        expect(response).to have_http_status :unprocessable_entity
      end

      it 'should not be allowed in a zip file' do
        zip_file = fixture_file_upload('test_zip_git_folder.zip', 'application/zip')
        post_as @student, :update_files,
                params: { course_id: course.id, assignment_id: @assignment.id, new_files: [zip_file], unzip: unzip }
        expect(response).to have_http_status :unprocessable_entity
      end

      it 'should not create a .git directory in the repo' do
        zip_file = fixture_file_upload('test_zip_git_folder.zip', 'application/zip')
        post_as @student, :update_files,
                params: { course_id: course.id, assignment_id: @assignment.id,
                          new_files: [zip_file], unzip: unzip }
        tree = @grouping.group.access_repo do |repo|
          repo.get_latest_revision.tree_at_path(@assignment.repository_folder)
        end
        expect(tree['test_zip_git_folder']).to be_nil
      end
    end

    context 'uploading a zip file' do
      let(:unzip) { 'true' }
      let(:tree) do
        zip_file = fixture_file_upload('test_zip.zip', 'application/zip')
        post_as @student, :update_files,
                params: { course_id: course.id, assignment_id: @assignment.id, new_files: [zip_file], unzip: unzip }
        @grouping.group.access_repo do |repo|
          repo.get_latest_revision.tree_at_path(@assignment.repository_folder)
        end
      end

      context 'when unzip if false' do
        let(:unzip) { 'false' }

        it 'should just upload the zip file as is' do
          expect(tree['test_zip.zip']).not_to be_nil
        end

        it 'should not upload any other files' do
          expect(tree.length).to eq 1
        end
      end

      it 'should not upload the zip file' do
        expect(tree['test_zip.zip']).to be_nil
      end

      it 'should upload the outer dir' do
        expect(tree['test_zip']).not_to be_nil
      end

      it 'should upload the inner dir' do
        expect(tree['test_zip/zip_subdir']).not_to be_nil
      end

      it 'should upload a file in the outer dir' do
        expect(tree['test_zip/Shapes.java']).not_to be_nil
      end

      it 'should upload a file in the inner dir' do
        expect(tree['test_zip/zip_subdir/TestShapes.java']).not_to be_nil
      end
    end

    it 'should be able to populate the file manager' do
      get_as @student, :populate_file_manager,
             params: { course_id: course.id, assignment_id: @assignment.id }, format: 'json'
      expect(subject).to respond_with(:success)
    end

    it 'should be able to access file manager page' do
      get_as @student, :file_manager,
             params: { course_id: course.id, assignment_id: @assignment.id }
      expect(subject).to respond_with(:success)
      # file_manager action assert assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      expect(assigns(:assignment)).not_to be_nil
      expect(assigns(:grouping)).not_to be_nil
      expect(assigns(:path)).not_to be_nil
      expect(assigns(:revision)).not_to be_nil
      expect(assigns(:files)).not_to be_nil
    end

    it 'should render with the assignment content layout' do
      get_as @student, :file_manager,
             params: { course_id: course.id, assignment_id: @assignment.id }
      expect(response).to render_template('layouts/assignment_content')
    end

    # TODO: figure out how to test this test into the one above
    # TODO Figure out how to remove fixture_file_upload
    it 'should be able to replace files' do
      expect(@student).to have_accepted_grouping_for(@assignment.id)

      @grouping.group.access_repo do |repo|
        txn = repo.get_transaction('markus')
        # overwrite and commit both files
        txn.add(File.join(@assignment.repository_folder, 'Shapes.java'),
                'Content of Shapes.java')
        txn.add(File.join(@assignment.repository_folder, 'TestShapes.java'),
                'Content of TestShapes.java')
        repo.commit(txn)

        # revision 2
        revision = repo.get_latest_revision
        old_files = revision.files_at_path(@assignment.repository_folder)
        old_file1 = old_files['Shapes.java']
        old_file2 = old_files['TestShapes.java']

        @file1 = fixture_file_upload('Shapes.java', 'text/java')
        @file2 = fixture_file_upload('TestShapes.java', 'text/java')

        post_as @student,
                :update_files,
                params: { course_id: course.id, assignment_id: @assignment.id, new_files: [@file1, @file2],
                          file_revisions: { 'Shapes.java' => old_file1.from_revision,
                                            'TestShapes.java' => old_file2.from_revision } }
      end
      expect(response).to have_http_status :ok

      expect(assigns(:assignment)).not_to be_nil
      expect(assigns(:grouping)).not_to be_nil
      expect(assigns(:path)).not_to be_nil
      expect(assigns(:revision)).not_to be_nil
      expect(assigns(:files)).not_to be_nil

      @grouping.group.access_repo do |repo|
        revision = repo.get_latest_revision
        files = revision.files_at_path(@assignment.repository_folder)
        expect(files['Shapes.java']).not_to be_nil
        expect(files['TestShapes.java']).not_to be_nil

        # Test to make sure that the contents were successfully updated
        @file1.rewind
        @file2.rewind
        file_1_new_contents = repo.download_as_string(files['Shapes.java'])
        file_2_new_contents = repo.download_as_string(files['TestShapes.java'])

        expect(@file1.read).to eq(file_1_new_contents)
        expect(@file2.read).to eq(file_2_new_contents)
      end
    end

    it 'should be able to delete files' do
      expect(@student).to have_accepted_grouping_for(@assignment.id)

      @grouping.group.access_repo do |repo|
        txn = repo.get_transaction('markus')
        txn.add(File.join(@assignment.repository_folder, 'Shapes.java'),
                'Content of Shapes.java')
        txn.add(File.join(@assignment.repository_folder, 'TestShapes.java'),
                'Content of TestShapes.java')
        repo.commit(txn)
        revision = repo.get_latest_revision
        old_files = revision.files_at_path(@assignment.repository_folder)
        old_file1 = old_files['Shapes.java']
        old_file2 = old_files['TestShapes.java']

        post_as @student,
                :update_files,
                params: { course_id: course.id, assignment_id: @assignment.id, delete_files: ['Shapes.java'],
                          file_revisions: { 'Shapes.java' => old_file1.from_revision,
                                            'TestShapes.java' => old_file2.from_revision } }
      end

      expect(response).to have_http_status :ok

      expect(assigns(:assignment)).not_to be_nil
      expect(assigns(:grouping)).not_to be_nil
      expect(assigns(:path)).not_to be_nil
      expect(assigns(:revision)).not_to be_nil
      expect(assigns(:files)).not_to be_nil

      @grouping.group.access_repo do |repo|
        revision = repo.get_latest_revision
        files = revision.files_at_path(@assignment.repository_folder)
        expect(files['Shapes.java']).to be_nil
        expect(files['TestShapes.java']).not_to be_nil
      end
    end

    # Repository Browser Tests
    # TODO:  TEST REPO BROWSER HERE
    it 'should not be able to use the repository browser' do
      get_as @student, :repo_browser,
             params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: Grouping.last.id }
      expect(subject).to respond_with(:forbidden)
    end

    # Stopping a curious student
    it 'should not be able download repository checkout commands' do
      get_as @student, :download_repo_checkout_commands, params: { course_id: course.id, assignment_id: @assignment.id }

      expect(subject).to respond_with(:forbidden)
    end

    it 'should not be able to download the repository list' do
      get_as @student, :download_repo_list, params: { course_id: course.id, assignment_id: @assignment.id }

      expect(subject).to respond_with(:forbidden)
    end
  end

  describe 'A grader' do
    let(:grader) { create(:ta) }
    let(:revision_identifier) do
      @grouping.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
    end
    let(:grader_permission) { grader.grader_permission }

    before do
      @group = create(:group)
      @assignment = create(:assignment, course: @group.course)
      @grouping = create(:grouping,
                         group: @group,
                         assignment: @assignment)
      @membership = create(:student_membership,
                           membership_status: 'inviter',
                           grouping: @grouping)
      @student = @membership.role

      @grouping1 = create(:grouping,
                          assignment: @assignment)
      @grouping1.group.access_repo do |repo|
        txn = repo.get_transaction('test')
        path = File.join(@assignment.repository_folder, 'file1_name')
        txn.add(path, 'file1 content', '')
        repo.commit(txn)

        # Generate submission
        submission = Submission.generate_new_submission(Grouping.last,
                                                        repo.get_latest_revision)
        result = submission.get_latest_result
        result.marking_state = Result::MARKING_STATES[:complete]
        result.save
        submission.save
      end
    end

    describe '#set_resulting_marking_state' do
      let(:role) { create(:ta) }
      let(:grouping) { @grouping1 }

      it_behaves_like 'An authorized instructor and grader accessing #set_result_marking_state'
    end

    it 'should be able to access the repository browser.' do
      revision_identifier = Grouping.last.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
      get_as grader,
             :repo_browser,
             params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: Grouping.last.id,
                       revision_identifier: revision_identifier,
                       path: '/' }
      expect(subject).to respond_with(:success)
    end

    it 'should render with the assignment_content layout' do
      revision_identifier = Grouping.last.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
      get_as grader,
             :repo_browser,
             params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: Grouping.last.id,
                       revision_identifier: revision_identifier,
                       path: '/' }
      expect(response).to render_template('layouts/assignment_content')
    end

    it 'should be able to download the repository checkout commands' do
      get_as grader, :download_repo_checkout_commands, params: { course_id: course.id, assignment_id: @assignment.id }
      expect(subject).to respond_with(:forbidden)
    end

    it 'should be able to download the repository list' do
      get_as grader, :download_repo_list, params: { course_id: course.id, assignment_id: @assignment.id }
      expect(subject).to respond_with(:forbidden)
    end

    describe 'When grader is allowed to collect and update submissions' do
      before do
        grader_permission.manage_submissions = true
        grader_permission.save
      end

      describe '#collect_submissions' do
        it('should respond with success status') do
          post_as grader, :collect_submissions,
                  params: { course_id: course.id, assignment_id: @assignment.id, groupings: [@grouping.id] }
          expect(response).to have_http_status(:success)
        end
      end

      describe '#manually_collect_and_begin_grading' do
        it 'should respond with 302' do
          post_as grader, :manually_collect_and_begin_grading,
                  params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: @grouping.id,
                            current_revision_identifier: revision_identifier }

          expect(response).to have_http_status :found
        end

        it 'should respond with 302 when additional parameters are present' do
          post_as grader, :manually_collect_and_begin_grading,
                  params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: @grouping.id,
                            current_revision_identifier: revision_identifier,
                            apply_late_penalty: true,
                            retain_existing_grading: true }

          expect(response).to have_http_status :found
        end

        it 'should not flash any error messages' do
          post_as grader, :manually_collect_and_begin_grading,
                  params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: @grouping.id,
                            current_revision_identifier: revision_identifier }

          expect(flash[:error]).to be_nil
        end

        context 'When a grouping\'s submission has already been released' do
          before do
            # mark the existing submission as released
            last_result = @grouping1.current_submission_used.get_latest_result
            last_result.update!(released_to_students: true)
          end

          it 'should respond with 302' do
            post_as grader, :manually_collect_and_begin_grading,
                    params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: @grouping1.id,
                              current_revision_identifier: revision_identifier }

            expect(response).to have_http_status :found
          end

          it 'should flash an error message' do
            post_as grader, :manually_collect_and_begin_grading,
                    params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: @grouping1.id,
                              current_revision_identifier: revision_identifier }

            expect(flash[:error]).to have_message(I18n.t('submissions.collect.could_not_collect_released'))
          end
        end
      end

      describe '#update submissions' do
        it 'should respond with 302' do
          post_as grader,
                  :update_submissions,
                  params: { course_id: course.id,
                            assignment_id: @assignment.id,
                            groupings: [@grouping1.id],
                            release_results: 'true' }
          expect(subject).to respond_with(:success)
        end
      end
    end

    describe 'When grader is not allowed to collect and update submissions' do
      before do
        grader_permission.manage_submissions = false
        grader_permission.save
      end

      describe '#collect_submissions' do
        before do
          post_as grader, :collect_submissions,
                  params: { course_id: course.id, assignment_id: @assignment.id, groupings: [@grouping.id] }
        end

        it('should respond with 403') { expect(response).to have_http_status :forbidden }
      end

      describe '#manually_collect_and_begin_grading' do
        before do
          post_as grader, :manually_collect_and_begin_grading,
                  params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: @grouping.id,
                            current_revision_identifier: revision_identifier }
        end

        it('should respond with 403') { expect(response).to have_http_status :forbidden }
      end

      describe '#update submissions' do
        it 'should respond with 403' do
          post_as grader,
                  :update_submissions,
                  params: { course_id: course.id,
                            assignment_id: @assignment.id,
                            groupings: ([] << @assignment.groupings).flatten,
                            release_results: 'true' }
          expect(response).to have_http_status :forbidden
        end
      end
    end
  end

  describe 'An administrator' do
    before do
      @group = create(:group)
      @assignment = create(:assignment, course: @group.course)
      @grouping = create(:grouping,
                         group: @group,
                         assignment: @assignment)
      @membership = create(:student_membership,
                           membership_status: 'inviter',
                           grouping: @grouping)
      @student = @membership.role
      @instructor = create(:instructor)
      @csv_options = {
        type: 'text/csv',
        disposition: 'attachment',
        filename: "#{@assignment.short_identifier}_simple_report.csv"
      }
    end

    it 'should be able to access the repository browser' do
      get_as @instructor, :repo_browser,
             params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: Grouping.last.id, path: '/' }
      expect(subject).to respond_with(:success)
    end

    it 'should render with the assignment_content layout' do
      get_as @instructor, :repo_browser,
             params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: Grouping.last.id, path: '/' }
      expect(response).to render_template(layout: 'layouts/assignment_content')
    end

    it 'should be able to download the repository checkout commands' do
      get_as @instructor, :download_repo_checkout_commands,
             params: { course_id: course.id, assignment_id: @assignment.id }
      expect(subject).to respond_with(:success)
    end

    it 'should be able to download the repository list' do
      get_as @instructor, :download_repo_list, params: { course_id: course.id, assignment_id: @assignment.id }
      expect(subject).to respond_with(:success)
    end

    describe 'attempting to collect submissions' do
      before do
        @grouping.group.access_repo do |repo|
          txn = repo.get_transaction('test')
          path = File.join(@assignment.repository_folder, 'file1_name')
          txn.add(path, 'file1 content', '')
          repo.commit(txn)

          # Generate submission
          submission =
            Submission.generate_new_submission(@grouping,
                                               repo.get_latest_revision)
          result = submission.get_latest_result
          result.marking_state = Result::MARKING_STATES[:complete]
          result.save
          submission.save
        end
        @grouping.update! is_collected: true
      end

      around { |example| perform_enqueued_jobs(&example) }

      describe '#set_resulting_marking_state' do
        let(:role) { create(:ta) }
        let(:grouping) { @grouping }

        it_behaves_like 'An authorized instructor and grader accessing #set_result_marking_state'
      end

      context 'when at least one submission can be collected' do
        let(:instructor2) { create(:instructor) }
        let(:params) do
          { course_id: course.id,
            assignment_id: @assignment.id,
            groupings: [@grouping.id],
            override: true }
        end

        before do
          @assignment.update!(due_date: 1.week.ago)
          allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }
        end

        it 'broadcasts a status update to the correct user' do
          expect(CollectSubmissionsChannel).to receive(:broadcast_to) do |enqueuing_user, _|
            expect(enqueuing_user).to eq(@instructor.user)
          end
          post_as @instructor, :collect_submissions, params: params
        end

        it 'broadcasts exactly one message' do
          expect(CollectSubmissionsChannel).to receive(:broadcast_to).once
          post_as @instructor, :collect_submissions, params: params
        end

        it "doesn't broadcast the message to other users" do
          expect(CollectSubmissionsChannel).to receive(:broadcast_to) do |enqueuing_user, _|
            expect(enqueuing_user).not_to eq(instructor2.user)
          end
          post_as @instructor, :collect_submissions, params: params
        end
      end

      context 'when no submissions can be collected' do
        it 'broadcasts no messages' do
          @assignment.update!(due_date: 1.week.ago)
          allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }
          expect(CollectSubmissionsChannel).to receive(:broadcast_to).exactly(0).times
          post_as @instructor, :collect_submissions, params: { course_id: course.id,
                                                               assignment_id: @assignment.id,
                                                               groupings: [@grouping.id],
                                                               override: false }
        end
      end

      context 'where a grouping does not have a previously collected submission' do
        let(:uncollected_grouping) { create(:grouping, assignment: @assignment) }

        before do
          uncollected_grouping.group.access_repo do |repo|
            txn = repo.get_transaction('test')
            path = File.join(@assignment.repository_folder, 'file1_name')
            txn.add(path, 'file1 content', '')
            repo.commit(txn)
          end
          @assignment.update!(due_date: 1.week.ago)
          allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }
        end

        it 'should collect all groupings when override is true' do
          enqueuing_user = @instructor.user
          expect(SubmissionsJob).to receive(:perform_later).with(
            array_including(@grouping, uncollected_grouping),
            enqueuing_user: enqueuing_user,
            notify_socket: true,
            collection_dates: hash_including,
            collect_current: false,
            apply_late_penalty: false,
            retain_existing_grading: false
          )
          post_as @instructor, :collect_submissions, params: { course_id: course.id,
                                                               assignment_id: @assignment.id,
                                                               groupings: [@grouping.id, uncollected_grouping.id],
                                                               override: true }
        end

        it 'should retain existing grading data on all groupings when override and retain_existing_grading are true' do
          enqueuing_user = @instructor.user
          expect(SubmissionsJob).to receive(:perform_later).with(
            array_including(@grouping, uncollected_grouping),
            enqueuing_user: enqueuing_user,
            notify_socket: true,
            collection_dates: hash_including,
            collect_current: false,
            apply_late_penalty: false,
            retain_existing_grading: true
          )
          post_as @instructor, :collect_submissions, params: { course_id: course.id,
                                                               assignment_id: @assignment.id,
                                                               groupings: [@grouping.id, uncollected_grouping.id],
                                                               override: true, retain_existing_grading: true }
        end

        it 'should collect the uncollected grouping only when override is false' do
          enqueuing_user = @instructor.user
          expect(SubmissionsJob).to receive(:perform_later).with(
            [uncollected_grouping],
            enqueuing_user: enqueuing_user,
            notify_socket: true,
            collection_dates: hash_including,
            collect_current: false,
            apply_late_penalty: false,
            retain_existing_grading: false
          )
          post_as @instructor, :collect_submissions, params: { course_id: course.id,
                                                               assignment_id: @assignment.id,
                                                               groupings: [@grouping.id, uncollected_grouping.id],
                                                               override: false }
        end
      end

      context 'when updating students on submission results' do
        it 'should be able to release submissions' do
          allow(Assignment).to receive(:find) { @assignment }
          post_as @instructor,
                  :update_submissions,
                  params: { course_id: course.id,
                            assignment_id: @assignment.id,
                            groupings: ([] << @assignment.groupings).flatten,
                            release_results: 'true' }
          expect(subject).to respond_with(:success)
        end

        context 'with one grouping selected' do
          it 'sends an email to the student if only one student exists in the grouping' do
            expect do
              post_as @instructor,
                      :update_submissions,
                      params: { course_id: course.id,
                                assignment_id: @assignment.id,
                                groupings: ([] << @assignment.groupings).flatten,
                                release_results: 'true' }
            end.to change { ActionMailer::Base.deliveries.count }.by(1)
          end

          it 'sends an email to every student in a grouping if it has multiple students' do
            create(:student_membership, membership_status: 'inviter', grouping: @grouping)
            expect do
              post_as @instructor,
                      :update_submissions,
                      params: { course_id: course.id,
                                assignment_id: @assignment.id,
                                groupings: ([] << @assignment.groupings).flatten,
                                release_results: 'true' }
            end.to change { ActionMailer::Base.deliveries.count }.by(2)
          end

          it 'does not send an email to some students in a grouping if some have emails disabled' do
            another_membership = create(:student_membership, membership_status: 'inviter', grouping: @grouping)
            another_membership.role.update!(receives_results_emails: false)
            expect do
              post_as @instructor,
                      :update_submissions,
                      params: { course_id: course.id,
                                assignment_id: @assignment.id,
                                groupings: ([] << @assignment.groupings).flatten,
                                release_results: 'true' }
            end.to change { ActionMailer::Base.deliveries.count }.by(1)
          end
        end

        context 'with several groupings selected' do
          it 'sends emails to students in every grouping selected if more than one grouping is selected' do
            other_grouping = create(:grouping, assignment: @assignment)
            create(:student_membership, membership_status: 'inviter', grouping: other_grouping)
            other_grouping.group.access_repo do |repo|
              txn = repo.get_transaction('test')
              path = File.join(@assignment.repository_folder, 'file1_name')
              txn.add(path, 'file1 content', '')
              repo.commit(txn)
              # Generate submission
              submission = Submission.generate_new_submission(other_grouping, repo.get_latest_revision)
              result = submission.get_latest_result
              result.marking_state = Result::MARKING_STATES[:complete]
              result.save
              submission.save
            end
            other_grouping.update! is_collected: true
            expect do
              post_as @instructor,
                      :update_submissions,
                      params: { course_id: course.id,
                                assignment_id: @assignment.id,
                                groupings: ([] << @assignment.groupings).flatten,
                                release_results: 'true' }
            end.to change { ActionMailer::Base.deliveries.count }.by(2)
          end

          it 'does not email some students in some groupings if those students have them disabled' do
            other_grouping = create(:grouping, assignment: @assignment)
            other_membership = create(:student_membership, membership_status: 'inviter', grouping: other_grouping)
            other_membership.role.update!(receives_results_emails: false)
            other_grouping.group.access_repo do |repo|
              txn = repo.get_transaction('test')
              path = File.join(@assignment.repository_folder, 'file1_name')
              txn.add(path, 'file1 content', '')
              repo.commit(txn)
              # Generate submission
              submission = Submission.generate_new_submission(other_grouping, repo.get_latest_revision)
              result = submission.get_latest_result
              result.marking_state = Result::MARKING_STATES[:complete]
              result.save
              submission.save
            end
            other_grouping.update! is_collected: true
            expect do
              post_as @instructor,
                      :update_submissions,
                      params: { course_id: course.id,
                                assignment_id: @assignment.id,
                                groupings: ([] << @assignment.groupings).flatten,
                                release_results: 'true' }
            end.to change { ActionMailer::Base.deliveries.count }.by(1)
          end
        end
      end

      context 'of selected groupings' do
        it 'should get an error if no groupings are selected' do
          post_as @instructor, :collect_submissions,
                  params: { course_id: course.id, assignment_id: @assignment.id, groupings: [] }

          expect(subject).to respond_with(:bad_request)
        end

        context 'with a section' do
          before do
            @section = create(:section, name: 's1')
            @assessment_section_properties = create(:assessment_section_properties, section: @section,
                                                                                    assessment: @assignment)
            @student.section = @section
            @student.save
          end

          it 'should get an error if it is before the section due date and collect_current is not selected' do
            @assessment_section_properties.update!(due_date: 1.week.from_now)
            expect_any_instance_of(SubmissionsController).to receive(:flash_now).with(:error, anything)
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }

            post_as @instructor,
                    :collect_submissions,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              override: true, groupings: ([] << @assignment.groupings).flatten }
            expect(response).to have_http_status(:success)
          end

          it 'should not receive an error if it is before the section due date and collect_current is selected' do
            @assessment_section_properties.update!(due_date: 1.week.from_now)
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }
            post_as @instructor,
                    :collect_submissions,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              override: true, collect_current: true,
                              groupings: @assignment.groupings.to_a }
            expect(flash[:error]).to be_nil
          end

          it 'should succeed if it is before the section due date and collect_current is selected' do
            @assessment_section_properties.update!(due_date: 1.week.from_now)
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }
            post_as @instructor,
                    :collect_submissions,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              override: true, collect_current: true,
                              groupings: @assignment.groupings.to_a }
            expect(response).to have_http_status(:success)
          end

          it 'should succeed if it is after the section due date' do
            @assessment_section_properties.update!(due_date: 1.week.ago)
            expect_any_instance_of(SubmissionsController).not_to receive(:flash_now).with(:error, anything)
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }

            post_as @instructor,
                    :collect_submissions,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              override: true, groupings: ([] << @assignment.groupings).flatten }
            expect(response).to have_http_status(:success)
          end
        end

        context 'without a section' do
          before do
            @student.section = nil
            @student.save
          end

          it 'should get an error if it is before the global due date' do
            @assignment.update!(due_date: 1.week.from_now)
            expect_any_instance_of(SubmissionsController).to receive(:flash_now).with(:error, anything)
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }

            post_as @instructor,
                    :collect_submissions,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              override: true, groupings: ([] << @assignment.groupings).flatten }
            expect(response).to have_http_status(:success)
          end

          it 'should not return an error if it is before the global due date but collect_current is true' do
            @assignment.update!(due_date: 1.week.from_now)
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }
            post_as @instructor,
                    :collect_submissions,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              override: true, collect_current: true,
                              groupings: @assignment.groupings.to_a }
            expect(flash[:error]).to be_nil
          end

          it 'should succeed if it is before the global due date but collect_current is true' do
            @assignment.update!(due_date: 1.week.from_now)
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }
            post_as @instructor,
                    :collect_submissions,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              override: true, collect_current: true,
                              groupings: @assignment.groupings.to_a }
            expect(response).to have_http_status(:success)
          end

          it 'should succeed if it is after the global due date' do
            @assignment.update!(due_date: 1.week.ago)
            expect_any_instance_of(SubmissionsController).not_to receive(:flash_now).with(:error, anything)
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }

            post_as @instructor,
                    :collect_submissions,
                    params: { course_id: course.id, assignment_id: @assignment.id,
                              override: true, groupings: ([] << @assignment.groupings).flatten }
            expect(response).to have_http_status(:success)
          end
        end
      end
    end

    it 'download all files uploaded in a Zip file' do
      @file1_name = 'TestFile.java'
      @file2_name = 'SecondFile.go'
      @file1_content = "Some contents for TestFile.java\n"
      @file2_content = "Some contents for SecondFile.go\n"

      @group.access_repo do |repo|
        txn = repo.get_transaction('test')
        path = File.join(@assignment.repository_folder, @file1_name)
        txn.add(path, @file1_content, '')
        path = File.join(@assignment.repository_folder, @file2_name)
        txn.add(path, @file2_content, '')
        repo.commit(txn)

        # Generate submission
        @submission = Submission.generate_new_submission(
          @grouping,
          repo.get_latest_revision
        )
      end
      get_as @instructor,
             :downloads,
             params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: @grouping.id }

      expect(response.header['Content-Type']).to eq('application/zip')
      expect(subject).to respond_with(:success)
      revision_identifier = @grouping.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
      zip_path = "tmp/#{@assignment.short_identifier}_" \
                 "#{@grouping.group.group_name}_#{revision_identifier}.zip"
      Zip::File.open(zip_path) do |zip_file|
        expect(zip_file.find_entry(@file1_name)).not_to be_nil
        expect(zip_file.find_entry(@file2_name)).not_to be_nil

        expect(zip_file.read(@file1_name)).to eq(@file1_content)
        expect(zip_file.read(@file2_name)).to eq(@file2_content)
      end
    end

    it 'not be able to download an empty revision' do
      @group.access_repo do |repo|
        txn = repo.get_transaction('test')
        repo.commit(txn)

        # Generate submission
        @submission = Submission.generate_new_submission(
          @grouping,
          repo.get_latest_revision
        )
      end

      get_as @instructor,
             :downloads,
             params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: @grouping.id }

      expect(subject).to respond_with(:redirect)
    end

    it 'not be able to download the revision 0' do
      @group.access_repo do |repo|
        txn = repo.get_transaction('test')
        path = File.join(@assignment.repository_folder, 'file1_name')
        txn.add(path, 'file1 content', '')
        repo.commit(txn)

        # Generate submission
        @submission = Submission.generate_new_submission(
          @grouping,
          repo.get_latest_revision
        )
      end
      get_as @instructor,
             :downloads,
             params: { course_id: course.id, assignment_id: @assignment.id, grouping_id: @grouping.id,
                       revision_identifier: 0 }

      expect(subject).to respond_with(:redirect)
    end

    describe 'prepare and download a zip file' do
      let(:assignment) { create(:assignment) }
      let(:grouping_ids) do
        create_list(:grouping_with_inviter, 3, assignment: assignment).map.with_index do |grouping, i|
          submit_file(grouping.assignment, grouping, "file#{i}", "file#{i}'s content\n")
          grouping.id
        end
      end
      let(:unassigned_ta) { create(:ta) }
      let(:assigned_ta) do
        ta = create(:ta)
        grouping_ids # make sure groupings are created
        assignment.groupings.each do |grouping|
          create(:ta_membership, role: ta, grouping: grouping)
        end
        ta
      end

      describe '#zip_groupings_files' do
        it 'should be able to download all groups\' submissions' do
          expect(DownloadSubmissionsJob).to receive(:perform_later) do |grouping_ids, _zip_file, _assignment_id|
            expect(grouping_ids).to match_array(grouping_ids)
            DownloadSubmissionsJob.new
          end
          post_as @instructor, :zip_groupings_files,
                  params: { course_id: course.id, assignment_id: assignment.id, groupings: grouping_ids }
          expect(subject).to respond_with(:success)
        end

        it 'should be able to download a subset of the submissions' do
          subset = grouping_ids[0...2]
          expect(DownloadSubmissionsJob).to receive(:perform_later) do |grouping_ids, _zip_file, _assignment_id|
            expect(grouping_ids).to match_array(subset)
            DownloadSubmissionsJob.new
          end
          post_as @instructor, :zip_groupings_files,
                  params: { course_id: course.id, assignment_id: assignment.id, groupings: subset }
          expect(subject).to respond_with(:success)
        end

        it 'should - as Ta - be not able to download all groups\' submissions when unassigned' do
          expect(DownloadSubmissionsJob).to receive(:perform_later) do |grouping_ids, _zip_file, _assignment_id|
            expect(grouping_ids).to be_empty
            DownloadSubmissionsJob.new
          end
          post_as unassigned_ta, :zip_groupings_files,
                  params: { course_id: course.id, assignment_id: assignment.id, groupings: grouping_ids }
          expect(subject).to respond_with(:success)
        end

        it 'should - as Ta - be able to download all groups\' submissions when assigned' do
          expect(DownloadSubmissionsJob).to receive(:perform_later) do |gids, _zip_file, _assignment_id|
            expect(gids).to match_array(grouping_ids)
            DownloadSubmissionsJob.new
          end
          post_as assigned_ta, :zip_groupings_files,
                  params: { course_id: course.id, assignment_id: assignment.id, groupings: grouping_ids }
          expect(subject).to respond_with(:success)
        end

        it 'should create a zip file named after the current role and the assignment' do
          expect(DownloadSubmissionsJob).to receive(:perform_later) do |_grouping_ids, zip_file, _assignment_id|
            expect(zip_file).to include(assignment.short_identifier)
            expect(zip_file).to include(@instructor.user_name)
            DownloadSubmissionsJob.new
          end
          post_as @instructor, :zip_groupings_files,
                  params: { course_id: course.id, assignment_id: assignment.id, groupings: grouping_ids }
          expect(subject).to respond_with(:success)
        end

        it 'should pass the print parameter to DownloadSubmissionsJob when given' do
          expect(DownloadSubmissionsJob).to receive(:perform_later) do |_gids, _zip_file, _assignment_id, _course_id,
                                                                        kwargs|
            expect(kwargs[:print]).to be true
            DownloadSubmissionsJob.new
          end
          post_as assigned_ta, :zip_groupings_files,
                  params: { course_id: course.id, assignment_id: assignment.id, groupings: grouping_ids, print: 'true' }
          expect(subject).to respond_with(:success)
        end
      end

      describe '#download_zipped_file' do
        it 'should download a file name after the current role and the assignment' do
          expect(controller).to receive(:send_file) do |zip_file|
            expect(zip_file.to_s).to include(assignment.short_identifier)
            expect(zip_file.to_s).to include(@instructor.user_name)
          end
          post_as @instructor, :download_zipped_file, params: { course_id: course.id, assignment_id: assignment.id }
        end
      end
    end
  end

  describe 'An unauthenticated or unauthorized role' do
    let(:assignment) { create(:assignment) }

    it 'should not be able to download the repository checkout commands' do
      get :download_repo_checkout_commands, params: { course_id: course.id, assignment_id: assignment.id }
      expect(subject).to respond_with(:redirect)
    end

    it 'should not be able to download the repository list' do
      get :download_repo_list, params: { course_id: course.id, assignment_id: assignment.id }
      expect(subject).to respond_with(:redirect)
    end
  end

  describe '#download' do
    let(:assignment) { create(:assignment) }
    let(:instructor) { create(:instructor) }
    let(:grouping) { create(:grouping_with_inviter, assignment: assignment) }
    let(:file1) { fixture_file_upload('Shapes.java', 'text/java') }
    let(:file2) { fixture_file_upload('test_zip.zip', 'application/zip') }
    let(:file3) { fixture_file_upload('example.ipynb') }
    let(:file4) { fixture_file_upload('sample.markusurl') }
    let(:file5) { fixture_file_upload('example.Rmd') }

    before do
      [file1, file2, file3, file4, file5].each do |f|
        submit_file(assignment, grouping, f.original_filename, f.read)
      end
    end

    context 'When the file is in preview' do
      describe 'when the file is not a binary file' do
        it 'should display the file content' do
          get_as instructor, :download, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  file_name: 'Shapes.java',
                                                  preview: true,
                                                  grouping_id: grouping.id }
          expect(response.body).to eq(File.read(file1))
        end
      end

      describe 'When the file is a jupyter notebook file' do
        subject do
          get_as instructor, :download, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  file_name: 'example.ipynb',
                                                  preview: true,
                                                  grouping_id: grouping.id }
        end

        let(:redirect_location) do
          html_content_course_assignment_submissions_url(course_id: course.id,
                                                         assignment_id: assignment.id,
                                                         file_name: 'example.ipynb',
                                                         grouping_id: grouping.id)
        end

        context 'and the python dependencies are installed' do
          before { allow(Rails.application.config).to receive(:nbconvert_enabled).and_return(true) }

          it 'should redirect to "html_content"' do
            expect(subject).to redirect_to(redirect_location)
          end
        end

        context 'and the python dependencies are not installed' do
          before { allow(Rails.application.config).to receive(:nbconvert_enabled).and_return(false) }

          it 'should redirect to "html_content"' do
            expect(subject).not_to redirect_to(redirect_location)
          end
        end
      end

      describe 'When the file is a rmarkdown file' do
        subject do
          get_as instructor, :download, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  file_name: 'example.Rmd',
                                                  preview: true,
                                                  grouping_id: grouping.id }
        end

        let(:redirect_location) do
          html_content_course_assignment_submissions_url(course_id: course.id,
                                                         assignment_id: assignment.id,
                                                         file_name: 'example.Rmd',
                                                         grouping_id: grouping.id)
        end

        context 'and the rmd_convert_enabled flag is true' do
          before { allow(Rails.application.config).to receive(:rmd_convert_enabled).and_return(true) }

          it 'should redirect to "html_content"' do
            expect(subject).to redirect_to(redirect_location)
          end
        end

        context 'and the rmd_convert_enabled flag is false' do
          before { allow(Rails.application.config).to receive(:rmd_convert_enabled).and_return(false) }

          it 'should not redirect to "html_content"' do
            expect(subject).not_to redirect_to(redirect_location)
          end
        end
      end

      describe 'When the file is a binary file' do
        it 'should not display the contents of the compressed file' do
          get_as instructor, :download, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  file_name: 'test_zip.zip',
                                                  preview: true,
                                                  grouping_id: grouping.id }
          expect(response.body).to eq(I18n.t('submissions.cannot_display'))
        end
      end

      describe 'When the file is a url file' do
        it 'should read the entire file' do
          assignment.update!(url_submit: true)
          get_as instructor, :download, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  file_name: 'sample.markusurl',
                                                  preview: true,
                                                  grouping_id: grouping.id }
          expect(response.body).not_to eq(URI.extract(File.read(file4)).first)
        end
      end
    end

    context 'When the file is being downloaded' do
      describe 'when the file is not a binary file' do
        it 'should download the file' do
          get_as instructor, :download, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  file_name: 'Shapes.java',
                                                  preview: false,
                                                  grouping_id: grouping.id }
          expect(response.body).to eq(File.read(file1))
        end
      end

      describe 'When the file is a jupyter notebook file' do
        it 'should download the file as is' do
          get_as instructor, :download, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  file_name: 'example.ipynb',
                                                  preview: false,
                                                  grouping_id: grouping.id }
          expect(response.body).to eq(File.read(file3))
        end
      end

      describe 'When the file is a RMarkdown file' do
        it 'should download the file as is' do
          get_as instructor, :download, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  file_name: 'example.Rmd',
                                                  preview: false,
                                                  grouping_id: grouping.id }
          expect(response.body).to eq(File.read(file5))
        end
      end

      describe 'When the file is a binary file' do
        it 'should download all the contents of the zip file' do
          get_as instructor, :download, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  file_name: 'test_zip.zip',
                                                  preview: false,
                                                  grouping_id: grouping.id }
          grouping.group.access_repo do |repo|
            revision = repo.get_latest_revision
            file = revision.files_at_path(assignment.repository_folder)['test_zip.zip']
            content = repo.download_as_string(file)
            expect(response.body).to eq(content)
          end
        end
      end

      describe 'When the file is a url file' do
        it 'should download the file as is' do
          get_as instructor, :download, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  file_name: 'sample.markusurl',
                                                  preview: false,
                                                  grouping_id: grouping.id }
          expect(response.body).to eq(File.read(file4))
        end
      end
    end
  end

  describe '#html_content' do
    let(:assignment) { create(:assignment) }
    let(:instructor) { create(:instructor) }
    let(:grouping) { create(:grouping_with_inviter, assignment: assignment) }
    let(:file) { fixture_file_upload(filename) }
    let(:submission) { submit_file(assignment, grouping, file.original_filename, file.read) }

    shared_examples 'html content types' do
      shared_examples 'html content' do
        it 'is successful' do
          subject
          expect(response).to have_http_status(:success)
        end

        it 'renders the correct template' do
          expect(subject).to render_template('html_content')
        end
      end

      context 'a jupyter-notebook file',
              skip: Rails.application.config.nbconvert_enabled ? false : 'nbconvert dependencies not installed' do
        let(:filename) { 'example.ipynb' }

        it_behaves_like 'html content'
      end

      context 'a jupyter-notebook file with widgets',
              skip: Rails.application.config.nbconvert_enabled ? false : 'nbconvert dependencies not installed' do
        render_views
        let(:filename) { 'example_widgets.ipynb' }

        it 'renders without widgets' do
          subject
          expect(response.body).not_to include("KeyError: 'state'")
        end

        it_behaves_like 'html content'
      end

      context 'an rmarkdown file',
              skip: Rails.application.config.rmd_convert_enabled ? false : 'rmd_convert_enabled not set to true' do
        let(:filename) { 'example.Rmd' }

        it_behaves_like 'html content'
      end
    end

    context 'called with a collected submission' do
      subject do
        get_as instructor, :html_content,
               params: { course_id: course.id, assignment_id: assignment.id, select_file_id: submission_file.id }
      end

      let(:submission_file) { create(:submission_file, submission: submission, filename: filename) }

      it_behaves_like 'html content types'
    end

    context 'called with a revision identifier' do
      subject do
        get_as instructor, :html_content, params: { course_id: course.id,
                                                    assignment_id: assignment.id,
                                                    file_name: filename,
                                                    grouping_id: grouping.id,
                                                    revision_identifier: submission.revision_identifier }
      end

      it_behaves_like 'html content types'
    end

    context 'called with an invalid path for multiple file types' do
      ['example.ipynb', 'example.Rmd'].each do |test_filename|
        context "when the file is #{test_filename}" do
          subject do
            get_as instructor, :html_content, params: { course_id: course.id,
                                                        assignment_id: assignment.id,
                                                        file_name: filename,
                                                        grouping_id: grouping.id,
                                                        revision_identifier: submission.revision_identifier,
                                                        path: '../..' }
          end

          let(:filename) { test_filename }

          it 'flashes an error message' do
            subject
            expect(flash[:error]).to have_message(I18n.t('errors.invalid_path'))
          end
        end
      end
    end

    context 'where there is an invalid Jupyter notebook content' do
      render_views
      let(:filename) { 'pdf_with_ipynb_extension.ipynb' }

      it 'should display an invalid Jupyter notebook content error message' do
        get_as instructor, :html_content, params: { course_id: course.id,
                                                    assignment_id: assignment.id,
                                                    file_name: filename,
                                                    preview: true,
                                                    grouping_id: grouping.id,
                                                    revision_identifier: submission.revision_identifier }
        expect(response.body).to include(I18n.t('submissions.invalid_jupyter_notebook_content'))
      end
    end

    context 'where there is an invalid rmarkdown content' do
      render_views
      let(:filename) { 'pdf_with_rmd_extension.Rmd' }

      it 'should display a cannot display content error message' do
        get_as instructor, :html_content, params: { course_id: course.id,
                                                    assignment_id: assignment.id,
                                                    file_name: filename,
                                                    preview: true,
                                                    grouping_id: grouping.id,
                                                    revision_identifier: submission.revision_identifier }
        expect(response.body).to include(I18n.t('submissions.invalid_rmd_content'))
      end
    end
  end

  describe '#download_summary' do
    subject { get_as role, 'download_summary', params: { course_id: course.id, assignment_id: assignment.id } }

    let(:assignment) { create(:assignment) }
    let!(:groupings) { create_list(:grouping_with_inviter_and_submission, 2, assignment: assignment) }
    let(:returned_group_names) do
      header = nil
      groups = []
      MarkusCsv.parse(response.body) do |line|
        if header.nil?
          header = line
        else
          groups << header.zip(line).to_h[I18n.t('activerecord.models.group.one')]
        end
      end
      groups
    end

    context 'an instructor' do
      before { subject }

      let(:role) { create(:instructor) }

      it 'should be allowed' do
        expect(response).to have_http_status(:success)
      end

      it 'should download submission info for all groupings' do
        expect(returned_group_names).to match_array(groupings.map { |g| g.group.group_name })
      end

      it 'should not include hidden values' do
        header = nil
        MarkusCsv.parse(response.body) { |line| header ||= line }
        hidden = header.select { |h| h.start_with?('_') || h.end_with?('_id') }
        expect(hidden).to be_empty
      end
    end

    context 'a grader' do
      let(:role) { create(:ta) }

      it 'should be allowed' do
        subject
        expect(response).to have_http_status(:success)
      end

      context 'who has not been assigned any groupings' do
        it 'should download an empty csv' do
          subject
          expect(returned_group_names).to be_empty
        end
      end

      context 'who has been assigned a single grouping' do
        before { create(:ta_membership, role: role, grouping: groupings.first) }

        it 'should download the group info for the assigned group' do
          subject
          expect(returned_group_names).to contain_exactly(groupings.first.group.group_name)
        end
      end

      context 'who has been assigned all groupings' do
        before { groupings.each { |g| create(:ta_membership, role: role, grouping: g) } }

        it 'should download the group info for the assigned group' do
          subject
          expect(returned_group_names).to match_array(groupings.map { |g| g.group.group_name })
        end

        it 'should not include hidden values' do
          subject
          header = nil
          MarkusCsv.parse(response.body) { |line| header ||= line }
          hidden = header.select { |h| h.start_with?('_') || h.end_with?('_id') }
          expect(hidden).to be_empty
        end
      end
    end

    context 'a student' do
      before { subject }

      let(:role) { create(:student) }

      it 'should be forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#run_tests' do
    let(:assignment) { create(:assignment) }
    let(:instructor) { create(:instructor) }
    let(:grouping) { create(:grouping_with_inviter, assignment: assignment) }

    before do
      create(:version_used_submission, grouping: grouping, is_empty: false)
      assignment.update!(enable_test: true,
                         enable_student_tests: true,
                         unlimited_tokens: true,
                         token_start_date: 1.day.ago,
                         remote_autotest_settings_id: 1)
    end

    context 'at least one test-group can be run by instructors' do
      let(:assignment) { create(:assignment_with_test_groups_instructor_runnable) }

      it 'enqueues an AutotestRunJob' do
        params = { course_id: assignment.course_id, assignment_id: assignment.id, groupings: [grouping.id] }
        expect { post_as instructor, :run_tests, params: params }.to have_enqueued_job(AutotestRunJob)
      end
    end

    context 'no test-group can be run by instructors' do
      let(:assignment) { create(:assignment_with_test_groups_not_instructor_runnable) }

      it 'does not enqueue an AutotestRunJob' do
        params = { course_id: assignment.course_id, assignment_id: assignment.id, groupings: [grouping.id] }
        expect { post_as instructor, :run_tests, params: params }.not_to have_enqueued_job(AutotestRunJob)
      end
    end
  end

  def self.test_assigns_not_nil(key)
    it "should assign #{key}" do
      expect(assigns(key)).not_to be_nil
    end
  end

  def self.test_no_flash
    it 'should not display any flash messages' do
      expect(flash).to be_empty
    end
  end

  context 'file_download tests' do
    let(:course) { assignment.course }
    let(:assignment) { create(:assignment) }
    let(:student) { create(:student, grace_credits: 2) }
    let(:instructor) { create(:instructor) }
    let(:ta) { create(:ta) }
    let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: student) }
    let(:submission) { create(:version_used_submission, grouping: grouping) }
    let(:incomplete_result) { submission.current_result }
    let(:complete_result) { create(:complete_result, submission: submission) }
    let(:submission_file) { create(:submission_file, submission: submission) }
    let(:rubric_criterion) { create(:rubric_criterion, assignment: assignment) }
    let(:rubric_mark) { create(:rubric_mark, result: incomplete_result, criterion: rubric_criterion) }
    let(:flexible_criterion) { create(:flexible_criterion, assignment: assignment) }
    let(:flexible_mark) { create(:flexible_mark, result: incomplete_result, criterion: flexible_criterion) }
    let(:from_codeviewer) { nil }

    shared_examples 'download files' do
      context 'and without any file errors' do
        before do
          allow_any_instance_of(SubmissionFile).to receive(:retrieve_file).and_return SAMPLE_FILE_CONTENT
          get :download_file, params: { course_id: course.id,
                                        select_file_id: submission_file.id,
                                        from_codeviewer: from_codeviewer,
                                        id: submission.id, assignment_id: assignment.id }
        end

        it { expect(response).to have_http_status(:success) }

        test_no_flash
        it 'should have the correct content type' do
          expect(response.header['Content-Type']).to eq 'text/plain'
        end

        it 'should show the file content in the response body' do
          expect(response.body).to eq SAMPLE_FILE_CONTENT
        end
      end

      context 'with max content size parameter' do
        before do
          allow_any_instance_of(SubmissionFile).to receive(:retrieve_file).and_return SAMPLE_FILE_CONTENT
          get :download_file, params: { course_id: course.id,
                                        select_file_id: submission_file.id,
                                        from_codeviewer: from_codeviewer,
                                        id: submission.id,
                                        assignment_id: assignment.id,
                                        max_content_size: SAMPLE_FILE_CONTENT.size }
        end

        it { expect(response).to have_http_status(:success) }

        test_no_flash
        it 'should have the correct content type' do
          expect(response.header['Content-Type']).to eq 'text/plain'
        end

        it 'should show the file content in the response body' do
          expect(response.body).to eq SAMPLE_FILE_CONTENT
        end
      end

      context 'with max content size parameter less than the content size' do
        before do
          allow_any_instance_of(SubmissionFile).to receive(:retrieve_file).and_return SAMPLE_FILE_CONTENT
          get :download_file, params: { course_id: course.id,
                                        select_file_id: submission_file.id,
                                        from_codeviewer: from_codeviewer,
                                        id: submission.id,
                                        assignment_id: assignment.id,
                                        max_content_size: SAMPLE_FILE_CONTENT.size - 1 }
        end

        it { expect(response).to have_http_status(:payload_too_large) }

        it 'should have an empty response body' do
          expect(response.body).to be_empty
        end
      end

      context 'and with a file error' do
        before do
          allow_any_instance_of(SubmissionFile).to receive(:retrieve_file).and_raise SAMPLE_ERROR_MESSAGE
          get :download_file, params: { course_id: course.id,
                                        select_file_id: submission_file.id,
                                        from_codeviewer: from_codeviewer,
                                        id: submission.id, assignment_id: assignment.id }
        end

        it { expect(response).to have_http_status(:internal_server_error) }

        it 'should display a flash error' do
          expect(extract_text(flash[:error][0])).to eq SAMPLE_ERROR_MESSAGE
        end
      end

      context 'and with a supported image file shown in browser' do
        before do
          allow_any_instance_of(SubmissionFile).to receive(:is_supported_image?).and_return true
          allow_any_instance_of(SubmissionFile).to receive(:retrieve_file).and_return SAMPLE_FILE_CONTENT
          get :download_file, params: { course_id: course.id,
                                        select_file_id: submission_file.id,
                                        id: submission.id,
                                        assignment_id: assignment.id,
                                        from_codeviewer: from_codeviewer,
                                        show_in_browser: true }
        end

        it { expect(response).to have_http_status(:success) }

        test_no_flash
        it 'should have the correct content type' do
          expect(response.header['Content-Type']).to eq 'image'
        end

        it 'should show the file content in the response body' do
          expect(response.body).to eq SAMPLE_FILE_CONTENT
        end
      end

      context 'show in browser is true' do
        subject do
          get :download_file, params: { course_id: course.id,
                                        select_file_id: submission_file.id,
                                        id: submission.id, assignment_id: assignment.id,
                                        from_codeviewer: from_codeviewer,
                                        show_in_browser: true }
        end

        let(:submission_file) { create(:submission_file, filename: filename, submission: submission) }

        context 'file is a jupyter-notebook file' do
          let(:filename) { 'example.ipynb' }
          let(:redirect_location) do
            html_content_course_assignment_submissions_path(course,
                                                            assignment,
                                                            select_file_id: submission_file.id)
          end

          context 'and the python dependencies are installed' do
            before { allow(Rails.application.config).to receive(:nbconvert_enabled).and_return(true) }

            it 'should redirect to "html_content"' do
              expect(subject).to(redirect_to(redirect_location))
            end
          end

          context 'and the python dependencies are not installed' do
            before { allow(Rails.application.config).to receive(:nbconvert_enabled).and_return(false) }

            it 'should not redirect to "html_content"' do
              expect(subject).not_to(redirect_to(redirect_location))
            end
          end
        end

        context 'file is a RMarkdown file' do
          let(:filename) { 'example.Rmd' }
          let(:redirect_location) do
            html_content_course_assignment_submissions_path(course,
                                                            assignment,
                                                            select_file_id: submission_file.id)
          end

          context 'and the rmd_convert_enabled flag is true' do
            before { allow(Rails.application.config).to receive(:rmd_convert_enabled).and_return(true) }

            it 'should redirect to "html_content"' do
              expect(subject).to redirect_to(redirect_location)
            end
          end

          context 'and the rmd_convert_enabled flag is false' do
            before { allow(Rails.application.config).to receive(:rmd_convert_enabled).and_return(false) }

            it 'should not redirect to "html_content"' do
              expect(subject).not_to redirect_to(redirect_location)
            end
          end
        end
      end
    end

    shared_examples 'shared ta and instructor tests' do
      it_behaves_like 'download files'
      context 'accessing download_zip' do
        before do
          grouping.group.access_repo do |repo|
            txn = repo.get_transaction('test')
            path = File.join(assignment.repository_folder, SAMPLE_FILE_NAME)
            txn.add(path, SAMPLE_FILE_CONTENT, '')
            repo.commit(txn)
            @submission = Submission.generate_new_submission(grouping, repo.get_latest_revision)
          end
          file = SubmissionFile.find_by(submission_id: @submission.id)
          @annotation = TextAnnotation.create line_start: 1,
                                              line_end: 2,
                                              column_start: 1,
                                              column_end: 2,
                                              submission_file_id: file.id,
                                              is_remark: false,
                                              annotation_number: @submission.annotations.count + 1,
                                              annotation_text: create(:annotation_text, creator: instructor),
                                              result: complete_result,
                                              creator: instructor
          file_name_snippet = grouping.group.access_repo do |repo|
            "#{assignment.short_identifier}_#{grouping.group.group_name}" \
              "_r#{repo.get_latest_revision.revision_identifier}"
          end
          @file_path_ann = File.join 'tmp', "#{file_name_snippet}_ann.zip"
          @file_path = File.join 'tmp', "#{file_name_snippet}.zip"
          @submission_file_path = SAMPLE_FILE_NAME
        end

        after do
          FileUtils.rm_f @file_path_ann
          FileUtils.rm_f @file_path
        end

        context 'and including annotations' do
          before do
            get :download_file_zip, params: { course_id: course.id,
                                              id: @submission.id,
                                              assignment_id: assignment.id,
                                              grouping_id: grouping.id,
                                              include_annotations: 'true' }
          end

          after do
            FileUtils.rm_f @file_path_ann
          end

          it { expect(response).to have_http_status(:success) }

          it 'should have make the correct content type' do
            expect(response.header['Content-Type']).to eq 'application/zip'
          end

          it 'should create a zip file' do
            expect(File).to exist(@file_path_ann)
          end

          it 'should create a zip file containing the submission file' do
            Zip::File.open(@file_path_ann) do |zip_file|
              expect(zip_file.find_entry(@submission_file_path)).not_to be_nil
            end
          end

          it 'should include the annotations in the file output' do
            Zip::File.open(@file_path_ann) do |zip_file|
              expect(zip_file.read(@submission_file_path)).to include(@annotation.annotation_text.content)
            end
          end
        end

        context 'and not including annotations' do
          before do
            get :download_file_zip, params: { course_id: course.id,
                                              id: @submission.id,
                                              assignment_id: assignment.id,
                                              grouping_id: grouping.id,
                                              include_annotations: 'false' }
          end

          after do
            FileUtils.rm_f @file_path
          end

          it { expect(response).to have_http_status(:success) }

          it 'should have make the correct content type' do
            expect(response.header['Content-Type']).to eq 'application/zip'
          end

          it 'should create a zip file' do
            expect(File).to exist(@file_path)
          end

          it 'should create a zip file containing the submission file' do
            Zip::File.open(@file_path) do |zip_file|
              expect(zip_file.find_entry(@submission_file_path)).not_to be_nil
            end
          end

          it 'should not include the annotations in the file output' do
            Zip::File.open(@file_path) do |zip_file|
              expect(zip_file.read(@submission_file_path)).not_to include(@annotation.annotation_text.content)
            end
          end
        end
      end
    end

    context 'An Instructor' do
      before { sign_in instructor }

      it_behaves_like 'shared ta and instructor tests'
    end

    context 'A TA' do
      before { sign_in ta }

      context 'that cannot manage submissions and is not assigned to grade this groups submission' do
        context 'accessing download' do
          it {
            get :download_file, params: { course_id: course.id,
                                          select_file_id: submission_file.id,
                                          from_codeviewer: from_codeviewer,
                                          id: incomplete_result.submission.id,
                                          assignment_id: assignment.id }
            expect(response).to have_http_status(:forbidden)
          }
        end

        context 'accessing download_zip' do
          it {
            grouping.group.access_repo do |repo|
              txn = repo.get_transaction('test')
              path = File.join(assignment.repository_folder, SAMPLE_FILE_NAME)
              txn.add(path, SAMPLE_FILE_CONTENT, '')
              repo.commit(txn)
              @submission = Submission.generate_new_submission(grouping, repo.get_latest_revision)
            end
            get :download_file_zip, params: { course_id: course.id,
                                              id: @submission.id,
                                              assignment_id: assignment.id,
                                              grouping_id: grouping.id,
                                              include_annotations: 'true' }
            expect(response).to have_http_status(:forbidden)
          }
        end
      end

      context 'that has been assigned to grade the group\'s result' do
        before { create(:ta_membership, role: ta, grouping: grouping) }

        it_behaves_like 'shared ta and instructor tests'
      end

      context 'that can manage submissions' do
        let(:ta) { create(:ta, manage_submissions: true) }

        it_behaves_like 'shared ta and instructor tests'
      end
    end

    context 'A Student' do
      before { sign_in student }

      context 'downloading files' do
        shared_examples 'without permission' do
          before do
            get :download_file, params: { course_id: course.id,
                                          id: incomplete_result.submission.id,
                                          assignment_id: assignment.id,
                                          from_codeviewer: from_codeviewer,
                                          select_file_id: submission_file.id }
          end

          it { expect(response).to have_http_status(:forbidden) }
        end

        let(:assignment) { create(:assignment_with_peer_review_and_groupings_results) }
        let(:incomplete_result) { assignment.groupings.first.current_result }
        let(:submission) { incomplete_result.submission }

        context 'role is a reviewer for the current result' do
          let(:reviewer_grouping) { assignment.pr_assignment.groupings.first }
          let(:student) { reviewer_grouping.accepted_students.first }

          before { create(:peer_review, reviewer: reviewer_grouping, result: incomplete_result) }

          context 'from_codeviewer is true' do
            let(:from_codeviewer) { true }

            it_behaves_like 'download files'
          end

          context 'from_codeviewer is nil' do
            it_behaves_like 'without permission'
          end
        end

        context 'role is not a reviewer for the current result' do
          context 'role is an accepted member of the results grouping' do
            let(:student) { incomplete_result.grouping.accepted_students.first }

            context 'and the selected file is associated with the current submission' do
              let(:submission_file) { create(:submission_file, submission: incomplete_result.submission) }
              let(:grouping) { incomplete_result.grouping }

              it_behaves_like 'download files'
            end

            context 'and the selected file is associated with a different submission' do
              let(:submission_file) { create(:submission_file) }

              it {
                get :download_file, params: { course_id: course.id,
                                              id: incomplete_result.submission.id,
                                              assignment_id: assignment.id,
                                              from_codeviewer: from_codeviewer,
                                              select_file_id: submission_file.id }
                expect(response).to have_http_status(:not_found)
              }
            end
          end

          context 'role is not an accepted member of the results grouping' do
            let(:student) { create(:student) }

            it_behaves_like 'without permission'
          end
        end
      end

      it_behaves_like 'download files'
    end
  end

  context 'editing remark request status' do
    let(:course) { assignment.course }
    let(:assignment) { create(:assignment) }
    let(:student) { create(:student, grace_credits: 2) }
    let(:instructor) { create(:instructor) }
    let(:ta) { create(:ta) }
    let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: student) }
    let(:submission) { create(:version_used_submission, grouping: grouping) }
    let(:incomplete_result) { submission.current_result }
    let(:complete_result) { create(:complete_result, submission: submission) }
    let(:submission_file) { create(:submission_file, submission: submission) }
    let(:rubric_criterion) { create(:rubric_criterion, assignment: assignment) }
    let(:rubric_mark) { create(:rubric_mark, result: incomplete_result, criterion: rubric_criterion) }
    let(:flexible_criterion) { create(:flexible_criterion, assignment: assignment) }
    let(:flexible_mark) { create(:flexible_mark, result: incomplete_result, criterion: flexible_criterion) }
    let(:from_codeviewer) { nil }

    describe '#update_remark_request' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { allow_remarks: true }) }
      let(:grouping) { create(:grouping_with_inviter, assignment: assignment) }
      let(:student) { grouping.inviter }
      let(:submission) do
        s = create(:submission, grouping: grouping)
        s.get_original_result.update!(released_to_students: true)
        s
      end
      let(:result) { submission.get_original_result }

      context 'when saving a remark request message' do
        subject do
          patch_as student,
                   :update_remark_request,
                   params: { course_id: assignment.course_id,
                             id: submission.id,
                             assignment_id: assignment.id,
                             submission: { remark_request: 'Message' },
                             save: true }
        end

        before { subject }

        it 'updates the submission remark request message' do
          expect(submission.reload.remark_request).to eq 'Message'
        end

        it 'does not submit the remark request' do
          expect(submission.reload.remark_result).to be_nil
        end
      end

      context 'when submitting a remark request' do
        subject do
          patch_as student,
                   :update_remark_request,
                   params: { course_id: assignment.course_id,
                             id: submission.id,
                             assignment_id: assignment.id,
                             submission: { remark_request: 'Message' },
                             submit: true }
        end

        before { subject }

        it 'updates the submission remark request message' do
          expect(submission.reload.remark_request).to eq 'Message'
        end

        it 'submits the remark request' do
          expect(submission.reload.remark_result).not_to be_nil
        end

        it 'unreleases the original result' do
          expect(submission.get_original_result.reload.released_to_students).to be false
        end
      end
    end

    describe '#cancel_remark_request' do
      subject do
        delete_as student,
                  :cancel_remark_request,
                  params: { course_id: assignment.course_id,
                            id: submission.id,
                            assignment_id: assignment.id }
      end

      let(:assignment) { create(:assignment, assignment_properties_attributes: { allow_remarks: true }) }
      let(:grouping) { create(:grouping_with_inviter, assignment: assignment) }
      let(:student) { grouping.inviter }
      let(:submission) do
        s = create(:submission, grouping: grouping, remark_request: 'original message',
                                remark_request_timestamp: Time.current)
        s.make_remark_result
        s.results.reload
        s.remark_result.update!(marking_state: Result::MARKING_STATES[:incomplete])
        s.get_original_result.update!(released_to_students: false)

        s
      end

      before { subject }

      it 'destroys the remark result' do
        submission.non_pr_results.reload
        expect(submission.remark_result).to be_nil
      end

      it 'releases the original result' do
        expect(submission.get_original_result.reload.released_to_students).to be true
      end

      it 'redirects to the original result view' do
        expect(response).to redirect_to view_marks_course_result_path(course_id: assignment.course_id,
                                                                      id: submission.get_original_result.id)
      end
    end
  end
end
