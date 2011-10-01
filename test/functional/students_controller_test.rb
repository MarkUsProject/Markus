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
      get_as @student, :edit, :id => 178
      assert_response :missing
    end

    should "not be able to :update" do
      put_as @student, :update, :id => 178
      assert_response :missing
    end

    should "not be able to :create" do
      put_as @student, :create
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
      @section = Section.make
    end

    should "be able to get :new" do
      get_as @admin, :new
      assert_response :success
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

    should "be able to create a student with a section" do
      post_as @admin,
              :create,
              :user => {:user_name => 'jsmith',
                        :last_name => 'Smith',
                        :first_name => 'John',
                        :section_id => @section.id,}
      assert_response :redirect
      jsmith = Student.find_by_user_name('jsmith')
      assert_not_nil jsmith
      assert jsmith.section.id = @section.id
    end

    context "with a student" do
      setup do
        @student = Student.make
        @section = Section.make
      end

      should "be able to edit a student" do
        get_as @admin,
               :edit,
               :id => @student.id
        assert_response :success
      end

      should "be able to update student" do
        put_as @admin,
               :update,
               :id => @student.id,
               :user => {:last_name => 'Doe',
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

      should "be able to update student (and change his section)" do
        put_as @admin,
               :update,
               :id => @student.id,
               :user => {:last_name => 'Doe',
                         :first_name => 'John',
                         :section_id => @section.id }
        assert_response :redirect
        assert_equal I18n.t("students.edit_success",
                            :user_name => @student.user_name),
                     flash[:edit_notice]

        @student.reload
        assert_equal @section,
                     @student.section,
                     'should have been added to section' + @section.name

      end
    end  # -- with a student
  end  # -- An admin
end

