describe SubmissionsController do
  after(:each) do
    destroy_repos
  end

  describe 'A student working alone' do
    before(:each) do
      @group = create(:group)
      @assignment = create(:assignment,
                           allow_web_submits: true,
                           group_min: 1)
      @grouping = create(:grouping,
                         group: @group,
                         assignment: @assignment)
      @membership = create(:student_membership,
                           membership_status: 'inviter',
                           grouping: @grouping)
      @student = @membership.user
      request.env['HTTP_REFERER'] = 'back'
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
      @assignment = create(:assignment,
                           allow_web_submits: true,
                           group_min: 1)
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
      get_as @ta_membership.user,
             :repo_browser,
             params: { assignment_id: @assignment.id, id: Grouping.last.id,
                       revision_identifier: Grouping.last.group.repo.get_latest_revision.revision_identifier,
                       path: '/' }
      is_expected.to respond_with(:success)
    end

    it 'should render with the assignment_content layout' do
      get_as @ta_membership.user,
             :repo_browser,
             params: { assignment_id: @assignment.id, id: Grouping.last.id,
                       revision_identifier: Grouping.last.group.repo.get_latest_revision.revision_identifier,
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
      @assignment = create(:assignment,
                           allow_web_submits: true,
                           group_min: 1)
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
      end

      it 'should be able to release submissions' do
        allow(Assignment).to receive(:find) { @assignment }
        post_as @admin,
                :update_submissions,
                params: { assignment_id: 1, groupings: ([] << @assignment.groupings).flatten, release_results: 'true' }
        is_expected.to respond_with(:success)
      end

      context 'of selected groupings' do
        it 'should get an error if no groupings are selected' do
          post_as @admin, :collect_submissions, params: { assignment_id: 1, groupings: [] }

          is_expected.to respond_with(:bad_request)
        end

        context 'with a section' do
          before(:each) do
            @section = create(:section, name: 's1')
            @student.section = @section
            @student.save
          end

          it 'should get an error if it is before the section due date' do
            allow(Assignment).to receive_message_chain(
              :includes, :find) { @assignment }
            expect(@assignment).to receive_message_chain(
              :submission_rule, :can_collect_now?).with(@section) { false }
            expect(@assignment).to receive(:short_identifier) { 'a1' }
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }

            post_as @admin,
                    :collect_submissions,
                    params: { assignment_id: 1, groupings: ([] << @assignment.groupings).flatten }

            expect(response).to render_template(:partial => 'shared/_poll_job.js.erb')
          end

          it 'should succeed if it is after the section due date' do
            allow(Assignment).to receive_message_chain(
              :includes, :find) { @assignment }
            expect(@assignment).to receive_message_chain(
              :submission_rule, :can_collect_now?).with(@section) { true }
            expect(@assignment).to receive(:short_identifier) { 'a1' }
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }

            post_as @admin,
                    :collect_submissions,
                    params: { assignment_id: 1, groupings: ([] << @assignment.groupings).flatten }

            expect(response).to render_template(:partial => 'shared/_poll_job.js.erb')
          end
        end

        context 'without a section' do
          before(:each) do
            @student.section = nil
            @student.save
          end

          it 'should get an error if it is before the global due date' do
            allow(Assignment).to receive_message_chain(
              :includes, :find) { @assignment }
            expect(@assignment).to receive_message_chain(
              :submission_rule, :can_collect_now?).with(nil) { false }
            expect(@assignment).to receive(:short_identifier) { 'a1' }
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }

            post_as @admin,
                    :collect_submissions,
                    params: { assignment_id: 1, groupings: ([] << @assignment.groupings).flatten }

            expect(response).to render_template(:partial => 'shared/_poll_job.js.erb')
          end

          it 'should succeed if it is after the global due date' do
            allow(Assignment).to receive_message_chain(
              :includes, :find) { @assignment }
            expect(@assignment).to receive_message_chain(
              :submission_rule, :can_collect_now?).with(nil) { true }
            expect(@assignment).to receive(:short_identifier) { 'a1' }
            allow(SubmissionsJob).to receive(:perform_later) { Struct.new(:job_id).new('1') }

            post_as @admin,
                    :collect_submissions,
                    params: { assignment_id: 1, groupings: ([] << @assignment.groupings).flatten }

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
      zip_path = "tmp/#{@assignment.short_identifier}_" +
                 "#{@grouping.group.group_name}_#{@grouping.group.repo
                     .get_latest_revision.revision_identifier}.zip"
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

    describe 'attempting to download groupings files' do
      before(:each) do
        @assignment = create(:assignment,
                             allow_web_submits: true,
                             group_min: 1)
        (1..3).to_a.each do |i|
          @grouping = create(:grouping,
                             assignment: @assignment)
          @student = create(:student)

          instance_variable_set(:"@student#{i}", @student)
          instance_variable_set(:"@grouping#{i}",
                                @grouping)
          @membership = create(:student_membership,
                               user: instance_variable_get(:"@student#{i}"),
                               membership_status: 'inviter',
                               grouping: instance_variable_get(
                                 :"@grouping#{i}"))
          submit_file(@assignment, instance_variable_get(:"@grouping#{i}"),
                      "file#{i}", "file#{i}'s content\n")
        end
      end

      it 'should be able to download all groups\' submissions' do
        get_as @admin, :download_groupings_files, params: { assignment_id: @assignment.id }
        is_expected.to respond_with(:success)
        zip_path = "tmp/#{@assignment.short_identifier}_" +
                   "#{@admin.user_name}.zip"
        Zip::File.open(zip_path) do |zip_file|
          (1..3).to_a.each do |i|
            instance_variable_set(
              :"@file#{i}_path",
              File.join(
                "#{instance_variable_get(:"@grouping#{i}").group.repo_name}/",
                "file#{i}"))
            expect(zip_file.find_entry(
                     instance_variable_get(:"@file#{i}_path"))).to_not be_nil
            expect("file#{i}'s content\n").to eq(
              zip_file.read(instance_variable_get(:"@file#{i}_path")))
          end
        end
      end
      it 'should - as Ta - be not able to download all groups\' submissions when unassigned' do
        @ta = create(:ta)
        get_as @ta, :download_groupings_files, params: { assignment_id: @assignment.id }
        is_expected.to respond_with(:success)
        zip_path = "tmp/#{@assignment.short_identifier}_" +
                   "#{@ta.user_name}.zip"
        Zip::File.open(zip_path) do |zip_file|
          (1..3).to_a.each do |i|
            instance_variable_set(
              :"@file#{i}_path",
              File.join(
                "#{instance_variable_get(:"@grouping#{i}").group.repo_name}/",
                "file#{i}"))
            expect(zip_file.find_entry(
                     instance_variable_get(:"@file#{i}_path"))).to be_nil
          end
        end
      end
      it 'should - as Ta - be able to download all groups\' submissions when assigned' do
        @ta = create(:ta)
        @assignment.groupings.each do |grouping|
          create(:ta_membership, user: @ta, grouping: grouping)
        end
        get_as @ta, :download_groupings_files, params: { assignment_id: @assignment.id }
        is_expected.to respond_with(:success)
        zip_path = "tmp/#{@assignment.short_identifier}_" +
          "#{@ta.user_name}.zip"
        Zip::File.open(zip_path) do |zip_file|
          (1..3).to_a.each do |i|
            instance_variable_set(
              :"@file#{i}_path",
              File.join(
                "#{instance_variable_get(:"@grouping#{i}").group.repo_name}/",
                "file#{i}"))
            expect(zip_file.find_entry(
              instance_variable_get(:"@file#{i}_path"))).to_not be_nil
            expect("file#{i}'s content\n").to eq(
              zip_file.read(instance_variable_get(:"@file#{i}_path")))
          end
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

private

def submit_file(assignment, grouping, filename = 'file', content = 'content')
  grouping.group.access_repo do |repo|
    txn = repo.get_transaction('test')
    path = File.join(assignment.repository_folder, filename)
    txn.add(path, content, '')
    repo.commit(txn)

    # Generate submission
    Submission.generate_new_submission(
      grouping, repo.get_latest_revision)
  end
end
