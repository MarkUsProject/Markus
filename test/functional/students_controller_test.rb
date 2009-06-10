require 'test_helper'
require File.dirname(__FILE__) + '/authenticated_controller_test'

class StudentsControllerTest < AuthenticatedControllerTest
  def setup
    @student = users(:student2)
    @admin = users(:olm_admin_1)
  end
  
  # Students should never be able to access any of the functions of this controller
  def test_student_locked_out
    # Index
    get_as @student, :index
    assert_response :missing
    
    # Edit
    get_as @student, :edit
    assert_response :missing

    # Update
    get_as @student, :update
    assert_response :missing
    
    # Create
    get_as @student, :create
    assert_response :missing

    # Download Student List
    get_as @student, :download_student_list
    assert_response :missing
    
    # Upload Student List (Get)
    get_as @student, :index
    assert_response :missing

    # Upload Student List (Post)
    post_as @student, :index
    assert_response :missing

  end
end
