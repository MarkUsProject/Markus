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

  def test_index
    get_as(@admin, :index)
    assert_response :success
  end

  def test_edit
    student = users(:student1)
    get_as(@admin, :edit, :id => student.id)
    assert_response :success
  end

  def test_filter_all1
    get_as(@admin, :filter)
    assert_response :success
  end

  def test_filter_all2
    get_as(@admin, :filter)
    assert_equal(Student.all.count, @students.count, "should be the same
    number")
  end


  def test_filter_hidden
    get_as(@admin, :filter, :filter => "hidden")
    assert_response :success
  end

  def test_filter_hidden2
    get_as(@admin, :filter, :filter => "hidden")
    assert_equal(1, @students.count, "should be equal to 1")
  end

  def test_filter_visible
    get_as(@admin, :filter, :filter => "visible")
    assert_response :success
  end

  def test_filter_visible2
    student_number = Student.all.count - 1
    get_as(@admin, :filter, :filter => "visible")
    assert_equal(student_number, @students.count)
  end

  def test_create
    student = users(:student1)
    post_as(@admin, :create, :user => {:user_name => 'Essai',:id => student.id, :last_name => 'ESSAI', :first_name => 'essai'})
    assert_response :redirect
  end


  def test_update1
    student = users(:student1)
    post_as(@admin, :update, :user => {:id => student.id, :last_name =>
    'ESSAI', :first_name => 'essai'})
    assert_response :redirect
  end

  def test_update2
    student = users(:student1)
    post_as(@admin, :update, :user => {:id => student.id, :last_name =>
    'ESSAI', :first_name => 'essai'})
    assert_equal("ESSAI", student.last_name, 'should have been updated to ESSAI')
  end

end

