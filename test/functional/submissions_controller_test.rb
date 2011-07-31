require File.dirname(__FILE__) + '/authenticated_controller_test'
require File.join(File.dirname(__FILE__),'/../test_helper')
require File.join(File.dirname(__FILE__),'/../blueprints/blueprints')
require File.join(File.dirname(__FILE__),'/../blueprints/helper')
require 'fastercsv'
require 'shoulda'
require 'mocha'

class SubmissionsControllerTest < AuthenticatedControllerTest
  def setup
    clear_fixtures
  end

  context "I am a student trying working alone on an assignment" do
    setup do
      @group = Group.make
      @assignment = Assignment.make(:allow_web_submits => true, :group_min => 1)
      @grouping = Grouping.make(:group => @group, :assignment => @assignment)
      @membership = StudentMembership.make(:membership_status => 'inviter', :grouping => @grouping)
      @student = @membership.user
    end
    context "and I should be able to access the file manager page" do
      setup do
        get_as(@student, :file_manager, {:id => @assignment.id})
      end
      should respond_with :success
      # file_manager action should assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      should assign_to :assignment
      should assign_to :grouping
      should assign_to :path
      should assign_to :revision
      should assign_to :files
      should assign_to :missing_assignment_files
    end
    context "and I should be able to populate file" do
      setup do
        get_as(@student, :populate_file_manager, {:id => @assignment.id})
      end
      should respond_with :success
    end

    #TODO Figure out how to remove fixture_file_upload
    context "and I should be able to add files" do
      setup do
        file_1 = fixture_file_upload(File.join('..', 'files', 'Shapes.java'), 'text/java')
        file_2 = fixture_file_upload(File.join('..', 'files', 'TestShapes.java'), 'text/java')
        assert @student.has_accepted_grouping_for?(@assignment.id)
        post_as(@student, :update_files, {:id => @assignment.id, :new_files => [file_1, file_2]})
      end

      # must not respond with redirect_to (see comment in
      # app/controllers/submission_controller.rb#update_files)
      should respond_with :success

      # update_files action should assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      should assign_to :assignment
      should assign_to :grouping
      should assign_to :path
      should assign_to :revision
      should assign_to :files
      should assign_to :missing_assignment_files

      should "have added files accordingly" do
        # Check to see if the file was added
        @grouping.group.access_repo do |repo|
          revision = repo.get_latest_revision
          files = revision.files_at_path(@assignment.repository_folder)
          assert_not_nil files['Shapes.java']
          assert_not_nil files['TestShapes.java']
        end
      end
    end

    #TODO figure out how to test this test into the one above
    #TODO Figure out how to remove fixture_file_upload
    context "and I should be able to replace files" do
      setup do
        assert @student.has_accepted_grouping_for?(@assignment.id)

        @grouping.group.access_repo do |repo|
          txn = repo.get_transaction('markus')
          txn.add(File.join(@assignment.repository_folder,'Shapes.java'), 'Content of Shapes.java')
          txn.add(File.join(@assignment.repository_folder, 'TestShapes.java'), 'Content of TestShapes.java')
          repo.commit(txn)

          revision = repo.get_latest_revision
          old_files = revision.files_at_path(@assignment.repository_folder)
          old_file_1 = old_files['Shapes.java']
          old_file_2 = old_files['TestShapes.java']

          @file_1 = fixture_file_upload(File.join('..', 'files', 'Shapes.java'), 'text/java')
          @file_2 = fixture_file_upload(File.join('..', 'files', 'TestShapes.java'), 'text/java')

          post_as(@student, :update_files, { :id => @assignment.id,
            :replace_files => { 'Shapes.java' =>      @file_1,
                                'TestShapes.java' =>  @file_2},
            :file_revisions => {'Shapes.java' =>      old_file_1.from_revision,
                                'TestShapes.java' =>  old_file_2.from_revision}})

        end
      end

      # must not respond with redirect_to (see comment in
      # app/controllers/submission_controller.rb#update_files)
      should respond_with :success

      # update_files action should assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      should assign_to :assignment
      should assign_to :grouping
      should assign_to :path
      should assign_to :revision
      should assign_to :files
      should assign_to :missing_assignment_files

      should "have replaced files accordingly" do
        @grouping.group.access_repo do |repo|
          revision = repo.get_latest_revision
          files = revision.files_at_path(@assignment.repository_folder)
          assert_not_nil files['Shapes.java']
          assert_not_nil files['TestShapes.java']

          # Test to make sure that the contents were successfully updated
          @file_1.rewind
          @file_2.rewind
          file_1_new_contents = repo.download_as_string(files['Shapes.java'])
          file_2_new_contents = repo.download_as_string(files['TestShapes.java'])

          assert_equal @file_1.read, file_1_new_contents
          assert_equal @file_2.read, file_2_new_contents
        end
      end
    end
    context "and I should be able to delete files" do
      setup do
        assert @student.has_accepted_grouping_for?(@assignment.id)

        @grouping.group.access_repo do |repo|
          txn = repo.get_transaction('markus')
          txn.add(File.join(@assignment.repository_folder,'Shapes.java'), 'Content of Shapes.java')
          txn.add(File.join(@assignment.repository_folder, 'TestShapes.java'), 'Content of TestShapes.java')
          repo.commit(txn)
          revision = repo.get_latest_revision
          old_files = revision.files_at_path(@assignment.repository_folder)
          old_file_1 = old_files['Shapes.java']
          old_file_2 = old_files['TestShapes.java']

          post_as(@student, :update_files, {:id => @assignment.id,
            :delete_files => {  'Shapes.java' => true},
            :file_revisions => {'Shapes.java' => old_file_1.from_revision,
                                'TestShapes.java' => old_file_2.from_revision}})
        end
      end

      # must not respond with redirect_to (see comment in
      # app/controllers/submission_controller.rb#update_files)
      should respond_with :success

      # update_files action should assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      should assign_to :assignment
      should assign_to :grouping
      should assign_to :path
      should assign_to :revision
      should assign_to :files
      should assign_to :missing_assignment_files

      should "have deleted files accordingly" do
        @grouping.group.access_repo do |repo|
          revision = repo.get_latest_revision
          files = revision.files_at_path(@assignment.repository_folder)
          assert_not_nil files['TestShapes.java']
          assert_nil files['Shapes.java']
        end
      end
    end
    context "and I cannot add a file that exists" do
      setup do
        assert @student.has_accepted_grouping_for?(@assignment.id)

        @grouping.group.access_repo do |repo|
          txn = repo.get_transaction('markus')
          txn.add(File.join(@assignment.repository_folder,'Shapes.java'), 'Content of Shapes.java')
          txn.add(File.join(@assignment.repository_folder, 'TestShapes.java'), 'Content of TestShapes.java')
          repo.commit(txn)

          file_1 = fixture_file_upload(File.join('..', 'files', 'Shapes.java'), 'text/java')
          file_2 = fixture_file_upload(File.join('..', 'files', 'TestShapes.java'), 'text/java')
          assert @student.has_accepted_grouping_for?(@assignment.id)
          post_as(@student, :update_files, {:id => @assignment.id, :new_files => [file_1, file_2]})
        end
      end

      # must not respond with redirect_to (see comment in
      # app/controllers/submission_controller.rb#update_files)
      should respond_with :success

      # update_files action should assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      should assign_to :assignment
      should assign_to :grouping
      should assign_to :path
      should assign_to :revision
      should assign_to :files
      should assign_to :missing_assignment_files
      should assign_to :file_manager_errors

      should "not have added the file and set the file_manager_errors hash properly" do
        file_manager_errors = assigns["file_manager_errors"]
        @grouping.group.access_repo do |repo|
          # Check to see if the file was added
          assert @grouping.is_valid?

          revision = repo.get_latest_revision
          files = revision.files_at_path(@assignment.repository_folder)
          assert_not_nil files['Shapes.java']
          assert_not_nil files['TestShapes.java']
          assert_not_nil file_manager_errors[:update_conflicts]
        end
      end
    end
    # TODO:  Test that a student can't replace file if out of sync
    # TODO:  Test that a student can't replace a file if the new file
    #         has a different name

    # Repository Browser Tests
    # TODO:  TEST REPO BROWSER HERE
    context "and I cannot use the repository browser" do
      setup do
        get_as(@student, :repo_browser, {:id => Grouping.last.id})
      end
      should respond_with :missing
    end

    context "and I cannot use the populate repository browser." do
      setup do
        get_as(@student, :populate_repo_browser, {:id => Grouping.first.id})
      end
      should respond_with :missing
    end

    # Stopping a curious student
    context "and I cannot access a simple csv report" do
      setup do
        get_as @student, :download_simple_csv_report
      end

      should respond_with :missing
    end

    context "and I cannot access a detailed csv report." do
      setup do
        get_as @student, :download_detailed_csv_report
      end

      should respond_with :missing
    end

    context "and I cannot download svn export commands" do
      setup do
        get_as @student, :download_svn_export_commands
      end

      should respond_with :missing
    end

    context "and I cannot download the svn repository list" do
      setup do
        get_as @student, :download_svn_repo_list
      end

      should respond_with :missing
    end

    context "and I have a grader. My grade should be able to" do
      setup do
        @ta_membership = TaMembership.make(:membership_status => :accepted, :grouping => @grouping)
        @grader = @ta_membership.user
      end

      context "access the repository browser." do
        setup do
          get_as(@grader, :repo_browser, {:id => Grouping.last.id})
        end
        should respond_with :success
      end


      context "access the populate repository browser." do
        setup do
          get_as(@grader, :populate_repo_browser, {:id => Grouping.first.id})
        end
        should respond_with :success
      end

      context "download a simple csv report" do
        setup do
          get_as @grader, :download_simple_csv_report
        end
        should respond_with :missing
      end

      context "download a detailed csv report" do
        setup do
          get_as @grader, :download_detailed_csv_report
        end
        should respond_with :missing
      end

      context "download the svn export commands" do
        setup do
          get_as @grader, :download_svn_export_commands
        end
        should respond_with :missing
      end

      context "download the svn repository list" do
        setup do
          get_as @grader, :download_svn_repo_list
        end
        should respond_with :missing
      end

      context "to collect all their assigned submissions at once" do

        context "before collection date" do
          setup do
            Assignment.stubs(:find).returns(@assignment)
            @assignment.expects(:short_identifier).once.returns('a1')
            @assignment.submission_rule.expects(:can_collect_now?).once.returns(false)
            get_as @grader, :collect_ta_submissions, :id => 1
          end
          should set_the_flash.to(I18n.t("collect_submissions.could_not_collect",
              :assignment_identifier => 'a1'))
          should respond_with :redirect
        end

        context "after assignment due date" do
          setup do
            @submission_collector = SubmissionCollector.instance
            Assignment.stubs(:find).returns(@assignment)
            SubmissionCollector.expects(:instance).returns(@submission_collector)
            @assignment.expects(:short_identifier).once.returns('a1')
            @assignment.submission_rule.expects(:can_collect_now?).once.returns(true)
            @submission_collector.expects(:push_groupings_to_queue).once
            get_as @grader, :collect_ta_submissions, :id => 1
          end
          should set_the_flash.to(I18n.t("collect_submissions.collection_job_started",
              :assignment_identifier => 'a1'))
          should respond_with :redirect
        end

      end
    end

    context "and I have an instructor." do
      # TODO:

      # Test whether or not an Instructor can release/unrelease results correctly
      # Test whether or not an Instructor can download files from student repos
      setup do
        @admin = Admin.make
      end
      context "My instructor should be able to access the populate repository browser." do
        setup do
          get_as(@admin, :populate_repo_browser, {:id => Grouping.first.id})
        end
        should respond_with :success
      end
      context "My instructor should be able to download the simple csv report." do
        setup do
          get_as @admin, :download_simple_csv_report, :id => @assignment.id
        end
        should respond_with :success
      end

      context "My instructor should be able to download the detailed csv report." do
        setup do
          get_as @admin, :download_detailed_csv_report, :id => @assignment.id
        end
        should respond_with :success
      end

      context "My instructor should be able to download the svn export commands." do
        setup do
          get_as @admin, :download_svn_export_commands, :id => @assignment.id
        end
        should respond_with :success
      end

      context "My instructor should be able to download the svn repository list." do
        setup do
          get_as @admin, :download_svn_repo_list, :id => @assignment.id
        end
        should respond_with :success
      end

      context "instructor attempts to collect all submissions at once" do

        context "before assignment due date" do
          setup do
            Assignment.stubs(:find).returns(@assignment)
            @assignment.expects(:short_identifier).once.returns('a1')
            @assignment.submission_rule.expects(:can_collect_now?).once.returns(false)
            get_as @admin, :collect_all_submissions, :id => 1
          end
          should set_the_flash.to(I18n.t("collect_submissions.could_not_collect",
              :assignment_identifier => 'a1'))
          should respond_with :redirect
        end

        context "after assignment due date" do
          setup do
            @submission_collector = SubmissionCollector.instance
            Assignment.stubs(:find).returns(@assignment)
            SubmissionCollector.expects(:instance).returns(@submission_collector)
            @assignment.expects(:short_identifier).once.returns('a1')
            @assignment.submission_rule.expects(:can_collect_now?).once.returns(true)
            @submission_collector.expects(:push_groupings_to_queue).once
            get_as @admin, :collect_all_submissions, :id => 1
          end
          should set_the_flash.to(I18n.t("collect_submissions.collection_job_started",
              :assignment_identifier => 'a1'))
          should respond_with :redirect
        end

      end

      should "instructor tries to release submissions" do

        Assignment.stubs(:find).returns(@assignment)
        @assignment.groupings.expects(:all).returns([@grouping])
        post_as @admin,
                :update_submissions,
                :id => 1,
                :ap_select_full => 'true',
                :filter => 'none',
                :release_results => 'true'
        assert respond_with :redirect

      end
    end

  end

  context "I am an unauthenticated or unauthorized user" do
    context "trying to download a simple csv report" do
      setup do
        get :download_simple_csv_report
      end
      should respond_with :redirect
    end

    context "trying to download a detailed csv report" do
      setup do
        get :download_detailed_csv_report
      end
      should respond_with :redirect
    end

    context "trying to download the svn export commands" do
      setup do
        get :download_svn_export_commands end
      should respond_with :redirect
    end

    context "trying to download the svn repository list" do
      setup do
        get :download_svn_repo_list
      end
      should respond_with :redirect
    end
  end

  def teardown
    destroy_repos
  end

end
