require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'shoulda'
require 'mocha'

class AnnotationCategoriesControllerTest < AuthenticatedControllerTest

  fixtures :all

  context "An unauthenticated and unauthorized user doing a GET" do

    # Since we are not authenticated and authorized, we should be redirected
    # to the login page

    context "on :index" do
      setup do
        get :index, :id => 1
      end
      should respond_with :redirect
    end

    context "on :get_annotations" do
      setup do
        get :get_annotations, :id => 1
      end
      should respond_with :redirect
    end

    context "on :add_annotation_category" do
      setup do
        get :add_annotation_category, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update_annotation_category" do
      setup do
        get :update_annotation_category, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update_annotation" do
      setup do
        get :update_annotation, :id => 1
      end
      should respond_with :redirect
    end

    context "on :add_annotation_text" do
      setup do
        get :add_annotation_text, :id => 1
      end
      should respond_with :redirect
    end

    context "on :delete_annotation_text" do
      setup do
        get :delete_annotation_text, :id => 1
      end
      should respond_with :redirect
    end

    context "on :delete_annotation_category" do
      setup do
        get :delete_annotation_category, :id => 1
      end
      should respond_with :redirect
    end

    context "on :download" do
      setup do
        get :download, :id => 1
      end
      should respond_with :redirect
    end

    context "on :csv_upload" do
      setup do
        get :csv_upload, :id => 1
      end
      should respond_with :redirect
    end

  end # end unauthenticated/unauthorized user GET

  context "An unauthenticated and unauthorized user doing a POST" do

    # Since we are not authenticated and authorized, we should be redirected
    # to the login page

    context "on :index" do
      setup do
        post :index, :id => 1
      end
      should respond_with :redirect
    end

    context "on :get_annotations" do
      setup do
        post :get_annotations, :id => 1
      end
      should respond_with :redirect
    end

    context "on :add_annotation_category" do
      setup do
        post :add_annotation_category, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update_annotation_category" do
      setup do
        post :update_annotation_category, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update_annotation" do
      setup do
        post :update_annotation, :id => 1
      end
      should respond_with :redirect
    end

    context "on :add_annotation_text" do
      setup do
        post :add_annotation_text, :id => 1
      end
      should respond_with :redirect
    end

    context "on :delete_annotation_text" do
      setup do
        post :delete_annotation_text, :id => 1
      end
      should respond_with :redirect
    end

    context "on :delete_annotation_category" do
      setup do
        post :delete_annotation_category, :id => 1
      end
      should respond_with :redirect
    end

    context "on :download" do
      setup do
        post :download, :id => 1
      end
      should respond_with :redirect
    end

    context "on :csv_upload" do
      setup do
        post :csv_upload, :id => 1
      end
      should respond_with :redirect
    end

  end # end unauthenticated/unauthorized user POST

  context "An authorized and authenticated user doing a GET" do
    fixtures  :users, :assignments, :annotation_categories, :annotation_texts

    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:assignment_1)
      @category = annotation_categories(:one)
      @annotation_text = annotation_texts(:one)
    end

    context "on :index" do
      setup do
        get_as @admin, :index, :id => @assignment.id
      end
      should_not set_the_flash
      should render_with_layout :content
      should render_template :index
      should respond_with :success
      should assign_to :annotation_categories
      should assign_to :assignment
    end

    context "on :get_annotations" do
      setup do
        get_as @admin, :get_annotations, :id => @category.id
      end
      should_not set_the_flash
      should respond_with :success
      should assign_to :annotation_category
      should assign_to :annotation_texts
    end

    context "on :add_annotation_category" do
      setup do
        get_as @admin, :add_annotation_category, :id => @assignment.id
      end
      should respond_with :success
      should render_template :add_annotation_category #this makes sure it didn't call another action
      should assign_to :assignment
      should_not assign_to :annotation_category
    end

    context "on :update_annotation_category" do

      context "without errors" do
        setup do
          get_as @admin, :update_annotation_category, :id => @category.id
        end
        should respond_with :success
        should_not set_the_flash
        should assign_to :annotation_category
      end

      context "with an error on save" do
        setup do
          AnnotationCategory.any_instance.stubs(:save).returns(false)
          AnnotationCategory.any_instance.stubs(:errors).returns("error")
          get_as @admin, :update_annotation_category, :id => @category.id
        end
        should respond_with :success
        should_not set_the_flash
        should assign_to :annotation_category
      end

    end

    context "on :update_annotation" do
      setup do
        AnnotationText.any_instance.expects(:update_attributes).with(@annotation_text)
        AnnotationText.any_instance.expects(:save).once
        get_as @admin, :update_annotation, :id => @annotation_text.id, :annotation_text => @annotation_text
      end
      should respond_with :success
    end

    context "on :add_annotation_text" do
      setup do
        AnnotationText.any_instance.expects(:save).never
        get_as @admin, :add_annotation_text, :id => @category.id
      end
      should respond_with :success
      should assign_to :annotation_category
      should_not assign_to :annotation_text
    end

    context "on :delete_annotation_text" do
      setup do
        AnnotationText.any_instance.expects(:destroy).once
        get_as @admin, :delete_annotation_text, :id => @annotation_text.id
      end
      should respond_with :success
    end

    context "on :delete_annotation_category" do
      setup do
        AnnotationCategory.any_instance.expects(:destroy).once
        get_as @admin, :delete_annotation_category, :id => @category.id
      end
      should respond_with :success
    end

    context "on :download" do

      context "in csv" do
        setup do
          get_as @admin, :download, :id => @assignment.id, :format => 'csv'
        end
        should respond_with :success
        should respond_with_content_type 'application/octet-stream'
      end

      context "in yml" do
        setup do
          get_as @admin, :download, :id => @assignment.id, :format => 'yml'
        end
        should respond_with :success
        should respond_with_content_type 'application/octet-stream'
      end

      context "in error" do
        setup do
          get_as @admin, :download, :id => @assignment.id, :format => 'xml'
        end
        should respond_with :redirect
        should set_the_flash.to((I18n.t("annotations.upload.flash_error", :format => 'xml')))
      end
    end

    context "on :csv_upload" do
      setup do
        get_as @admin, :csv_upload, :id => @assignment.id
      end
      should respond_with :redirect
    end
  end # end authenticated/authorized user GET

  context "An authorized and authenticated user doing a POST" do

    setup do
      @admin = users(:olm_admin_1)
      @assignment = assignments(:assignment_1)
      @category = annotation_categories(:one)
      @annotation_text = annotation_texts(:one)
    end

    context "on :add_annotation_category" do

      context "without errors" do
        setup do
          AnnotationCategory.any_instance.stubs(:save).returns(true)
          post_as @admin, :add_annotation_category, :id => @assignment.id
        end
        should respond_with :success
        should assign_to :assignment
        should assign_to :annotation_category
        should render_template 'insert_new_annotation_category'
      end

      context "with error on save" do
        setup do
          AnnotationCategory.any_instance.stubs(:save).returns(false)
          post_as @admin, :add_annotation_category, :id => @assignment.id
        end
        should respond_with :success
        should assign_to :assignment
        should assign_to :annotation_category
        should render_template 'new_annotation_category_error'
      end
    end

    context "on :add_annotation_text" do

      context "without errors" do
        setup do
          AnnotationText.any_instance.stubs(:save).returns(true)
          post_as @admin, :add_annotation_text, :id => @category.id
        end
        should respond_with :success
        should render_template 'insert_new_annotation_text'
        should assign_to :annotation_category
        should assign_to :annotation_text
      end

      context "with errors on save" do
        setup do
          AnnotationText.any_instance.stubs(:save).returns(false)
          post_as @admin, :add_annotation_text, :id => @category.id
        end
        should respond_with :success
        should render_template 'new_annotation_text_error'
        should assign_to :annotation_category
        should assign_to :annotation_text
      end
    end

    context "on :csv_upload" do
      setup do
        post_as @admin, :csv_upload, :id => @assignment.id, :annotation_category_list => 'name, text'
      end
      should respond_with :redirect
      should set_the_flash.to((I18n.t('annotations.upload.success', :annotation_category_number => 1)))
      should assign_to :assignment
    end
  end

end
