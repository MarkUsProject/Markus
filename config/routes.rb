# Required for filtering locale prefixed requests
require 'routing_filter'

Markus::Application.routes.draw do
  filter :locale

  # Install the default routes as the lowest priority.
  root :controller => "main", :action => "login"
   # API routes
  namespace :api, :defaults => { :format => 'text' } do
    resources :test_results, :except => [:new, :edit]
    resources :submission_downloads, :except => [:new, :edit]
    resources :users, :except => [:new, :edit]
    resources :main_api
  end

  resources :admins do
    collection do
      post 'populate'
    end
  end

  resources :assignments do

    collection do
      get 'download_csv_grades_report'
      get 'update_group_properties_on_persist'
      get 'delete_rejected'
      post 'update_collected_submissions'
    end

    member do
      get 'refresh_graph'
      get 'student_interface'
      get 'update_group_properties_on_persist'
      post 'invite_member'
      get 'creategroup'
      get 'join_group'
      get 'deletegroup'
      get 'decline_invitation'
      post 'disinvite_member'
      get 'render_test_result'
    end

    resources :rubrics do
      member do
        delete 'destroy'
        get 'move_criterion'
      end

      collection do
        post 'update_positions'
        post 'csv_upload'
        post 'yml_upload'
        get 'download_csv'
        get 'download_yml'
      end
    end

    resources :flexible_criteria do
      collection do
        post 'upload'
        get 'update_positions'
        get 'move_criterion'
        get 'download'
      end
    end

    resources :automated_tests do
      collection do
        get 'manage'
        post 'update' # because of collection
        post 'update_positions'
        get 'update_positions'
        post 'upload'
        get 'download'
        get 'move_criterion'
      end
    end

    resources :groups do

      member do
        post 'rename_group'
        get 'rename_group_dialog'
      end

      collection do
        post 'populate'
        post 'populate_students'
        get 'add_group'
        get 'use_another_assignment_groups'
        get 'manage'
        post 'csv_upload'
        get 'add_csv_group'
        get 'download_grouplist'
        get 'create_groups_when_students_work_alone'
        get 'valid_grouping'
        get 'invalid_grouping'
        get 'global_actions'
        get 'rename_group'
        delete 'remove_group'
        post 'add_group'
        post 'global_actions'
      end
    end

    resources :submissions do
      collection do
        get 'file_manager'
        get 'browse'
        post 'populate_file_manager'
        get 'collect_all_submissions'
        get 'download_simple_csv_report'
        get 'download_detailed_csv_report'
        get 'download_svn_export_list'
        get 'download_svn_export_commands'
        get 'download_svn_repo_list'
        get 'collect_ta_submissions'
        get 'update_submissions'
        post 'populate_repo_browser'
        post 'update_converted_pdfs'
        get 'updated_files'
        get 'replace_files'
        get 'delete_files'
        post 'update_files'
        post 'server_time'
        get 'download'
      end

      member do
        get 'collect_and_begin_grading'
        post 'manually_collect_and_begin_grading'
        get 'repo_browser'
      end

      resources :results do
        collection do
          get 'update_mark'
          get 'expand_criteria'
          get 'collapse_criteria'
          get 'expand_unmarked_criteria'
          get 'edit'
          get 'download'
        end

        member do
          get 'add_extra_marks'
          get 'add_extra_mark'
          get 'download'
          post 'download'
          get 'cancel_remark_request'
          get 'codeviewer'
          post 'codeviewer'
          post 'collapse_criteria'
          post 'add_extra_mark'
          get 'next_grouping'
          post 'remove_extra_mark'
          post 'expand_unmarked_criteria'
          get 'set_released_to_students'
          post 'update_overall_comment'
          post 'update_overall_remark_comment'
          post 'update_marking_state'
          get 'update_remark_request'
          get 'update_positions'
          get 'update_mark'
          get 'expand_criteria'
          get 'view_marks'
        end
      end
    end

    resources :graders do
      collection do
        get 'add_grader_to_grouping'
        post 'csv_upload_grader_groups_mapping'
        post 'csv_upload_grader_criteria_mapping'
        get 'download_grader_groupings_mapping'
        get 'download_grader_criteria_mapping'
        get 'download_dialog'
        get 'download_grouplist'
        get 'grader_criteria_dialog'
        get 'global_actions'
        get 'groups_coverage_dialog'
        post 'populate_graders'
        post 'populate'
        post 'populate_criteria'
        post 'set_assign_criteria'
        get 'random_assign'
        get 'upload_dialog'
        get 'unassign'
        post 'global_actions'
      end
    end

    resources :annotation_categories do
      member do
        get 'get_annotations'
        delete 'delete_annotation_category'
        delete 'delete_annotation_text'
        get 'add_annotation_text'
        post 'add_annotation_text'
        put 'update_annotation'
      end

      collection do
        get 'add_annotation_category'
        post 'csv_upload'
        get 'delete_annotation_category'
        get 'download'
        post 'yml_upload'
        post 'add_annotation_category'
        post 'update_annotation_category'
        get 'add_annotation_text'
        post 'delete_annotation_text'
        post 'update_annotation'
      end
    end
  end

  resources :grade_entry_forms do
    collection do
      get 'student_interface'
    end

    member do
      get 'grades'
      get 'g_table_paginate'
      get 'csv_download'
      post 'csv_upload'
      post 'update_grade'
      post 'update_grade_entry_students'
      get 'student_interface'
    end
  end

  resources :notes do

    collection do
      post 'add_note'
      post 'noteable_object_selector'
      get 'new_update_groupings'
      post 'new_update_groupings'
    end

    member do
      get 'student_interface'
      get 'notes_dialog'
      post 'grades'
    end
  end

  resources :sections

  resources :annotations do
    collection do
      post 'add_existing_annotation'
      put 'update_annotation'
      post 'update_comment'
      delete 'destroy'
    end
  end

  resources :students do
    collection do
      post 'bulk_modify'
      post 'populate'
      get 'manage'
      get 'add_new_section'
      get 'download_student_list'
      post 'upload_student_list'
    end
  end

  resources :tas  do
    collection do
      post 'populate'
      post 'upload_ta_list'
      get 'download_ta_list'
    end
  end

  resources :main do
    collection do
      get 'logout'
      get 'about'
      post 'login_as'
      get 'role_switch'
      get 'clear_role_switch_session'
      post 'reset_api_key'
    end
  end

  match 'main', :controller => 'main', :action => 'index'
  match 'main/about', :controller => 'main', :action => 'about'
  match 'main/logout', :controller => 'main', :action => 'logout'

  # Return a 404 when no route is match
  match '*path', :controller => 'main', :action => 'page_not_found'
end
