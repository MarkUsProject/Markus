describe SubmissionsController do
  after(:each) do
    destroy_repos
  end

  describe 'A student working alone' do
    before(:each) do
      @group = create(:group)
      @assignment = create(:assignment)
      @grouping = create(:grouping,
                         group: @group,
                         assignment: @assignment)
      @membership = create(:student_membership,
                           membership_status: 'inviter',
                           grouping: @grouping)
      @student = @membership.user
      request.env['HTTP_REFERER'] = 'back'
    end

    it 'should be rejected if it is a scanned assignment' do
      assignment = create(:assignment_for_scanned_exam)
      create(:grouping_with_inviter, inviter: @student, assignment: assignment)
      get_as @student, :file_manager, params: { assignment_id: assignment.id }
      expect(response).to have_http_status 403
    end

    it 'should be rejected if it is a timed assignment and the student has not yet started' do
      assignment = create(:timed_assignment)
      create(:grouping_with_inviter, inviter: @student, assignment: assignment)
      get_as @student, :file_manager, params: { assignment_id: assignment.id }
      expect(response).to have_http_status 403
    end

    it 'should not be rejected if it is a timed assignment and the student has started' do
      assignment = create(:timed_assignment)
      create(:grouping_with_inviter, inviter: @student, assignment: assignment, start_time: 10.minutes.ago)
      get_as @student, :file_manager, params: { assignment_id: assignment.id }
      expect(response).to have_http_status 200
    end

    it 'should be able to add and access files' do
      file_1 = fixture_file_upload(File.join('/files', 'Shapes.java'),
                                   'text/java')
      file_2 = fixture_file_upload(File.join('/files', 'TestShapes.java'),
                                   'text/java')

      expect(@student.has_accepted_grouping_for?(@assignment.id)).to be_truthy
      post_as @student, :update_files, params: { assignment_id: @assignment.id, new_files: [file_1, file_2] }

      is_expected.to respond_with(:redirect)

      # update_files action assert assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      expect(assigns :assignment).to_not be_nil
      expect(assigns :grouping).to_not be_nil
      expect(assigns :path).to_not be_nil
      expect(assigns :revision).to_not be_nil
      expect(assigns :files).to_not be_nil
      expect(assigns :missing_assignment_files).to_not be_nil

      # Check to see if the file was added
      @grouping.group.access_repo do |repo|
        revision = repo.get_latest_revision
        files = revision.files_at_path(@assignment.repository_folder)
        expect(files['Shapes.java']).to_not be_nil
        expect(files['TestShapes.java']).to_not be_nil
      end
    end

    context 'uploading a zip file' do
      let(:unzip) { 'true' }
      let(:tree) do
        zip_file = fixture_file_upload(File.join('/files', 'test_zip.zip'), 'application/zip')
        post_as @student, :update_files, params: { assignment_id: @assignment.id, new_files: [zip_file], unzip: unzip }
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
      get_as @student, :populate_file_manager, params: { assignment_id: @assignment.id }, format: 'json'
      is_expected.to respond_with(:success)
    end

    it 'should be able to access file manager page' do
      get_as @student, :file_manager, params: { assignment_id: @assignment.id }
      is_expected.to respond_with(:success)
      # file_manager action assert assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      expect(assigns :assignment).to_not be_nil
      expect(assigns :grouping).to_not be_nil
      expect(assigns :path).to_not be_nil
      expect(assigns :revision).to_not be_nil
      expect(assigns :files).to_not be_nil
      expect(assigns :missing_assignment_files).to_not be_nil
    end

    it 'should render with the assignment content layout' do
      get_as @student, :file_manager, params: { assignment_id: @assignment.id }
      expect(response).to render_template('layouts/assignment_content')
    end

    # TODO figure out how to test this test into the one above
    # TODO Figure out how to remove fixture_file_upload
    it 'should be able to replace files' do
      expect(@student.has_accepted_grouping_for?(@assignment.id)).to be_truthy

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
        old_file_1 = old_files['Shapes.java']
        old_file_2 = old_files['TestShapes.java']

        @file_1 = fixture_file_upload(File.join('/files', 'Shapes.java'),
                                      'text/java')
        @file_2 = fixture_file_upload(File.join('/files', 'TestShapes.java'),
                                      'text/java')

        post_as @student,
                :update_files,
                params: { assignment_id: @assignment.id, new_files: [@file_1, @file_2],
                          file_revisions: { 'Shapes.java' => old_file_1.from_revision,
                                            'TestShapes.java' => old_file_2.from_revision } }
      end
      is_expected.to respond_with(:redirect)

      expect(assigns :assignment).to_not be_nil
      expect(assigns :grouping).to_not be_nil
      expect(assigns :path).to_not be_nil
      expect(assigns :revision).to_not be_nil
      expect(assigns :files).to_not be_nil
      expect(assigns :missing_assignment_files).to_not be_nil

      @grouping.group.access_repo do |repo|
        revision = repo.get_latest_revision
        files = revision.files_at_path(@assignment.repository_folder)
        expect(files['Shapes.java']).to_not be_nil
        expect(files['TestShapes.java']).to_not be_nil

        # Test to make sure that the contents were successfully updated
        @file_1.rewind
        @file_2.rewind
        file_1_new_contents = repo.download_as_string(files['Shapes.java'])
        file_2_new_contents = repo.download_as_string(files['TestShapes.java'])

        expect(@file_1.read).to eq(file_1_new_contents)
        expect(@file_2.read).to eq(file_2_new_contents)
      end
    end

    it 'should be able to delete files' do
      expect(@student.has_accepted_grouping_for?(@assignment.id)).to be_truthy

      @grouping.group.access_repo do |repo|
        txn = repo.get_transaction('markus')
        txn.add(File.join(@assignment.repository_folder, 'Shapes.java'),
                'Content of Shapes.java')
        txn.add(File.join(@assignment.repository_folder, 'TestShapes.java'),
                'Content of TestShapes.java')
        repo.commit(txn)
        revision = repo.get_latest_revision
        old_files = revision.files_at_path(@assignment.repository_folder)
        old_file_1 = old_files['Shapes.java']
        old_file_2 = old_files['TestShapes.java']

        post_as @student,
                :update_files,
                params: { assignment_id: @assignment.id, delete_files: ['Shapes.java'],
                          file_revisions: { 'Shapes.java' => old_file_1.from_revision,
                                            'TestShapes.java' => old_file_2.from_revision } }
      end

      is_expected.to respond_with(:redirect)

      expect(assigns :assignment).to_not be_nil
      expect(assigns :grouping).to_not be_nil
      expect(assigns :path).to_not be_nil
      expect(assigns :revision).to_not be_nil
      expect(assigns :files).to_not be_nil
      expect(assigns :missing_assignment_files).to_not be_nil

      @grouping.group.access_repo do |repo|
        revision = repo.get_latest_revision
        files = revision.files_at_path(@assignment.repository_folder)
        expect(files['Shapes.java']).to be_nil
        expect(files['TestShapes.java']).to_not be_nil
      end
    end

    # Repository Browser Tests
    # TODO:  TEST REPO BROWSER HERE
    it 'should not be able to use the repository browser' do
      get_as @student, :repo_browser, params: { assignment_id: 1, id: Grouping.last.id }
      is_expected.to respond_with(:missing)
    end

    # Stopping a curious student
    it 'should not be able download svn checkout commands' do
      get_as @student, :download_repo_checkout_commands, params: { assignment_id: 1 }

      is_expected.to respond_with(:missing)
    end

    it 'should not be able to download the svn repository list' do
      get_as @student, :download_repo_list, params: { assignment_id: 1 }

      is_expected.to respond_with(:missing)
    end
  end

  describe 'A TA' do
    before(:each) do
      @group = create(:group)
      @assignment = create(:assignment)
      @grouping = create(:grouping,
                         group: @group,
                         assignment: @assignment)
      @membership = create(:student_membership,
                           membership_status: 'inviter',
                           grouping: @grouping)
      @student = @membership.user

      @grouping1 = create(:grouping,
                          assignment: @assignment)
      @grouping1.group.access_repo do |repo|
        txn = repo.get_transaction('test')
        path = File.join(@assignment.repository_folder, 'file1_name')
        txn.add(path, 'file1 content', '')
        repo.commit(txn)

        # Generate submission
        Submission.generate_new_submission(Grouping.last,
                                           repo.get_latest_revision)
      end
      @ta_membership = create(:ta_membership,
                              grouping: @grouping)
    end
    it 'should be able to access the repository browser.' do
      revision_identifier = Grouping.last.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
      get_as @ta_membership.user,
             :repo_browser,
             params: { assignment_id: @assignment.id, id: Grouping.last.id,
                       revision_identifier: revision_identifier,
                       path: '/' }
      is_expected.to respond_with(:success)
    end

    it 'should render with the assignment_content layout' do
      revision_identifier = Grouping.last.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
      get_as @ta_membership.user,
             :repo_browser,
             params: { assignment_id: @assignment.id, id: Grouping.last.id,
                       revision_identifier: revision_identifier,
                       path: '/' }
      expect(response).to render_template('layouts/assignment_content')
    end

    it 'should be able to download the svn checkout commands' do
      get_as @ta_membership.user, :download_repo_checkout_commands, params: { assignment_id: 1 }
      is_expected.to respond_with(:missing)
    end

    it 'should be able to download the svn repository list' do
      get_as @ta_membership.user, :download_repo_list, params: { assignment_id: 1 }
      is_expected.to respond_with(:missing)
    end
  end

  describe 'An administrator' do
    before(:each) do
      @group = create(:group)
      @assignment = create(:assignment)
      @grouping = create(:grouping,
                         group: @group,
                         assignment: @assignment)
      @membership = create(:student_membership,
                           membership_status: 'inviter',
                           grouping: @grouping)
      @student = @membership.user
      @admin = create(:admin)
      @csv_options = {
        type: 'text/csv',
        disposition: 'attachment',
        filename: "#{@assignment.short_identifier}_simple_report.csv"
      }
    end

    it 'should be able to access the repository browser' do
      get_as @admin, :repo_browser, params: { assignment_id: @assignment.id, id: Grouping.last.id, path: '/' }
      is_expected.to respond_with(:success)
    end

    it 'should render with the assignment_content layout' do
      get_as @admin, :repo_browser, params: { assignment_id: @assignment.id, id: Grouping.last.id, path: '/' }
      expect(response).to render_template(layout: 'layouts/assignment_content')
    end

    it 'should be able to download the svn checkout commands' do
      get_as @admin, :download_repo_checkout_commands, params: { assignment_id: @assignment.id }
      is_expected.to respond_with(:success)
    end

    it 'should be able to download the svn repository list' do
      get_as @admin, :download_repo_list, params: { assignment_id: @assignment.id }
      is_expected.to respond_with(:success)
    end

    describe 'attempting to collect submissions' do
      before(:each) do
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

      context '#set_result_marking_state' do
        let(:marking_state) { Result::MARKING_STATES[:complete] }
        let(:released_to_students) { false }
        let(:new_marking_state) { Result::MARKING_STATES[:incomplete] }
        before :each do
          @current_result = @grouping.current_result
          @current_result.update!(marking_state: marking_state, released_to_students: released_to_students)
          post_as @admin, :set_result_marking_state, params: { assignment_id: @assignment.id,
                                                               groupings: [@grouping.id],
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

      context 'where a grouping does not have a previously collected submission' do
        let(:uncollected_grouping) { create(:grouping, assignment: @assignment) }
        before(:each) do
          uncollected_grouping.group.access_repo do |repo|
            txn = repo.get_transaction('test')
            path = File.join(@assignment.repository_folder, 'file1_name')
            txn.add(path, 'file1 content', '')
            repo.commit(txn)
          end
        end

        it 'should collect all groupings when override is true' do
          @assignment.update!(due_date: Time.current - 1.week)
          allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }
          expect(SubmissionsJob).to receive(:perform_later).with(
            array_including(@grouping, uncollected_grouping),
            collection_dates: hash_including
          )
          post_as @admin, :collect_submissions, params: { assignment_id: @assignment.id,
                                                          groupings: [@grouping.id, uncollected_grouping.id],
                                                          override: true }
        end

        it 'should collect the uncollected grouping only when override is false' do
          @assignment.update!(due_date: Time.current - 1.week)
          allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }
          expect(SubmissionsJob).to receive(:perform_later).with(
            [uncollected_grouping],
            collection_dates: hash_including
          )
          post_as @admin, :collect_submissions, params: { assignment_id: @assignment.id,
                                                          groupings: [@grouping.id, uncollected_grouping.id],
                                                          override: false }
        end
      end

      context 'when updating students on submission results' do
        it 'should be able to release submissions' do
          allow(Assignment).to receive(:find) { @assignment }
          post_as @admin,
                  :update_submissions,
                  params: { assignment_id: 1,
                            groupings: ([] << @assignment.groupings).flatten,
                            release_results: 'true' }
          is_expected.to respond_with(:success)
        end
        context 'with one grouping selected' do
          it 'sends an email to the student if only one student exists in the grouping' do
            expect do
              post_as @admin,
                      :update_submissions,
                      params: { assignment_id: @assignment.id,
                                groupings: ([] << @assignment.groupings).flatten,
                                release_results: 'true' }
            end.to change { ActionMailer::Base.deliveries.count }.by(1)
          end
          it 'sends an email to every student in a grouping if it has multiple students' do
            create(:student_membership, membership_status: 'inviter', grouping: @grouping)
            expect do
              post_as @admin,
                      :update_submissions,
                      params: { assignment_id: @assignment.id,
                                groupings: ([] << @assignment.groupings).flatten,
                                release_results: 'true' }
            end.to change { ActionMailer::Base.deliveries.count }.by(2)
          end
          it 'does not send an email to some students in a grouping if some have emails disabled' do
            another_membership = create(:student_membership, membership_status: 'inviter', grouping: @grouping)
            another_membership.user.update!(receives_results_emails: false)
            expect do
              post_as @admin,
                      :update_submissions,
                      params: { assignment_id: @assignment.id,
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
              post_as @admin,
                      :update_submissions,
                      params: { assignment_id: @assignment.id,
                                groupings: ([] << @assignment.groupings).flatten,
                                release_results: 'true' }
            end.to change { ActionMailer::Base.deliveries.count }.by(2)
          end
          it 'does not email some students in some groupings if those students have them disabled' do
            other_grouping = create(:grouping, assignment: @assignment)
            other_membership = create(:student_membership, membership_status: 'inviter', grouping: other_grouping)
            other_membership.user.update!(receives_results_emails: false)
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
              post_as @admin,
                      :update_submissions,
                      params: { assignment_id: @assignment.id,
                                groupings: ([] << @assignment.groupings).flatten,
                                release_results: 'true' }
            end.to change { ActionMailer::Base.deliveries.count }.by(1)
          end
        end
      end

      context 'of selected groupings' do
        it 'should get an error if no groupings are selected' do
          post_as @admin, :collect_submissions, params: { assignment_id: 1, groupings: [] }

          is_expected.to respond_with(:bad_request)
        end

        context 'with a section' do
          before(:each) do
            @section = create(:section, name: 's1')
            @section_due_date = create(:section_due_date, section: @section, assignment: @assignment)
            @student.section = @section
            @student.save
          end

          it 'should get an error if it is before the section due date' do
            @section_due_date.update!(due_date: Time.current + 1.week)
            allow(Assignment).to receive_message_chain(
              :includes, :find) { @assignment }
            expect_any_instance_of(SubmissionsController).to receive(:flash_now).with(:error, anything)
            expect(@assignment).to receive(:short_identifier) { 'a1' }
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }

            post_as @admin,
                    :collect_submissions,
                    params: { assignment_id: 1, override: true, groupings: ([] << @assignment.groupings).flatten }

            expect(response).to render_template(:partial => 'shared/_poll_job.js.erb')
          end

          it 'should succeed if it is after the section due date' do
            @section_due_date.update!(due_date: Time.current - 1.week)
            allow(Assignment).to receive_message_chain(
              :includes, :find) { @assignment }
            expect_any_instance_of(SubmissionsController).not_to receive(:flash_now).with(:error, anything)
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }

            post_as @admin,
                    :collect_submissions,
                    params: { assignment_id: 1, override: true, groupings: ([] << @assignment.groupings).flatten }

            expect(response).to render_template(:partial => 'shared/_poll_job.js.erb')
          end
        end

        context 'without a section' do
          before(:each) do
            @student.section = nil
            @student.save
          end

          it 'should get an error if it is before the global due date' do
            @assignment.update!(due_date: Time.current + 1.week)
            allow(Assignment).to receive_message_chain(
              :includes, :find) { @assignment }
            expect(@assignment).to receive(:short_identifier) { 'a1' }
            expect_any_instance_of(SubmissionsController).to receive(:flash_now).with(:error, anything)
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }

            post_as @admin,
                    :collect_submissions,
                    params: { assignment_id: 1, override: true, groupings: ([] << @assignment.groupings).flatten }

            expect(response).to render_template(:partial => 'shared/_poll_job.js.erb')
          end

          it 'should succeed if it is after the global due date' do
            @assignment.update!(due_date: Time.current - 1.week)
            allow(Assignment).to receive_message_chain(
              :includes, :find) { @assignment }
            expect_any_instance_of(SubmissionsController).not_to receive(:flash_now).with(:error, anything)
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }

            post_as @admin,
                    :collect_submissions,
                    params: { assignment_id: 1, override: true, groupings: ([] << @assignment.groupings).flatten }

            expect(response).to render_template(:partial => 'shared/_poll_job.js.erb')
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
          repo.get_latest_revision)
      end
      get_as @admin,
             :downloads,
             params: { assignment_id: @assignment.id, id: @submission.id, grouping_id: @grouping.id }

      expect('application/zip').to eq(response.header['Content-Type'])
      is_expected.to respond_with(:success)
      revision_identifier = @grouping.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
      zip_path = "tmp/#{@assignment.short_identifier}_" +
                 "#{@grouping.group.group_name}_#{revision_identifier}.zip"
      Zip::File.open(zip_path) do |zip_file|
        file1_path = File.join("#{@assignment.short_identifier}-" +
                                   "#{@grouping.group.group_name}",
                               @file1_name)
        file2_path = File.join("#{@assignment.short_identifier}-" +
                                   "#{@grouping.group.group_name}",
                               @file2_name)
        expect(zip_file.find_entry(file1_path)).to_not be_nil
        expect(zip_file.find_entry(file2_path)).to_not be_nil

        expect(zip_file.read(file1_path)).to eq(@file1_content)
        expect(zip_file.read(file2_path)).to eq(@file2_content)
      end
    end

    it 'not be able to download an empty revision' do
      @group.access_repo do |repo|
        txn = repo.get_transaction('test')
        repo.commit(txn)

        # Generate submission
        @submission = Submission.generate_new_submission(
          @grouping,
          repo.get_latest_revision)
      end

      request.env['HTTP_REFERER'] = 'back'
      get_as @admin,
             :downloads,
             params: { assignment_id: @assignment.id, id: @submission.id, grouping_id: @grouping.id }

      is_expected.to respond_with(:redirect)
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
          repo.get_latest_revision)
      end
      request.env['HTTP_REFERER'] = 'back'
      get_as @admin,
             :downloads,
             params: { assignment_id: @assignment.id, id: @submission.id, grouping_id: @grouping.id,
                       revision_identifier: 0 }

      is_expected.to respond_with(:redirect)
    end

    describe 'prepare and download a zip file' do
      let(:assignment) { create :assignment }
      let(:grouping_ids) do
        create_list(:grouping_with_inviter, 3, assignment: assignment).map.with_index do |grouping, i|
          submit_file(grouping.assignment, grouping, "file#{i}", "file#{i}'s content\n")
          grouping.id
        end
      end
      let(:unassigned_ta) { create :ta }
      let(:assigned_ta) do
        ta = create :ta
        grouping_ids # make sure groupings are created
        assignment.groupings.each do |grouping|
          create(:ta_membership, user: ta, grouping: grouping)
        end
        ta
      end

      describe '#zip_groupings_files' do
        it 'should be able to download all groups\' submissions' do
          expect(DownloadSubmissionsJob).to receive(:perform_later) do |grouping_ids, _zip_file, _assignment_id|
            expect(grouping_ids).to contain_exactly(*grouping_ids)
            DownloadSubmissionsJob.new
          end
          post_as @admin, :zip_groupings_files, params: { assignment_id: assignment.id, groupings: grouping_ids }
          is_expected.to respond_with(:success)
        end

        it 'should be able to download a subset of the submissions' do
          subset = grouping_ids[0...2]
          expect(DownloadSubmissionsJob).to receive(:perform_later) do |grouping_ids, _zip_file, _assignment_id|
            expect(grouping_ids).to contain_exactly(*subset)
            DownloadSubmissionsJob.new
          end
          post_as @admin, :zip_groupings_files, params: { assignment_id: assignment.id, groupings: subset }
          is_expected.to respond_with(:success)
        end

        it 'should - as Ta - be not able to download all groups\' submissions when unassigned' do
          expect(DownloadSubmissionsJob).to receive(:perform_later) do |grouping_ids, _zip_file, _assignment_id|
            expect(grouping_ids).to be_empty
            DownloadSubmissionsJob.new
          end
          post_as unassigned_ta, :zip_groupings_files, params: { assignment_id: assignment.id, groupings: grouping_ids }
          is_expected.to respond_with(:success)
        end

        it 'should - as Ta - be able to download all groups\' submissions when assigned' do
          expect(DownloadSubmissionsJob).to receive(:perform_later) do |gids, _zip_file, _assignment_id|
            expect(gids).to contain_exactly(*grouping_ids)
            DownloadSubmissionsJob.new
          end
          post_as assigned_ta, :zip_groupings_files, params: { assignment_id: assignment.id, groupings: grouping_ids }
          is_expected.to respond_with(:success)
        end

        it 'should create a zip file named after the current user and the assignment' do
          expect(DownloadSubmissionsJob).to receive(:perform_later) do |_grouping_ids, zip_file, _assignment_id|
            expect(zip_file).to include(assignment.short_identifier)
            expect(zip_file).to include(@admin.user_name)
            DownloadSubmissionsJob.new
          end
          post_as @admin, :zip_groupings_files, params: { assignment_id: assignment.id, groupings: grouping_ids }
          is_expected.to respond_with(:success)
        end
      end

      describe '#download_zipped_file' do
        it 'should download a file name after the current user and the assignment' do
          expect(controller).to receive(:send_file) do |zip_file|
            expect(zip_file.to_s).to include(assignment.short_identifier)
            expect(zip_file.to_s).to include(@admin.user_name)
          end
          post_as @admin, :download_zipped_file, params: { assignment_id: assignment.id }
        end
      end
    end
  end

  describe 'An unauthenticated or unauthorized user' do
    it 'should not be able to download the svn checkout commands' do
      get :download_repo_checkout_commands, params: { assignment_id: 1 }
      is_expected.to respond_with(:redirect)
    end

    it 'should not be able to download the svn repository list' do
      get :download_repo_list, params: { assignment_id: 1 }
      is_expected.to respond_with(:redirect)
    end
  end
end

