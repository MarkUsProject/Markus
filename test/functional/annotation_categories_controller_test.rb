require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'shoulda'

class AnnotationCategoriesControllerTest < AuthenticatedControllerTest
  
  context "An unauthenticated and unauthorized user doing a GET" do
    
    # Since we are not authenticated and authorized, we should be redirected
    # to the login page
    
    context "on :index" do
      setup do
        get :index, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :get_annotations" do
      setup do
        get :get_annotations, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :add_annotation_category" do
      setup do
        get :add_annotation_category, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :update_annotation_category" do
      setup do
        get :update_annotation_category, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :update_annotation" do
      setup do
        get :update_annotation, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :add_annotation_text" do
      setup do
        get :add_annotation_text, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :delete_annotation_text" do
      setup do
        get :delete_annotation_text, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :delete_annotation_category" do
      setup do
        get :delete_annotation_category, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :download" do
      setup do
        get :download, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :csv_upload" do
      setup do
        get :csv_upload, :id => 1
      end
      should_respond_with :redirect
    end
    
  end # end unauthenticated/unauthorized user GET
  
  context "An unauthenticated and unauthorized user doing a POST" do

    # Since we are not authenticated and authorized, we should be redirected
    # to the login page
    
    context "on :index" do
      setup do
        post :index, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :get_annotations" do
      setup do
        post :get_annotations, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :add_annotation_category" do
      setup do
        post :add_annotation_category, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :update_annotation_category" do
      setup do
        post :update_annotation_category, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :update_annotation" do
      setup do
        post :update_annotation, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :add_annotation_text" do
      setup do
        post :add_annotation_text, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :delete_annotation_text" do
      setup do
        post :delete_annotation_text, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :delete_annotation_category" do
      setup do
        post :delete_annotation_category, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :download" do
      setup do
        post :download, :id => 1
      end
      should_respond_with :redirect
    end
    
    context "on :csv_upload" do
      setup do
        post :csv_upload, :id => 1
      end
      should_respond_with :redirect
    end
    
  end # end unauthenticated/unauthorized user POST
  
  context "An authorized and authenticated user doing a GET" do
    
    fixtures  :users, :assignments, :annotation_categories
    
    context "on :index" do
      setup do
        admin = users(:olm_admin_1)
        assignment = assignments(:assignment_1)
        get_as admin, :index, :id => assignment.id
      end
      
      should_not_set_the_flash
      should_render_with_layout :content
      should_render_template :index
      should_respond_with :success
      should_assign_to :annotation_categories, :assignment
    end
    
    context "on :get_annotations" do
      
      setup do
        admin = users(:olm_admin_1)
        category = annotation_categories(:one)
        get_as admin, :get_annotations, :id => category.id
      end
      
      should_not_set_the_flash
      should_respond_with :success
      should_assign_to :annotation_category, :annotation_texts
    end
    
    context "on :add_annotation_category" do
      setup do
        admin = users(:olm_admin_1)
        assignment = assignments(:assignment_1)
        get_as admin, :add_annotation_category, :id => assignment.id
      end
      should_respond_with :success
      should_assign_to :assignment
    end
    
    context "on :update_annotation_category" do
      setup do
        admin = users(:olm_admin_1)
        category = annotation_categories(:one)
        get_as admin, :update_annotation_category, :id => category.id
      end
      should_respond_with :success
      should_assign_to :annotation_category
    end
  
    
#    context "on :update_annotation" do
#      setup do
#        get :update_annotation, :id => 1
#      end
#      should_respond_with :redirect
#    end
#    
#    context "on :add_annotation_text" do
#      setup do
#        get :add_annotation_text, :id => 1
#      end
#      should_respond_with :redirect
#    end
#    
#    context "on :delete_annotation_text" do
#      setup do
#        get :delete_annotation_text, :id => 1
#      end
#      should_respond_with :redirect
#    end
#    
#    context "on :delete_annotation_category" do
#      setup do
#        get :delete_annotation_category, :id => 1
#      end
#      should_respond_with :redirect
#    end
#    
#    context "on :download" do
#      setup do
#        get :download, :id => 1
#      end
#      should_respond_with :redirect
#    end
#    
#    context "on :csv_upload" do
#      setup do
#        get :csv_upload, :id => 1
#      end
#      should_respond_with :redirect
#    end
    
  end
  
end
