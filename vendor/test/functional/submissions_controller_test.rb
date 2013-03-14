require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
include CsvHelper
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

    should "and I should be able to access the file manager page" do
      get_as @student, :file_manager, :assignment_id => @assignment.id

      assert_response :success
      # file_manager action assert assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      assert assign_to :assignment
      assert assign_to :grouping
      assert assign_to :path
      assert assign_to :revision
      assert assign_to :files
      assert assign_to :missing_assignment_files
    end

    should "and I should be able to populate file" do
      get_as @student, :populate_file_manager, :assignment_id => @assignment.id
      assert_response :success
    end

    #TODO Figure out how to remove fixture_file_upload
    should "and I should be able to add files" do
      file_1 = fixture_file_upload(File.join('..', 'files', 'Shapes.java'), 'text/java')
      file_2 = fixture_file_upload(File.join('..', 'files', 'TestShapes.java'), 'text/java')
      assert @student.has_accepted_grouping_for?(@assignment.id)
      post_as @student,
              :update_files,
              :assignment_id => @assignment.id,
              :new_files => [file_1, file_2]

      # must not respond with redirect_to (see comment in
      # app/controllers/submission_controller.rb#update_files)
      assert_response :success

      # update_files action assert assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      assert assign_to :assignment
      assert assign_to :grouping
      assert assign_to :path
      assert assign_to :revision
      assert assign_to :files
      assert assign_to :missing_assignment_files

      # Check to see if the file was added
      @grouping.group.access_repo do |repo|
        revision = repo.get_latest_revision
        files = revision.files_at_path(@assignment.repository_folder)
        assert_not_nil files['Shapes.java']
        assert_not_nil files['TestShapes.java']
      end
    end

    #TODO figure out how to test this test into the one above
    #TODO Figure out how to remove fixture_file_upload
    should "and I should be able to replace files" do
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

        post_as @student,
                :update_files, :assignment_id => @assignment.id,
          :replace_files => { 'Shapes.java' =>      @file_1,
                              'TestShapes.java' =>  @file_2},
          :file_revisions => {'Shapes.java' =>      old_file_1.from_revision,
                              'TestShapes.java' =>  old_file_2.from_revision}

      end

      # must not respond with redirect_to (see comment in
      # app/controllers/submission_controller.rb#update_files)
      assert_response :success

      # update_files action assert assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      assert assign_to :assignment
      assert assign_to :grouping
      assert assign_to :path
      assert assign_to :revision
      assert assign_to :files
      assert assign_to :missing_assignment_files

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

    should "and I should be able to delete files" do
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

        post_as(@student, :update_files, {:assignment_id => @assignment.id,
          :delete_files => {  'Shapes.java' => true},
          :file_revisions => {'Shapes.java' => old_file_1.from_revision,
                              'TestShapes.java' => old_file_2.from_revision}})
      end

      # must not respond with redirect_to (see comment in
      # app/controllers/submission_controller.rb#update_files)
      assert_response :success

      # update_files action assert assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      assert assign_to :assignment
      assert assign_to :grouping
      assert assign_to :path
      assert assign_to :revision
      assert assign_to :files
      assert assign_to :missing_assignment_files

      @grouping.group.access_repo do |repo|
        revision = repo.get_latest_revision
        files = revision.files_at_path(@assignment.repository_folder)
        assert_not_nil files['TestShapes.java']
        assert_nil files['Shapes.java']
      end
    end

    should "and I cannot add a file that exists" do
      assert @student.has_accepted_grouping_for?(@assignment.id)

      @grouping.group.access_repo do |repo|
        txn = repo.get_transaction('markus')
        txn.add(File.join(@assignment.repository_folder,'Shapes.java'), 'Content of Shapes.java')
        txn.add(File.join(@assignment.repository_folder, 'TestShapes.java'), 'Content of TestShapes.java')
        repo.commit(txn)

        file_1 = fixture_file_upload(File.join('..', 'files', 'Shapes.java'), 'text/java')
        file_2 = fixture_file_upload(File.join('..', 'files', 'TestShapes.java'), 'text/java')
        assert @student.has_accepted_grouping_for?(@assignment.id)
        post_as(@student, :update_files, {:assignment_id => @assignment.id, :new_files => [file_1, file_2]})
      end

      # must not respond with redirect_to (see comment in
      # app/controllers/submission_controller.rb#update_files)
      assert_response :success

      # update_files action should assign to various instance variables.
      # These are crucial for the file_manager view to work properly.
      assert assign_to :assignment
      assert assign_to :grouping
      assert assign_to :path
      assert assign_to :revision
      assert assign_to :files
      assert assign_to :missing_assignment_files
      assert assign_to :file_manager_errors

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
    # TODO:  Test that a student can't replace file if out of sync
    # TODO:  Test that a student can't replace a file if the new file
    #         has a different name

    # Repository Browser Tests
    # TODO:  TEST REPO BROWSER HERE
    should "and I cannot use the repository browser" do
      get_as @student,
             :repo_browser,
             :assignment_id => 1,
             :id => Grouping.last.id
      assert_response :missing
    end

    should "and I cannot use the populate repository browser." do
      get_as @student,
             :populate_repo_browser,
             :assignment_id => 1,
             :id => Grouping.first.id
      assert_response :missing
    end

    # Stopping a curious student
    should "and I cannot access a simple csv report" do
      get_as @student, :download_simple_csv_report, :assignment_id => 1

      assert_response :missing
    end

    should "and I cannot access a detailed csv report." do
      get_as @student, :download_detailed_csv_report, :assignment_id => 1

      assert_response :missing
    end

    should "and I cannot download svn export commands" do
      get_as @student, :download_svn_export_commands, :assignment_id => 1

      assert_response :missing
    end

    should "and I cannot download the svn repository list" do
      get_as @student, :download_svn_repo_list, :assignment_id => 1

      assert_response :missing
    end

    context "and I have a grader. My grade should be able to" do
      setup do
        @ta_membership = TaMembership.make(:membership_status => :accepted, :grouping => @grouping)
        @grader = @ta_membership.user
      end

      should "access the repository browser." do
        get_as @grader,
               :repo_browser,
               :assignment_id => @assignment.id,
               :id => Grouping.last.id
        assert_response :success
      end

      should "access the populate repository browser." do
        get_as @grader,
               :populate_repo_browser,
               :assignment_id => 1,
               :id => Grouping.first.id
        assert_response :success
      end

      should "download a simple csv report" do
        get_as @grader,
               :download_simple_csv_report,
               :assignment_id => 1

        assert_response :missing
      end

      should "download a detailed csv report" do
        get_as @grader, :download_detailed_csv_report, :assignment_id => 1
        assert_response :missing
      end

      should "download the svn export commands" do
        get_as @grader, :download_svn_export_commands, :assignment_id => 1
        assert_response :missing
      end

      should "download the svn repository list" do
        get_as @grader, :download_svn_repo_list, :assignment_id => 1
        assert_response :missing
      end

      context "to collect all their assigned submissions at once" do

        should "before collection date" do
          Assignment.stubs(:find).returns(@assignment)
          @assignment.expects(:short_identifier).once.returns('a1')
          @assignment.submission_rule.expects(:can_collect_now?).once.returns(false)
          get_as @grader, 
                 :collect_ta_submissions, 
                 :assignment_id => 1, 
                 :id => 1 
          assert_equal flash[:error], I18n.t("collect_submissions.could_not_collect",
              :assignment_identifier => 'a1')
          assert_response :redirect
        end

        should "after assignment due date" do
          @submission_collector = SubmissionCollector.instance
          Assignment.stubs(:find).returns(@assignment)
          SubmissionCollector.expects(:instance).returns(@submission_collector)
          @assignment.expects(:short_identifier).once.returns('a1')
          @assignment.submission_rule.expects(:can_collect_now?).once.returns(true)
          @submission_collector.expects(:push_groupings_to_queue).once
          get_as @grader,
                 :collect_ta_submissions, 
                 :assignment_id => 1,
                 :id => 1
                  
          assert_equal flash[:success], I18n.t("collect_submissions.collection_job_started",
              :assignment_identifier => 'a1')
          assert_response :redirect 
        end 
       
        should "per_page and sort_by not defined so cookies are set to default" do
          Assignment.stubs(:find).returns(@assignment)
          @assignment.expects(:short_identifier).once.returns('a1')
          @assignment.submission_rule.expects(:can_collect_now?).once.returns(true)

          @c_per_page = @grader.id.to_s + "_" + @assignment.id.to_s + "_per_page"
          @c_sort_by = @grader.id.to_s + "_" + @assignment.id.to_s + "_sort_by"
          
          get_as @grader,
                 :browse,
                 :assignment_id => 1,
                 :id => 1
          assert_response :success
          assert_equal "30", cookies[@c_per_page], "Debug: Cookies=#{cookies.inspect}"
          assert_equal "group_name", cookies[@c_sort_by], "Debug: Cookies=#{cookies.inspect}" 
        end
        
        should "per_page and sort_by defined so cookies are set to their values" do
          Assignment.stubs(:find).returns(@assignment)
          @assignment.expects(:short_identifier).once.returns('a1')
          @assignment.submission_rule.expects(:can_collect_now?).once.returns(true) 

          @c_per_page = @grader.id.to_s + "_" + @assignment.id.to_s + "_per_page"
          @c_sort_by = @grader.id.to_s + "_" + @assignment.id.to_s + "_sort_by"
          
          get_as @grader,
                 :browse,
                 {
                    :assignment_id => 1,
                    :id => 1,
                    :per_page => 15,
                    :sort_by  => "revision_timestamp"
                 } 
          assert_response :success
          assert_equal "15", cookies[@c_per_page], "Debug: Cookies=#{cookies.inspect}"
          assert_equal "revision_timestamp", cookies[@c_sort_by], "Debug: Cookies=#{cookies.inspect}"  
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

      should "My instructor should be able to access the populate repository browser." do
        get_as @admin,
               :populate_repo_browser,
               :assignment_id => 1,
               :id => Grouping.first.id
        assert_response :success
      end

      should "My instructor should be able to download the simple csv report." do
        get_as @admin,
               :download_simple_csv_report,
               :assignment_id => @assignment.id
        assert_response :success
      end

      should "My instructor should be able to download the detailed csv report." do
        get_as @admin,
               :download_detailed_csv_report,
               :assignment_id => @assignment.id
        assert_response :success
      end

      should "My instructor should be able to download the svn export commands." do
        get_as @admin,
               :download_svn_export_commands,
               :assignment_id => @assignment.id
        assert_response :success
      end

      should "My instructor should be able to download the svn repository list." do
        get_as @admin,
               :download_svn_repo_list,
               :assignment_id => @assignment.id
        assert_response :success
      end

      context "instructor attempts to collect all submissions at once" do

        should "before assignment due date" do
          Assignment.stubs(:find).returns(@assignment)
          @assignment.expects(:short_identifier).once.returns('a1')
          @assignment.submission_rule.expects(:can_collect_now?).once.returns(false)
          get_as @admin,
                 :collect_all_submissions,
                 :assignment_id => 1
          assert_equal flash[:error], I18n.t("collect_submissions.could_not_collect",
              :assignment_identifier => 'a1')
          assert_response :redirect
        end

        should "after assignment due date" do
          @submission_collector = SubmissionCollector.instance
          Assignment.stubs(:find).returns(@assignment)
          SubmissionCollector.expects(:instance).returns(@submission_collector)
          @assignment.expects(:short_identifier).once.returns('a1')
          @assignment.submission_rule.expects(:can_collect_now?).once.returns(true)
          @submission_collector.expects(:push_groupings_to_queue).once
          get_as @admin, :collect_all_submissions, :assignment_id => 1, :id => 1
          assert_equal flash[:success], I18n.t("collect_submissions.collection_job_started",
              :assignment_identifier => 'a1')
          assert_response :redirect
 
        end

        should "per_page and sort_by not defined so set cookies to default" do
          Assignment.stubs(:find).returns(@assignment)
          @assignment.submission_rule.expects(:can_collect_now?).once.returns(true)
         
          @c_per_page = @admin.id.to_s + "_" + @assignment.id.to_s + "_per_page"
          @c_sort_by = @admin.id.to_s + "_" + @assignment.id.to_s + "_sort_by" 
          
          get_as @admin,
                 :browse,
                 :assignment_id => 1,
                 :id => 1

          assert_response :success
          assert_equal "30", cookies[@c_per_page], "Debug: Cookies=#{cookies.inspect}" 
          assert_equal "group_name", cookies[@c_sort_by]
        end

        should "15 per_page and sort_by revision_timestamp so set cookies to default" do
          Assignment.stubs(:find).returns(@assignment)
          @assignment.submission_rule.expects(:can_collect_now?).once.returns(true)

          @c_per_page = @admin.id.to_s + "_" + @assignment.id.to_s + "_per_page"
          @c_sort_by = @admin.id.to_s + "_" + @assignment.id.to_s + "_sort_by"

          get_as @admin,
                 :browse,
                 {
                    :assignment_id => 1,
                    :id => 1, 
                    :per_page => 15,
                    :sort_by  => "revision_timestamp" 
                 }
 
          assert_response :success
          assert_equal "15", cookies[@c_per_page], "Debug: Cookies=#{cookies.inspect}" 
          assert_equal "revision_timestamp", cookies[@c_sort_by]
        end

      end
 
      should "instructor tries to release submissions" do

        Assignment.stubs(:find).returns(@assignment)
        @assignment.groupings.expects(:all).returns([@grouping])
        post_as @admin,
                :update_submissions,
                :assignment_id => 1,
                :id => 1,
                :ap_select_full => 'true',
                :filter => 'none',
                :release_results => 'true'
        assert_response :redirect

      end
    end

  end

  context "I am an unauthenticated or unauthorized user" do
    should "trying to download a simple csv report" do
      get :download_simple_csv_report, :assignment_id => 1
      assert_response :redirect
    end

    should "trying to download a detailed csv report" do
      get :download_detailed_csv_report, :assignment_id => 1
      assert_response :redirect
    end

    should "trying to download the svn export commands" do
      get :download_svn_export_commands, :assignment_id => 1
      assert_response :redirect
    end

    should "trying to download the svn repository list" do
      get :download_svn_repo_list, :assignment_id => 1
      assert_response :redirect
    end
  end

  def teardown
    destroy_repos
  end

end
