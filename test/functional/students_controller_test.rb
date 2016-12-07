# encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

class StudentsControllerTest < AuthenticatedControllerTest

  context 'A student' do
    setup do
      @student = Student.make
    end

    should 'not be able to go on :index' do
      get_as @student, :index
      assert_response :missing
    end

    should 'not be able to :edit' do
      get_as @student, :edit, id: 178
      assert_response :missing
    end

    should 'not be able to :update' do
      put_as @student, :update, id: 178
      assert_response :missing
    end

    should 'not be able to :create' do
      put_as @student, :create
      assert_response :missing
    end

    should 'not be able to :download_student_list' do
      get_as @student, :download_student_list
      assert_response :missing
    end
  end  # -- A student

  context 'An admin' do
    setup do
      @admin = Admin.make
      @section = Section.make
    end

    should 'be able to get :new' do
      get_as @admin, :new, user_params
      assert_response :success
    end

    should 'be able to get :index' do
      get_as @admin, :index
      assert_response :success
    end

    should 'be able to create a student' do
      post_as @admin,
              :create,
              user: {user_name: 'jdoe',
                     last_name: 'Doe',
                     first_name: 'John'}
      assert_response :redirect
      assert_not_nil Student.find_by_user_name('jdoe')
    end

    should 'recognize remote action for add a new section modal' do
      assert_recognizes( {controller: 'students', action: 'add_new_section' },
      {path: 'students/add_new_section', method: 'get'} )
    end

    should 'not be able to create a student with missing data' do
      post_as @admin,
              :create,
              user: {user_name: 'jdoe',
                     first_name: 'John'}
      assert_response :success
      assert_nil Student.find_by_user_name('jdoe')
      assert_equal [I18n.t('student.create.error')], flash[:error]
    end

    should 'be able to create a student with a section' do
      post_as @admin,
              :create,
              user: {user_name: 'jsmith',
                     last_name: 'Smith',
                     first_name: 'John',
                     section_id: @section.id,}
      assert_response :redirect
      jsmith = Student.find_by_user_name('jsmith')
      assert_not_nil jsmith
      assert jsmith.section.id = @section.id
    end

    context 'with a student' do
      setup do
        @student = Student.make
        @section = Section.make
      end

      should 'recognize action to bulk modify for a student' do
        assert_recognizes( {action: 'bulk_modify', controller: 'students'},
               {path: 'students/bulk_modify', method: 'post'} )
      end

      should 'be able to edit a student' do
        get_as @admin,
               :edit,
               id: @student.id
        assert_response :success
      end

      should 'be able to update student' do
        put_as @admin,
               :update,
               id: @student.id,
               user: {last_name: 'Doe',
                      first_name: 'John'}
        assert_response :redirect
        assert_equal [I18n.t('students.update.success',
                            user_name: @student.user_name)],
                     flash[:success]

        @student.reload
        assert_equal 'Doe',
                     @student.last_name,
                     'should have been updated to Doe'

      end

      should 'be able to update student (and change his section)' do
        put_as @admin,
               :update,
               id: @student.id,
               user: {  user_name:  'machinist_student1',
                        last_name:  'Doe',
                        first_name: 'John',
                        section_id: @section.id }
        assert_response :redirect
        assert_equal [I18n.t('students.update.success',
                            user_name: @student.user_name)],
                     flash[:success]

        @student.reload
        assert_equal @section,
                     @student.section,
                     'should have been added to section' + @section.name

      end

      should 'be able to upload a student CSV file without sections' do
        post_as @admin,
                :upload_student_list,
                userlist: fixture_file_upload('classlist-csvs/new_students.csv')
        assert_response :redirect
        assert_redirected_to(controller: 'students', action: 'index')
        c8mahler = Student.find_by_user_name('c8mahlernew')
        assert_not_nil c8mahler
        assert_generates '/students/upload_student_list', controller: 'students', action: 'upload_student_list'
        assert_recognizes({controller: 'students', action: 'upload_student_list' },
          {path: 'students/upload_student_list', method: :post})
      end

      should 'have valid values in database after an upload of a UTF-8 encoded file parsed as UTF-8' do
        post_as @admin,
                :upload_student_list,
                userlist: fixture_file_upload('files/test-students-utf8.csv'),
                encoding: 'UTF-8'
        assert_response :redirect
        assert_redirected_to(controller: 'students', action: 'index')
        test_student = Student.find_by_user_name('c2ÈrÉØrr')
        assert_not_nil test_student # student should exist
      end

      should 'have valid values in database after an upload of a ISO-8859-1 encoded file parsed as ISO-8859-1' do
        post_as @admin,
                :upload_student_list,
                userlist: fixture_file_upload('files/test-students-iso-8859-1.csv'),
                encoding: 'ISO-8859-1'
        assert_response :redirect
        assert_redirected_to(controller: 'students', action: 'index')
        test_student = Student.find_by_user_name('c2ÈrÉØrr')
        assert_not_nil test_student # student should exist
      end

      should 'have invalid values in database after an upload of a UTF-8 encoded file parsed as ISO-8859-1' do
        post_as @admin,
                :upload_student_list,
                userlist: fixture_file_upload('files/test-students-utf8.csv'),
                encoding: 'ISO-8859-1'
        assert_response :redirect
        assert_redirected_to(controller: 'students', action: 'index')
        test_student = Student.find_by_user_name('c2ÈrÉØrr')
        assert_nil test_student # student should not be found, despite existing in the CSV file
      end

      should 'gracefully handle malformed csv files' do
        tempfile = fixture_file_upload('files/malformed.csv')
        post_as @admin,
                :upload_student_list,
                userlist: tempfile

        assert_response :redirect
        assert_equal flash[:error], [I18n.t('csv.upload.malformed_csv')]
      end

      should 'gracefully handle a non csv file with a csv extension' do
        tempfile = fixture_file_upload('files/pdf_with_csv_extension.csv')
        post_as @admin,
                :upload_student_list,
                userlist: tempfile,
                encoding: 'UTF-8'

        assert_response :redirect
        assert_equal flash[:error],
                     I18n.t(['csv.upload.non_text_file_with_csv_extension'])
      end
    end  # -- with a student
  end  # -- An admin
end

