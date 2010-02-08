require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'fastercsv'
require 'shoulda'

class SubmissionsControllerTest < AuthenticatedControllerTest

  fixtures  :all
  set_fixture_class :rubric_criteria => RubricCriterion
  
  def setup
    @controller = SubmissionsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    
    # login before testing
    @admin = users(:olm_admin_1)
    @grader = users(:ta1)
    @request.session['uid'] = @admin.id
    @student = users(:student1)
    # stub assignment
    @new_assignment = {  
      'name'          => '', 
      'message'       => '', 
      'group_min'     => '',
      'group_max'     => '',
      'due_date(1i)'  => '',
      'due_date(2i)'  => '',
      'due_date(2i)'  => '',
      'due_date(2i)'  => '',
    }
    setup_group_fixture_repos
    
  end
  
  def teardown
    destroy_repos
  end
  
  def test_students_can_use_file_manager
    assignment = assignments(:assignment_5)
    get_as(@student, :file_manager, {:id => assignment.id})
    assert_response :success
  end
  
  def test_students_can_populate_file_manager
    assignment = assignments(:assignment_5)
    get_as(@student, :populate_file_manager, {:id => assignment.id})
    assert_response :success
  end
  
  def test_students_can_add_files
    file_1 = fixture_file_upload('files/Shapes.java', 'text/java')
    file_2 = fixture_file_upload('files/TestShapes.java', 'text/java')
    assignment = assignments(:assignment_5)
    assert @student.has_accepted_grouping_for?(assignment.id)
    post_as(@student, :update_files, {:id => assignment.id, :new_files => [file_1, file_2]})
    assert_redirected_to :action => 'file_manager'
    # Check to see if the file was added
    grouping = @student.accepted_grouping_for(assignment.id)
    revision = grouping.group.repo.get_latest_revision
    files = revision.files_at_path(assignment.repository_folder)
    assert_not_nil files['Shapes.java']
    assert_not_nil files['TestShapes.java']
  end
  
  def test_students_can_replace_files
    assignment = assignments(:assignment_5)
    assert @student.has_accepted_grouping_for?(assignment.id)
    grouping = @student.accepted_grouping_for(assignment.id)
     
    repo = grouping.group.repo
    txn = repo.get_transaction('markus')
    txn.add(File.join(assignment.repository_folder,'Shapes.java'), 'Content of Shapes.java')
    txn.add(File.join(assignment.repository_folder, 'TestShapes.java'), 'Content of TestShapes.java')
    repo.commit(txn)
    
    revision = repo.get_latest_revision
    old_files = revision.files_at_path(assignment.repository_folder)
    old_file_1 = old_files['Shapes.java']
    old_file_2 = old_files['TestShapes.java']

    file_1 = fixture_file_upload('files/Shapes.java', 'text/java')
    file_2 = fixture_file_upload('files/TestShapes.java', 'text/java')

    post_as(@student, :update_files, {:id => assignment.id, :replace_files => {'Shapes.java' => file_1, 'TestShapes.java' => file_2}, :file_revisions => {'Shapes.java' => old_file_1.from_revision, 'TestShapes.java' => old_file_2.from_revision}})

    assert_redirected_to :action => 'file_manager'
    # Check to see if the file was added
    grouping = @student.accepted_grouping_for(assignment.id)
    revision = grouping.group.repo.get_latest_revision
    files = revision.files_at_path(assignment.repository_folder)
    assert_not_nil files['Shapes.java']
    assert_not_nil files['TestShapes.java']
    
    # Test to make sure that the contents were successfully updated
    file_1.rewind
    file_2.rewind
    file_1_new_contents = repo.download_as_string(files['Shapes.java'])
    file_2_new_contents = repo.download_as_string(files['TestShapes.java'])
    
    assert_equal file_1.read, file_1_new_contents
    assert_equal file_2.read, file_2_new_contents
    
  end 
  
  def test_students_can_delete_files
    assignment = assignments(:assignment_5)
    assert @student.has_accepted_grouping_for?(assignment.id)
    grouping = @student.accepted_grouping_for(assignment.id)
     
    repo = grouping.group.repo
    txn = repo.get_transaction('markus')
    txn.add(File.join(assignment.repository_folder,'Shapes.java'), 'Content of Shapes.java')
    txn.add(File.join(assignment.repository_folder, 'TestShapes.java'), 'Content of TestShapes.java')
    repo.commit(txn)
    revision = repo.get_latest_revision
    old_files = revision.files_at_path(assignment.repository_folder)
    old_file_1 = old_files['Shapes.java']
    old_file_2 = old_files['TestShapes.java']
    
    post_as(@student, :update_files, {:id => assignment.id, :delete_files => {'Shapes.java' => true}, :file_revisions => {'Shapes.java' => old_file_1.from_revision, 'TestShapes.java' => old_file_2.from_revision}})

    repo = grouping.group.repo
    revision = repo.get_latest_revision
    files = revision.files_at_path(assignment.repository_folder)
    assert_not_nil files['TestShapes.java']
    assert_nil files['Shapes.java']
  end
  
  def test_student_cant_add_file_that_exists
    assignment = assignments(:assignment_5)
    assert @student.has_accepted_grouping_for?(assignment.id)
    grouping = @student.accepted_grouping_for(assignment.id)
     
    repo = grouping.group.repo
    txn = repo.get_transaction('markus')
    txn.add(File.join(assignment.repository_folder,'Shapes.java'), 'Content of Shapes.java')
    txn.add(File.join(assignment.repository_folder, 'TestShapes.java'), 'Content of TestShapes.java')
    repo.commit(txn)
  
    file_1 = fixture_file_upload('files/Shapes.java', 'text/java')
    file_2 = fixture_file_upload('files/TestShapes.java', 'text/java')
    assignment = assignments(:assignment_5)
    assert @student.has_accepted_grouping_for?(assignment.id)
    post_as(@student, :update_files, {:id => assignment.id, :new_files => [file_1, file_2]})
    # Check to see if the file was added
    assert_redirected_to :action => 'file_manager', :id => assignment.id
    grouping = @student.accepted_grouping_for(assignment.id)
    assert grouping.is_valid?
    revision = grouping.group.repo.get_latest_revision
    files = revision.files_at_path(assignment.repository_folder)
    assert_not_nil files['Shapes.java']
    assert_not_nil files['TestShapes.java']
    assert_not_nil flash[:update_conflicts]
  end
  
  # TODO:  Test that a student can't replace file if out of sync
  
  # TODO:  Test that a student can't replace a file if the new file
  # has a different name
  
  def test_students_cant_use_repo_browser
    get_as(@student, :repo_browser, {:id => Grouping.last.id})
    assert_response :missing
  end
  
  def test_graders_can_use_repo_browser
    get_as(@grader, :repo_browser, {:id => Grouping.last.id})
    assert_response :success
  end
  
  def test_instructors_can_use_repo_browser
    get_as(@admin, :repo_browser, {:id => Grouping.last.id})
    assert_response :success
  end
 
  # TODO:  TEST REPO BROWSER HERE
  
  def test_students_cant_populate_repo_browser
    get_as(@student, :populate_repo_browser, {:id => Grouping.first.id})
    assert_response :missing
  end
  
  def test_graders_can_populate_repo_browser
    get_as(@grader, :populate_repo_browser, {:id => Grouping.first.id})
    assert_response :success
  end
  
  def test_instructors_can_populate_repo_browser
    get_as(@admin, :populate_repo_browser, {:id => Grouping.first.id})
    assert_response :success
  end
  
  # TODO:
  
  # Test whether or not an Instructor can release/unrelease results correctly
  # Test whether or not an Instructor can download files from student repos
  
  context "A logged in student doing a GET" do
    
    setup do
      @student = users(:student1)
    end
    
    context "on download_simple_csv_report" do
      setup do
        get_as @student, :download_simple_csv_report
      end
      
      should_respond_with :missing
    end
    
    context "on download_detailed_csv_report" do
      setup do
        get_as @student, :download_detailed_csv_report
      end
      
      should_respond_with :missing
    end
    
    context "on download_svn_export_commands" do
      setup do
        get_as @student, :download_svn_export_commands
      end
      
      should_respond_with :missing
    end
    
    context "on download_svn_repo_list" do
      setup do
        get_as @student, :download_svn_repo_list
      end
      
      should_respond_with :missing
    end
    
  end # context logged in student
  
  context "An unauthenticated and unauthorized user doing a GET" do
    
    context "on download_simple_csv_report" do
      setup do
        get :download_simple_csv_report
      end
      should_respond_with :redirect
    end
    
    context "on download_detailed_csv_report" do
      setup do
        get :download_detailed_csv_report
      end
      should_respond_with :redirect
    end
    
    context "on download_svn_export_commands" do
      setup do
        get :download_svn_export_commands
      end
      should_respond_with :redirect
    end
    
    context "on download_svn_repo_list" do
      setup do
        get :download_svn_repo_list
      end
      should_respond_with :redirect
    end
    
  end # An unauthenticated and unauthorized user doing a POST
  
  context "A logged in admin doing a GET" do
    
    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:assignment_6)
    end
    
    context "on download_simple_csv_report" do
      setup do
        get_as @admin, :download_simple_csv_report, :id => @assignment.id
      end
      should_respond_with :success
    end
    
    context "on download_detailed_csv_report" do
      setup do
        get_as @admin, :download_detailed_csv_report, :id => @assignment.id
      end
      should_respond_with :success
    end
    
    context "on download_svn_export_commands" do
      setup do
        get_as @admin, :download_svn_export_commands, :id => @assignment.id
      end
      
      should_respond_with :success
    end
    
    context "on download_svn_repo_list" do
      setup do
        get_as @admin, :download_svn_repo_list, :id => @assignment.id
      end
      
      should_respond_with :success
    end
    
  end # context: A logged in admin doing a GET
  
  
  context "A logged in TA doing a GET" do
    
    setup do
      @ta = users(:ta1)
    end
    
    context "on download_simple_csv_report" do
      setup do
        get_as @ta, :download_simple_csv_report
      end
      should_respond_with :missing
    end
    
    context "on download_detailed_csv_report" do
      setup do
        get_as @ta, :download_detailed_csv_report
      end
      should_respond_with :missing
    end
    
    context "on download_svn_export_commands" do
      setup do
        get_as @ta, :download_svn_export_commands
      end
      should_respond_with :missing
    end
    
    context "on download_svn_repo_list" do
      setup do
        get_as @ta, :download_svn_repo_list
      end
      should_respond_with :missing
    end
    
  end # context: A logged in TA doing a GET
    
end
