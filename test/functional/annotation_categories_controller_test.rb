  # encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'

class AnnotationCategoriesControllerTest < AuthenticatedControllerTest

  context 'An unauthenticated user' do

    # Since we are not authenticated and authorized, we should be redirected
    # to the login page

    should 'on :index (get)' do
      get :index, assignment_id: 1
      assert_response :redirect
    end

    should 'on :show (get)' do
      get :show, assignment_id: 1, id: 1
      assert_response :redirect
    end

    should 'on :new (get)' do
      get :new, assignment_id: 1
      assert_response :redirect
    end

    should 'on :add_annotation_text (get)' do
      get :add_annotation_text, assignment_id: 1, id: 1
      assert_response :redirect
    end

    should 'on :destroy (delete)' do
      delete :destroy, assignment_id: 1, id: 1
      assert_response :redirect
    end

    should 'on :download (get)' do
      get :download, assignment_id: 1
      assert_response :redirect
    end

    should 'on :csv_upload (get)' do
      get :csv_upload, assignment_id: 1
      assert_response :redirect
    end

    should 'on :index (post)' do
      post :index, assignment_id: 1
      assert_response :redirect
    end

    should 'on :create (post)' do
      post :create, assignment_id: 1
      assert_response :redirect
    end

    should 'on :update (put)' do
      put :update, assignment_id: 1, id: 1
      assert_response :redirect
    end

    should 'on :update_annotation (post)' do
      post :update_annotation, assignment_id: 1, id: 1
      assert_response :redirect
    end

    should 'on :add_annotation_text (post)' do
      post :add_annotation_text, assignment_id: 1, id: 1
      assert_response :redirect
    end

    should 'on :delete_annotation_text (post)' do
      post :delete_annotation_text, assignment_id: 1, id: 1
      assert_response :redirect
    end

    should 'on :download (post)' do
      post :download, assignment_id: 1
      assert_response :redirect
    end

    should 'on :csv_upload (post)' do
      post :csv_upload, assignment_id: 1
      assert_response :redirect
    end

    should 'on :update_annotation' do
      put :update_annotation, assignment_id: 1, id: 1
      assert_response :redirect
    end

    should 'on :delete_annotation_text' do
      delete :delete_annotation_text, assignment_id: 1, id: 1
      assert_response :redirect
    end

  end # end unauthenticated/unauthorized user DELETE

  context 'An admin' do

    setup do
      @admin = Admin.make
      @editor = Admin.make
      @category = AnnotationCategory.make
      @assignment = @category.assignment
      @annotation_text = AnnotationText.make(
                                             annotation_category: @category,
                                             creator_id: @admin.id,
                                             last_editor_id: (@admin.id + 1))
      @annotation_text_params = {
        id: @annotation_text.id,
        annotation_category: @annotation_text.annotation_category,
        creator_id: @annotation_text.creator_id,
        last_editor_id: @annotation_text.last_editor_id
      }
    end

    should 'on :index' do
      get_as @admin, :index, assignment_id: @assignment.id
      assert_equal true, flash.empty?
      assert render_with_layout :content
      assert render_template :index
      assert_response :success
      assert_not_nil assigns :annotation_categories
      assert_not_nil assigns :assignment
    end

    should 'on :show' do
      get_as @admin,
            :show,
            assignment_id: @assignment.id,
            id: @category.id,
            format: :js
      assert_equal true, flash.empty?
      assert_response :success
      assert_not_nil assigns :annotation_category
    end

    should 'on :new' do
      get_as @admin,
              :new,
              assignment_id: @assignment.id,
              format: :js
      assert_response :success
      assert render_template :new #this makes sure it didn't call another action
      assert_not_nil assigns :assignment
      assert_nil assigns :annotation_category
    end

    context 'on :update' do
      should 'update properly' do
        put_as @admin,
               :update,
               assignment_id: @assignment.id,
               id: @category.id,
               annotation_category: { annotation_category_name: 'Test' },
               format: :js
        assert_response :success
        assert_not_nil assigns :annotation_category
        assert_equal I18n.t('annotations.update.annotation_category_success'),
                     flash[:success]
      end

      should 'with an error on save' do
        AnnotationCategory.any_instance.stubs(:save).returns(false)

        put_as @admin,
               :update,
               assignment_id: @assignment.id,
               id: @category.id,
               annotation_category: { annotation_category_name: 'Test' },
               format: :js
        assert_response :success
        assert_not_nil flash[:error]
        assert_nil flash[:success]
        assert_not_nil assigns :annotation_category
      end
    end

    should 'on :update_annotation' do
      refute_equal @admin.id,
                   AnnotationText.find(@annotation_text.id).last_editor_id
      get_as @admin,
             :update_annotation,
             assignment_id: 1,
             id: @annotation_text.id,
             annotation_text: @annotation_text_params,
             format: :js
      assert_response :success
      assert_equal @admin.id,
                   AnnotationText.find(@annotation_text.id).last_editor_id
    end

    context 'As another admin' do
      should 'update last_editor_id with editor.id' do
        get_as @editor,
               :update_annotation,
               assignment_id: 1,
               id: @annotation_text.id,
               annotation_text: @annotation_text_params,
               format: :js
        @annotation_text = AnnotationText.find(@annotation_text.id)
        assert_response :success
        assert_equal @editor.id, @annotation_text.last_editor_id
      end
    end

    should 'on :add_annotation_text' do
      @annotation_text = AnnotationText.make(creator_id: @admin.id)
      get_as @admin,
             :add_annotation_text,
             assignment_id: 1,
             id: @category.id,
             format: :js
      @annotation_text = AnnotationText.find(@annotation_text.id)
      assert_response :success
      assert_not_nil assigns :annotation_category
      assert_nil assigns :annotation_text
      assert_equal @admin.id, @annotation_text.creator_id
    end

    should 'on :delete_annotation_text' do
      AnnotationText.any_instance.expects(:destroy).once
      get_as @admin,
             :delete_annotation_text,
             assignment_id: @assignment.id,
             id: @annotation_text.id,
             format: :js
      assert_response :success
    end

    should 'on :destroy' do
      AnnotationCategory.any_instance.expects(:destroy).once
      get_as @admin, :destroy,
             assignment_id: 1,
             id: @category.id,
             format: :js
      assert_response :success
    end

    context 'on :download' do

      should 'in csv' do
        get_as @admin,
                :download,
                assignment_id: @assignment.id,
                format: 'csv'
        assert_response :success
        assert_equal 'text/csv', response.header['Content-Type']
      end

      should 'in yml' do
        get_as @admin, :download, assignment_id: @assignment.id, format: 'yml'
        assert_response :success
        assert_equal  'application/octet-stream', response.header['Content-Type']
      end

      should 'in error' do
        get_as @admin,
               :download,
               assignment_id: @assignment.id, format: 'xml'
        assert_response :redirect
        assert set_flash.to(t('annotations.upload.flash_error',
                              format: 'xml'))
      end
    end

    should 'on :csv_upload (get)' do
      get_as @admin, :csv_upload, assignment_id: @assignment.id
      assert_response :redirect
    end

    context 'on :create' do

      should 'without errors' do
        post_as @admin,
               :create,
               assignment_id: @assignment.id,
               annotation_category: { annotation_category_name: 'Test' },
               format: :js
        assert_response :success
        assert_not_nil assigns :assignment
        assert_not_nil assigns :annotation_category
        assert render_template 'insert_new_annotation_category'
      end

      should 'with error on save' do
        AnnotationCategory.any_instance.stubs(:save).returns(false)
        post_as @admin,
                :create,
                assignment_id: @assignment.id,
                annotation_category: { annotation_category_name: 'Test' },
                format: :js
        assert_response :success
        assert_not_nil assigns :assignment
        assert_not_nil assigns :annotation_category
        assert render_template 'new_annotation_category_error'
      end
    end

    context 'on :add_annotation_text' do

      should 'without errors' do
        AnnotationText.any_instance.stubs(:save).returns(true)
        get_as @admin,
               :add_annotation_text,
               assignment_id: 1,
               id: @category.id,
               format: :js
        assert_response :success
        assert_not_nil assigns :annotation_category
        assert render_template 'insert_new_annotation_text'
      end

      should 'with errors on save' do
        AnnotationText.any_instance.stubs(:save).returns(false)
        post_as @admin, :add_annotation_text,
                assignment_id: 1,
                id: @category.id,
                annotation_text: @annotation_text_params,
                format: :js
        assert_response :success
        assert render_template 'new_annotation_text_error'
        assert_not_nil assigns :annotation_category
        assert_not_nil assigns :annotation_text
      end
    end

    should 'on :csv_upload (post)' do
      post_as @admin,
              :csv_upload,
              assignment_id: @assignment.id,
              annotation_category_list_csv: StringIO.new('name, text')
      assert_response :redirect
      assert set_flash.to(t('annotations.upload.success',
                            annotation_category_number: 1))
      assert_not_nil assigns :assignment
    end

    should 'on :csv_upload route properly' do
      assert_recognizes({controller: 'annotation_categories', assignment_id: '1', action: 'csv_upload' },
        {path: 'assignments/1/annotation_categories/csv_upload',  method: :post})
    end

    should 'on :csv_upload have valid values in database after an upload of a UTF-8 encoded file parsed as UTF-8' do
      post_as @admin,
              :csv_upload,
              assignment_id: @assignment.id,
              annotation_category_list_csv: fixture_file_upload('files/test_annotations_UTF-8.csv'),
              encoding: 'UTF-8'
      assert_response :redirect
      test_annotation = @assignment.annotation_categories.find_by_annotation_category_name('AnnotationÈrÉØrr')
      assert_not_nil test_annotation # annotation should exist
    end

    should 'on :csv_upload have valid values in database after an upload of a ISO-8859-1 encoded file parsed as ISO-8859-1' do
      post_as @admin,
              :csv_upload,
              assignment_id: @assignment.id,
              annotation_category_list_csv: fixture_file_upload('files/test_annotations_ISO-8859-1.csv'),
              encoding: 'ISO-8859-1'
      assert_response :redirect
      test_annotation = @assignment.annotation_categories.find_by_annotation_category_name('AnnotationÈrÉØrr')
      assert_not_nil test_annotation # annotation should exist
    end

    should 'on :csv_upload have valid values in database after an upload of a UTF-8 encoded file parsed as ISO-8859-1' do
      post_as @admin,
              :csv_upload,
              assignment_id: @assignment.id,
              annotation_category_list_csv: fixture_file_upload('files/test_annotations_UTF-8.csv'),
              encoding: 'ISO-8859-1'
      assert_response :redirect
      test_annotation = @assignment.annotation_categories.find_by_annotation_category_name('AnnotationÈrÉØrr')
      assert_nil test_annotation # annotation should not exist, despite being in file
    end

    context 'Annotation Categories' do
      should 'on :yml_upload' do
        @old_annotation_categories =  @assignment.annotation_categories
        # Needed, otherwise the test fail
        @old_annotation_categories.length
        post_as @admin, :yml_upload, assignment_id: @assignment.id, annotation_category_list_yml: "--- \n A:\n - A1\n - A2\n"

        assert_response :redirect
        assert set_flash.to(t('annotations.upload.success',
                              annotation_category_number: 1))
        assert_not_nil assigns :assignment
        @assignment.reload
        new_categories_list = @assignment.annotation_categories
        assert_equal(@old_annotation_categories.length + 1, (new_categories_list.length))
      end

      should 'on :yml_upload with an error' do
        @old_annotation_categories = @assignment.annotation_categories
        post_as @admin,
                :yml_upload,
                assignment_id: @assignment.id,
                annotation_category_list_yml: "--- \n A:\n - A1\n A2\n"

        assert_response :redirect
        assert set_flash.to(t('annotations.upload.syntax_error',
                              error: "syntax error on line 4, col -1: `'"))
        assert_not_nil assigns :assignment
        @assignment.reload
        new_categories_list = @assignment.annotation_categories
        assert_equal(@old_annotation_categories.length,
                     (new_categories_list.length))
      end

      should 'flash error on :yml_upload with unparseable YAML file' do
        tempfile = fixture_file_upload('files/rubric.csv')
        post_as @admin,
                :yml_upload,
                assignment_id: @assignment.id,
                annotation_category_list_yml: tempfile

        assert_response :redirect
        assert_equal(flash[:error],
                     [I18n.t('annotations.upload.unparseable_yaml')])
      end

      should 'on :yml_upload route properly' do
        assert_recognizes({controller: 'annotation_categories', assignment_id: '1', action: 'yml_upload' },
          {path: 'assignments/1/annotation_categories/yml_upload',  method: :post})
      end

      should 'on :yml_upload have valid values in database after an upload of a UTF-8 encoded file parsed as UTF-8' do
        post_as @admin,
                :yml_upload,
                assignment_id: @assignment.id,
                annotation_category_list_yml: fixture_file_upload('files/test_annotations_UTF-8.yml'),
                encoding: 'UTF-8'
        assert_response :redirect
        test_annotation = @assignment.annotation_categories.find_by_annotation_category_name('AnnotationÈrÉØrr')
        assert_not_nil test_annotation # annotation should exist
      end

      should 'on :yml_upload have valid values in database after an upload of a ISO-8859-1 encoded file parsed as ISO-8859-1' do
        post_as @admin,
                :yml_upload,
                assignment_id: @assignment.id,
                annotation_category_list_yml: fixture_file_upload('files/test_annotations_ISO-8859-1.yml'),
                encoding: 'ISO-8859-1'
        assert_response :redirect
        test_annotation = @assignment.annotation_categories.find_by_annotation_category_name('AnnotationÈrÉØrr')
        assert_not_nil test_annotation # annotation should exist
      end

      should 'on :yml_upload have valid values in database after an upload of a UTF-8 encoded file parsed as ISO-8859-1' do
        post_as @admin,
                :yml_upload,
                assignment_id: @assignment.id,
                annotcation_category_list_yml: fixture_file_upload('files/test_annotations_UTF-8.yml'),
                encoding: 'ISO-8859-1'
        assert_response :redirect
        test_annotation = @assignment.annotation_categories.find_by_annotation_category_name('AnnotationÈrÉØrr')
        assert_nil test_annotation # annotation should not exist, despite being in file
      end

      should 'on :csv_upload gracefully handle a malformed csv file' do
        tempfile = fixture_file_upload('files/malformed.csv')
        post_as @admin,
                :csv_upload,
                assignment_id: @assignment.id,
                annotation_category_list_csv: tempfile,
                encoding: 'UTF-8'
        assert_response :redirect
        assert_equal(flash[:error], [I18n.t('csv.upload.malformed_csv')])
      end

      should 'on :csv_upload gracefully handle a non csv file with .csv extension' do
        tempfile = fixture_file_upload('files/pdf_with_csv_extension.csv')
        post_as @admin,
                :csv_upload,
                assignment_id: @assignment.id,
                annotation_category_list_csv: tempfile,
                encoding: 'UTF-8'
        assert_response :redirect
        assert_equal(flash[:error],
                     [I18n.t('csv.upload.non_text_file_with_csv_extension')])
      end
    end
  end

end
