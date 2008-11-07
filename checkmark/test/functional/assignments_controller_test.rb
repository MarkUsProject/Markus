require File.dirname(__FILE__) + '/authenticated_controller_test'

class AssignmentsControllerTest < AuthenticatedControllerTest
  
  fixtures  :users, :assignments
  
  def setup
    @controller = AssignmentsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    
    # login before testing
    @admin = users(:admin)
    @request.session['uid'] = @admin.id
    
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
  end
  
  # Test for accessing new assignment page
  def test_get_new
    get_as @admin, :new
    assert_response :success
    assert_not_nil assigns['assignment']
  end
  
  # TODO
  
  
  # Test create assignment with assignment files
  
  # Test create assignment with assignment files and blank text fields
  
  # Test create invalid assignment
  
  
  # Test update invalid assignment without file
  
  # Test update valid assignment without file
  
  # Test update 0-1 file with blank text fields
  
  # Test add and remove at the same time
  
  # Test remove all files
  
  
end
