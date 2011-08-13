# Required for filtering locale prefixed requests
require 'routing_filter'

Markus::Application.routes.draw do
  filter :locale

  # Install the default routes as the lowest priority.
  root :controller => "main", :action => "login"
   # API routes
  namespace :api do
    resources :test_results
    resources :submission_downloads
    resources :users
  end

  resources :admins do
    collection do
      get 'populate'
    end
  end

  resources :annotation_categories do
    member do
      get 'get_annotations'
      get 'add_annotation_category'
      get 'add_annotation_text'
      get 'csv_upload'
      get 'delete_annotation_category'
      get 'download'
      get 'yml_upload'
      post 'delete_annotation_text'
      post 'update_annotation_category'
      post 'update_annotation'
    end
  end

  resources :annotations do
    member do
      post 'update_comment'
    end
  end

  resources :assignments do
    collection do
      get 'download_csv_grades_report'
      get 'update_group_properties_on_persist'
    end
    member do
      get 'refresh_graph'
      get 'update_group_properties_on_persist'
    end

    resources :rubrics
    resources :flexible_criteria
    resources :test_framework
  end

  resources :flexible_criteria

  resources :grade_entry_forms do
    collection do
      post 'student_interface'
    end
    member do
      post 'grades'
      post 'update_grade'
      post 'student_interface'
      post 'update_grade_entry_students'
    end
  end

  resources :graders do
    member do
      get 'manage'
    end
  end

  resources :groups do
    member do
      get 'manage'
    end
  end

  resources :note do
    collection do
      get 'noteable_object_selector'
    end
    member do
      get 'student_interface'
      post 'grades'
    end
  end

  resources :results

  resources :rubric

  resources :sections

  resources :students do
    collection do
      get 'populate'
      get 'manage'
      get 'download_student_list'
      get 'upload_student_list'
    end
  end

  resources :submissions do
    member do
      get 'browse'
    end
  end

  resources :tas  do
    collection do
      get 'populate'
      get 'upload_ta_list'
      get 'download_ta_list'
    end
  end


  resources :test_framework

  match 'main', :controller => 'main', :action => 'index'
  match 'main/about', :controller => 'main', :action => 'about'
  match 'main/logout', :controller => 'main', :action => 'logout'


  # Return a 404 when no route is match
  match '*path', :controller => 'main', :action => 'page_not_found'
end
