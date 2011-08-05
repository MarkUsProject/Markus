require File.join(File.dirname(__FILE__), 'authenticated_controller_test')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')

class StudentsControllerTest < AuthenticatedControllerTest


  def setup
    clear_fixtures
  end

  context "A student" do
    setup do
      @student = Student.make
    end

    should "not be able to go on :index" do
      get_as @student, :index
      assert_response :missing
    end

    should "not be able to :edit" do
      get_as @student, :edit
      assert_response :missing
    end

    should "not be able to :update" do
      get_as @student, :update
      assert_response :missing
    end

    should "not be able to :create" do
      get_as @student, :create
      assert_response :missing
    end

    should "not be able to :download_student_list" do
      get_as @student, :download_student_list
      assert_response :missing
    end
  end  # -- A student

  context "An admin" do
    setup do
      @admin = Admin.make
    end

    should "be able to get :index" do
      get_as @admin, :index
      assert_response :success
    end

    should "be able to create a student" do
      post_as @admin,
              :create,
              :user => {:user_name => 'jdoe',
                        :last_name => 'Doe',
                        :first_name => 'John'}
      assert_response :redirect
      assert_not_nil Student.find_by_user_name('jdoe')
    end

    context "with a student" do
      setup do
        @student = Student.make
      end

      should "be able to edit a student" do
        get_as @admin,
               :edit,
               :id => @student.id
        assert_response :success
      end

      should "be able to update student" do
        post_as @admin,
                :update,
                :user => {:id => @student.id,
                          :last_name => 'Doe',
                          :first_name => 'John'}
        assert_response :redirect
        assert_equal I18n.t("students.edit_success",
                            :user_name => @student.user_name),
                     flash[:edit_notice]

        @student.reload
        assert_equal "Doe",
                     @student.last_name,
                     'should have been updated to Doe'

      end
    end  # -- with a student
  end  # -- An admin
end

