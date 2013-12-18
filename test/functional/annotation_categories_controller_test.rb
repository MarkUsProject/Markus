  # encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'
require 'mocha/setup'

class AnnotationCategoriesControllerTest < AuthenticatedControllerTest

  context 'An unauthenticated user' do

    # Since we are not authenticated and authorized, we should be redirected
    # to the login page

    should 'on :index (get)' do
      get :index, :assignment_id => 1
      assert_response :redirect
    end

    should 'on :get_annotations (get)' do
      get :get_annotations, :assignment_id => 1,:id => 1
      assert_response :redirect
    end

    should 'on :add_annotation_category (get)' do
      get :add_annotation_category, :assignment_id => 1
      assert_response :redirect
    end

    should 'on :update_annotation_category (get)' do
      get :update_annotation_category, :assignment_id => 1
      assert_response :redirect
    end

    should 'on :add_annotation_text (get)' do
      get :add_annotation_text, :assignment_id => 1, :id => 1
      assert_response :redirect
    end

    should 'on :delete_annotation_category (get)' do
      get :delete_annotation_category, :assignment_id => 1
      assert_response :redirect
    end

    should 'on :download (get)' do
      get :download, :assignment_id => 1
      assert_response :redirect
    end

    should 'on :csv_upload (get)' do
      get :csv_upload, :assignment_id => 1
      assert_response :redirect
    end

    should 'on :index (post)' do
      post :index, :assignment_id => 1
      assert_response :redirect
    end

    should 'on :get_annotations (post)' do
      post :get_annotations, :assignment_id => 1, :id => 1
      assert_response :redirect
    end

    should 'on :add_annotation_category (post)' do
      post :add_annotation_category, :assignment_id => 1
      assert_response :redirect
    end

    should 'on :update_annotation_category (post)' do
      post :update_annotation_category, :assignment_id => 1
      assert_response :redirect
    end

    should 'on :update_annotation (post)' do
      post :update_annotation, :assignment_id => 1, :id => 1
      assert_response :redirect
    end

    should 'on :add_annotation_text (post)' do
      post :add_annotation_text, :assignment_id => 1, :id => 1
      assert_response :redirect
    end

    should 'on :delete_annotation_text (post)' do
      post :delete_annotation_text, :assignment_id => 1, :id => 1
      assert_response :redirect
    end

    should 'on :delete_annotation_category (post)' do
      post :delete_annotation_category, :assignment_id => 1
      assert_response :redirect
    end

    should 'on :download (post)' do
      post :download, :assignment_id => 1
      assert_response :redirect
    end

    should 'on :csv_upload (post)' do
      post :csv_upload, :assignment_id => 1
      assert_response :redirect
    end

    should 'on :update_annotation' do
      put :update_annotation, :assignment_id => 1, :id => 1
      assert_response :redirect
    end

    should 'on :delete_annotation_text' do
      delete :delete_annotation_text, :assignment_id => 1, :id => 1
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
                :annotation_category => @category,
                :creator_id => @admin.id,
                :last_editor_id => @admin.id)
    end

    should 'on :index' do
      get_as @admin, :index, :assignment_id => @assignment.id
      assert_equal true, flash.empty?
      assert render_with_layout :content
      assert render_template :index
      assert_response :success
      assert_not_nil assigns :annotation_categories
      assert_not_nil assigns :assignment
    end

    should 'on :get_annotations' do
      get_as @admin,
            :get_annotations,
            :assignment_id => @assignment.id,
            :id => @category.id,
            :format => :js
      assert_equal true, flash.empty?
      assert_response :success
      assert_not_nil assigns :annotation_category
      assert_not_nil assigns :annotation_texts
    end

    should 'on :add_annotation_category' do
      get_as @admin,
              :add_annotation_category,
              :assignment_id => @assignment.id,
              :format => :js
      assert_response :success
      assert render_template :add_annotation_category #this makes sure it didn't call another action
      assert_not_nil assigns :assignment
      assert_nil assigns :annotation_category
    end

    context 'on :update_annotation_category' do
      should 'update properly' do
        get_as @admin,
               :update_annotation_category,
               :assignment_id => @assignment.id,
               :id => @category.id,
               :format => :js
        assert_response :success
        assert_not_nil assigns :annotation_category
        assert_equal I18n.t('annotations.update.annotation_category_success'),
                     flash[:success]
      end

      should 'with an error on save' do
        AnnotationCategory.any_instance.stubs(:save).returns(false)

        get_as @admin,
                :update_annotation_category,
                :assignment_id => @assignment.id,
                :id => @category.id,
                :format => :js
        assert_response :success
        assert_not_nil flash[:error]
        assert_nil flash[:success]
        assert_not_nil assigns :annotation_category
      end
    end

    should 'on :update_annotation' do
      AnnotationText.any_instance.expects(:update_attributes).with(
            @annotation_text)
      AnnotationText.any_instance.expects(:save).once
      get_as @admin,
              :update_annotation,
              :assignment_id => 1,
              :id => @annotation_text.id,
              :annotation_text => @annotation_text,
              :format => :js
      assert_response :success
    end

    context 'As another admin' do
        should 'update last_editor_id with editor.id' do
            AnnotationText.any_instance.expects(:update_attributes).with(
              @annotation_text)          
            get_as @editor,
                :update_annotation,
                :assignment_id => 1,
                :id => @annotation_text.id,
                :annotation_text => @annotation_text,
                :format => :js
        @annotation_text = AnnotationText.find(@annotation_text.id)
        assert_response :success
        assert_equal @editor.id, @annotation_text.last_editor_id
      end
    end

    should 'on :add_annotation_text' do
      @annotation_text = AnnotationText.make(:creator_id => @admin.id)
      get_as @admin,
             :add_annotation_text,
             :assignment_id => 1,
             :id => @category.id,
             :format => :js
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
             :assignment_id => @assignment.id,
             :id => @annotation_text.id,
             :format => :js
      assert_response :success
    end

    should 'on :delete_annotation_category' do
      AnnotationCategory.any_instance.expects(:destroy).once
      get_as @admin, :delete_annotation_category,
             :assignment_id => 1,
             :id => @category.id,
             :format => :js
      assert_response :success
    end

    context 'on :download' do

      should 'in csv' do
        get_as @admin,
                :download,
                :assignment_id => @assignment.id,
                :format => 'csv'
        assert_response :success
        assert_equal response.header['Content-Type'], 'application/octet-stream'
      end

      should 'in yml' do
        get_as @admin, :download, :assignment_id => @assignment.id, :format => 'yml'
        assert_response :success
        assert_equal response.header['Content-Type'], 'application/octet-stream'
      end

      should 'in error' do
        get_as @admin,
               :download,
               :assignment_id => @assignment.id, :format => 'xml'
        assert_response :redirect
        assert set_the_flash.to((I18n.t('annotations.upload.flash_error',
                                        :format => 'xml')))
      end
    end

    should 'on :csv_upload (get)' do
      get_as @admin, :csv_upload, :assignment_id => @assignment.id
      assert_response :redirect
    end

    context 'on :add_annotation_category' do

      should 'without errors' do
        AnnotationCategory.any_instance.stubs(:save).returns(true)
        get_as @admin,
               :add_annotation_category,
               :assignment_id => @assignment.id,
               :format => :js
        assert_response :success
        assert_not_nil assigns :assignment
      end

      should 'with error on save' do
        AnnotationCategory.any_instance.stubs(:save).returns(false)
        post_as @admin,
                :add_annotation_category,
                :assignment_id => @assignment.id,
                :format => :js
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
               :assignment_id => 1,
               :id => @category.id,
               :format => :js
        assert_response :success
        assert_not_nil assigns :annotation_category
        assert render_template 'insert_new_annotation_text'
      end

      should 'with errors on save' do
        AnnotationText.any_instance.stubs(:save).returns(false)
        post_as @admin, :add_annotation_text,
                :assignment_id => 1,
                :id => @category.id,
                :format => :js
        assert_response :success
        assert render_template 'new_annotation_text_error'
        assert_not_nil assigns :annotation_category
        assert_not_nil assigns :annotation_text
      end
    end

    should 'on :csv_upload (post)' do
      post_as @admin,
              :csv_upload,
              :assignment_id => @assignment.id,
              :annotation_category_list_csv => StringIO.new('name, text')
      assert_response :redirect
      assert set_the_flash.to((I18n.t('annotations.upload.success', :annotation_category_number => 1)))
      assert_not_nil assigns :assignment
    end

    should 'on :csv_upload route properly' do
      assert_recognizes({:controller => 'annotation_categories', :assignment_id => '1', :action => 'csv_upload' },
        {:path => 'assignments/1/annotation_categories/csv_upload',  :method => :post})
    end

    should 'on :csv_upload have valid values in database after an upload of a UTF-8 encoded file parsed as UTF-8' do
      post_as @admin,
              :csv_upload,
              :assignment_id => @assignment.id,
              :annotation_category_list_csv => fixture_file_upload('files/test_annotations_UTF-8.csv'),
              :encoding => 'UTF-8'
      assert_response :redirect
      test_annotation = @assignment.annotation_categories.find_by_annotation_category_name('AnnotationÈrÉØrr')
      assert_not_nil test_annotation # annotation should exist
    end

    should 'on :csv_upload have valid values in database after an upload of a ISO-8859-1 encoded file parsed as ISO-8859-1' do
      post_as @admin,
              :csv_upload,
              :assignment_id => @assignment.id,
              :annotation_category_list_csv => fixture_file_upload('files/test_annotations_ISO-8859-1.csv'),
              :encoding => 'ISO-8859-1'
      assert_response :redirect
      test_annotation = @assignment.annotation_categories.find_by_annotation_category_name('AnnotationÈrÉØrr')
      assert_not_nil test_annotation # annotation should exist
    end

    should 'on :csv_upload have valid values in database after an upload of a UTF-8 encoded file parsed as ISO-8859-1' do
      post_as @admin,
              :csv_upload,
              :assignment_id => @assignment.id,
              :annotation_category_list_csv => fixture_file_upload('files/test_annotations_UTF-8.csv'),
              :encoding => 'ISO-8859-1'
      assert_response :redirect
      test_annotation = @assignment.annotation_categories.find_by_annotation_category_name('AnnotationÈrÉØrr')
      assert_nil test_annotation # annotation should not exist, despite being in file
    end

    context 'Annotation Categories' do
      should 'on :yml_upload' do
        @old_annotation_categories =  @assignment.annotation_categories
        # Needed, otherwise the test fail
        @old_annotation_categories.length
        post_as @admin, :yml_upload, :assignment_id => @assignment.id, :annotation_category_list_yml => "--- \n A:\n - A1\n - A2\n"

        assert_response :redirect
        assert set_the_flash.to((I18n.t('annotations.upload.success', :annotation_category_number => 1)))
        assert_not_nil assigns :assignment
        @assignment.reload
        new_categories_list = @assignment.annotation_categories
        assert_equal(@old_annotation_categories.length + 1, (new_categories_list.length))
      end

      should 'on :yml_upload with an error' do
        @old_annotation_categories = @assignment.annotation_categories
        post_as @admin,
                :yml_upload,
                :assignment_id => @assignment.id,
                :annotation_category_list_yml => "--- \n A:\n - A1\n A2\n"

        assert_response :redirect
        assert set_the_flash.to((I18n.t('annotations.upload.syntax_error', :error => "syntax error on line 4, col -1: `'")))
        assert_not_nil assigns :assignment
        @assignment.reload
        new_categories_list = @assignment.annotation_categories
        assert_equal(@old_annotation_categories.length,
                     (new_categories_list.length))
      end

      should 'on :yml_upload route properly' do
        assert_recognizes({:controller => 'annotation_categories', :assignment_id => '1', :action => 'yml_upload' },
          {:path => 'assignments/1/annotation_categories/yml_upload',  :method => :post})
      end

      should 'on :yml_upload have valid values in database after an upload of a UTF-8 encoded file parsed as UTF-8' do
        post_as @admin,
                :yml_upload,
                :assignment_id => @assignment.id,
                :annotation_category_list_yml => fixture_file_upload('files/test_annotations_UTF-8.yml'),
                :encoding => 'UTF-8'
        assert_response :redirect
        test_annotation = @assignment.annotation_categories.find_by_annotation_category_name('AnnotationÈrÉØrr')
        assert_not_nil test_annotation # annotation should exist
      end

      should 'on :yml_upload have valid values in database after an upload of a ISO-8859-1 encoded file parsed as ISO-8859-1' do
        post_as @admin,
                :yml_upload,
                :assignment_id => @assignment.id,
                :annotation_category_list_yml => fixture_file_upload('files/test_annotations_ISO-8859-1.yml'),
                :encoding => 'ISO-8859-1'
        assert_response :redirect
        test_annotation = @assignment.annotation_categories.find_by_annotation_category_name('AnnotationÈrÉØrr')
        assert_not_nil test_annotation # annotation should exist
      end

      should 'on :yml_upload have valid values in database after an upload of a UTF-8 encoded file parsed as ISO-8859-1' do
        post_as @admin,
                :yml_upload,
                :assignment_id => @assignment.id,
                :annotcation_category_list_yml => fixture_file_upload('files/test_annotations_UTF-8.yml'),
                :encoding => 'ISO-8859-1'
        assert_response :redirect
        test_annotation = @assignment.annotation_categories.find_by_annotation_category_name('AnnotationÈrÉØrr')
        assert_nil test_annotation # annotation should not exist, despite being in file
      end
    end
  end

end
