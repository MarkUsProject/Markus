# encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

class TasControllerTest < AuthenticatedControllerTest

  context 'No user' do
    should 'redirect to the index' do
      get :index
      assert_redirected_to action: 'login', controller: 'main'
    end
  end # -- No user


  context 'a TA' do
    setup do
      @ta = Ta.make
    end

    should 'not be able to go on :index' do
      get_as @ta, :index
      assert_response :missing
    end

    should 'not be able to :edit' do
      get_as @ta, :edit, id: @ta.id
      assert_response :missing
    end

    should 'not be able to :update' do
      put_as @ta, :update, id: @ta.id
      assert_response :missing
    end

    should 'not be able to :create' do
      put_as @ta, :create
      assert_response :missing
    end

  end # -- a TA


  context 'An admin' do
    setup do
      @admin = Admin.make
    end

    should 'be able to get :index' do
      get_as @admin, :index
      assert_response :success
    end

    should 'be able to get :new' do
      get_as @admin, :new
      assert_response :success
    end

    context 'with a TA' do
      setup do
        @ta = Ta.make
      end

      should 'be able to edit a TA' do
        get_as @admin,
               :edit,
               id: @ta.id
        assert_response :success
      end

      should 'be able to upload a TA CSV file' do
        post_as @admin,
                :upload_ta_list,
                userlist: fixture_file_upload('classlist-csvs/new_students.csv')
        assert_response :redirect
        assert_redirected_to(controller: 'tas', action: 'index')
        c8mahler = Ta.find_by_user_name('c8mahlernew')
        assert_not_nil c8mahler
        assert_generates '/tas/upload_ta_list', controller: 'tas', action: 'upload_ta_list'
        assert_recognizes({controller: 'tas', action: 'upload_ta_list' },
          {path: 'tas/upload_ta_list', method: :post})
      end

      should 'have valid values in database after an upload of a ISO-8859-1 encoded TAs file parsed as ISO-8859-1' do
        post_as @admin,
                :upload_ta_list,
                userlist: fixture_file_upload('files/test-students-iso-8859-1.csv'),
                encoding: 'ISO-8859-1'
        assert_response :redirect
        assert_redirected_to(controller: 'tas', action: 'index')
        test_student = Ta.find_by_user_name('c2ÈrÉØrr')
        assert_not_nil test_student # student should exist
      end

      should 'have valid values in database after an upload of a UTF-8 encoded TAs file parsed as UTF-8' do
        post_as @admin,
                :upload_ta_list,
                userlist: fixture_file_upload('files/test-students-utf8.csv'),
                encoding: 'UTF-8'
        assert_response :redirect
        assert_redirected_to(controller: 'tas', action: 'index')
        test_student = Ta.find_by_user_name('c2ÈrÉØrr')
        assert_not_nil test_student # student should exist
      end

      should 'have invalid values in database after an upload of a UTF-8 encoded TAs file parsed as ISO-8859-1' do
        post_as @admin,
                :upload_ta_list,
                userlist: fixture_file_upload('files/test-students-utf8.csv'),
                encoding: 'ISO-8859-1'
        assert_response :redirect
        assert_redirected_to(controller: 'tas', action: 'index')
        test_student = Ta.find_by_user_name('c2ÈrÉØrr')
        assert_nil test_student # student should not be found, despite existing in the CSV file
      end

      should 'gracefully handle malformed csv files' do
        tempfile = fixture_file_upload('files/malformed.csv')
        post_as @admin,
                :upload_ta_list,
                userlist: tempfile,
                encoding: 'UTF-8'

        assert_response :redirect
        assert_equal flash[:error], [I18n.t('csv.upload.malformed_csv')]
      end

      should 'gracefully handle a non csv file with a csv extension' do
        tempfile = fixture_file_upload('files/pdf_with_csv_extension.csv')
        post_as @admin,
                :upload_ta_list,
                userlist: tempfile,
                encoding: 'UTF-8'

        assert_response :redirect
        assert_equal flash[:error],
                     [I18n.t('csv.upload.non_text_file_with_csv_extension')]
      end
    end # -- With a TA
  end # -- An admin

end
