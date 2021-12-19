Rails.application.routes.draw do
  # Install the default routes as the lowest priority.
  root controller: 'main', action: 'login', via: [:post, :get]

  # optional path scope (denoted by the parentheses)
  # API routes
  namespace :api do
    resources :users, only: [:index, :create, :show, :update] do
      collection do
        put 'update_by_username'
      end
    end
    resources :courses, only: [:index, :show, :create, :update] do
      member do
        put 'update_autotest_url'
      end
      resources :roles, except: [:new, :edit, :destroy] do
        collection do
          post 'create_or_unhide'
          put 'update_by_username'
        end
      end
      resources :grade_entry_forms, only: [:show, :index, :create, :update] do
        member do
          put 'update_grades'
        end
      end
      resources :assignments, except: [:new, :edit] do
        resources :groups, except: [:new, :edit, :create, :destroy] do
          collection do
            get 'annotations'
            get 'group_ids_by_name'
          end
          resources :submission_files, only: [:index, :create] do
            collection do
              delete 'remove_file'
              delete 'remove_folder'
              post 'create_folders'
            end
          end
          resources :feedback_files, only: [:index, :create]
          member do
            get 'annotations'
            post 'add_annotations'
            post 'add_members'
            post 'create_extra_marks'
            put 'update_marks'
            put 'update_marking_state'
            delete 'remove_extra_marks'
          end
        end
        resources :starter_file_groups, only: [:index, :create]
        member do
          get 'test_files'
          get 'grades_summary'
          get 'test_specs'
          post 'update_test_specs'
        end
      end
      resources :feedback_files, only: [:show, :update, :destroy]
      resources :submission_files, only: [:update, :destroy]
      resources :starter_file_groups, only: [:show, :update, :destroy] do
        member do
          get 'entries'
          post 'create_file'
          post 'create_folder'
          delete 'remove_file'
          delete 'remove_folder'
          get 'download_entries'
        end
      end
    end
    # Return a 404 when no route is match
    match '*path', controller: 'main_api', action: 'page_not_found', via: :all
  end

  resources :courses, only: [:show, :index] do
    member do
      get 'clear_role_switch_session'
      get 'role_switch'
      post 'switch_role'
      get 'download_assignments'
      post 'upload_assignments'
    end

    resources :instructors, only: [:index, :new, :create, :edit, :update]

    resources :starter_file_groups, only: [:destroy, :update] do
      member do
        get 'download_file'
        get 'download_files'
        post 'update_files'
      end
    end

    resources :tags, only: [:edit, :update, :destroy, :create, :index] do
      member do
        get 'edit_tag_dialog'
      end
      collection do
        get 'download'
        post 'upload'
      end
    end

    resources :criteria, only: [:edit, :destroy, :update]

    resources :exam_templates, only: [:edit, :update, :destroy] do
      member do
        get 'download'
        get 'download_generate'
        get 'show_cover'
        get 'assign_errors'
        get 'download_raw_split_file'
        get 'download_error_file'
        get 'error_pages'
        patch 'add_fields'
        patch 'generate'
        patch 'split'
        post 'fix_error'
      end
    end

    resources :groups, only: [] do
      member do
        post 'rename_group'
      end
    end

    resources :submissions, only: [] do
      member do
        get 'collect_and_begin_grading'
        get 'get_file'
      end

      resources :results, only: [:edit] do
        collection do
          patch 'update_remark_request'
        end
      end
    end

    resources :results, only: [:show, :edit] do
      member do
        get 'get_annotations'
        get 'add_extra_marks'
        get 'download'
        post 'download'
        get 'download_zip'
        delete 'cancel_remark_request'
        post 'add_extra_mark'
        delete 'delete_grace_period_deduction'
        get 'next_grouping'
        delete 'remove_extra_mark'
        patch 'revert_to_automatic_deductions'
        post 'set_released_to_students'
        post 'update_overall_comment'
        post 'toggle_marking_state'
        get 'update_positions'
        patch 'update_mark'
        get 'view_marks'
        post 'add_tag'
        post 'remove_tag'
        post 'run_tests'
        get 'stop_test'
        get 'get_test_runs_instructors'
        get 'get_test_runs_instructors_released'
      end
    end

    resources :peer_reviews, only: [] do
      member do
        get 'show_result'
      end
    end

    resources :annotation_categories, only: [:show, :destroy, :update]

    resources :assignments, except: [:destroy] do
      collection do
        get 'delete_rejected'
        get 'batch_runs'
        post 'upload_config_files'
      end

      member do
        get 'download_sample_starter_files'
        get 'download_starter_file_mappings'
        get 'view_summary'
        post 'update_starter_file'
        get 'peer_review'
        get 'populate_starter_file_manager'
        get 'summary'
        get 'batch_runs'
        post 'set_boolean_graders_options'
        get 'stop_test'
        get 'stop_batch_tests'
        get 'switch'
        put 'start_timed_assignment'
        get 'starter_file'
        put 'update_starter_file'
        get 'grade_distribution'
        get 'download_config_files'
        get 'download_test_results'
      end

      resources :starter_file_groups, only: [:create]

      resources :criteria, only: [:create, :index, :new] do
        collection do
          post 'update_positions'
          post 'upload'
          get  'download'
        end
      end

      resources :automated_tests, only: [] do
        collection do
          get 'manage'
          post 'update' # because of collection
          post 'update_positions'
          get 'update_positions'
          post 'upload'
          get 'download'
          get 'get_test_runs_students'
          get 'populate_autotest_manager'
          get 'download_file'
          get 'download_files'
          post 'upload_files'
          get 'download_specs'
          post 'upload_specs'
          get 'student_interface'
          post 'execute_test_run'
        end
      end

      resources :exam_templates, only: [:index, :create] do
        collection do
          get 'view_logs'
        end
      end

      resources :groups, only: [:index, :create, :new, :destroy] do
        collection do
          get 'add_group'
          post 'use_another_assignment_groups'
          get 'manage'
          get 'assign_scans'
          get 'download'
          get 'download_starter_file'
          get 'get_names'
          get 'assign_student_and_next'
          get 'next_grouping'
          post 'upload'
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
          patch 'accept_invitation'
          patch 'decline_invitation'
          delete 'delete_rejected'
          post 'invite_member'
          patch 'disinvite_member'
        end
      end

      resources :submissions, only: [:index] do
        collection do
          get 'populate_submissions_table'
          get 'file_manager'
          get 'browse'
          get 'populate_file_manager'
          get 'revisions'
          post 'collect_submissions'
          get 'uncollect_all_submissions'
          post 'run_tests'
          get 'download_svn_export_list'
          get 'download_repo_checkout_commands'
          get 'download_repo_list'
          post 'set_result_marking_state'
          post 'update_submissions'
          get 'updated_files'
          get 'replace_files'
          get 'delete_files'
          post 'update_files'
          get 'download'
          post 'zip_groupings_files'
          get 'download_zipped_file'
          get 'notebook_content'
          get 'download_summary'
          get 'repo_browser'
          post 'repo_browser'
          post 'manually_collect_and_begin_grading'
          get 'downloads'
        end
      end

      resources :peer_reviews, only: [:index] do
        collection do
          get 'populate'
          post 'assign_groups'
          get 'peer_review_mapping'
          post 'upload'
          get 'list_reviews'
          get 'show_reviews'
        end
      end

      resources :graders, only: [:index] do
        collection do
          post 'upload'
          get 'grader_groupings_mapping'
          get 'grader_criteria_mapping'
          get 'global_actions'
          post 'global_actions'
          get 'grader_summary'
        end
      end

      resources :annotation_categories, only: [:index, :new, :create] do
        collection do
          post 'update_positions'
          post 'upload'
          get 'download'
          get 'new_annotation_text'
          post 'create_annotation_text'
          delete 'destroy_annotation_text'
          put 'update_annotation_text'
          get 'find_annotation_text'
          get 'annotation_text_uses'
          get 'uncategorized_annotations'
        end
      end
    end

    resources :grade_entry_forms, except: [:index, :destroy] do
      collection do
        get 'student_interface'
      end

      member do
        get 'populate_grades_table'
        get 'get_mark_columns'
        get 'view_summary'
        get 'grades'
        get 'download'
        post 'upload'
        post 'update_grade'
        post 'update_grade_entry_students'
        get 'student_interface'
        get 'grade_distribution'
        get 'switch'
      end

      resources :marks_graders, only: [:index] do
        collection do
          post 'upload'
          get 'grader_mapping'
          post 'assign_all'
          post 'unassign_all'
          post 'unassign_single'
          post 'randomly_assign'
        end
      end
    end

    resources :notes, except: [:show] do
      collection do
        post 'add_note'
        post 'noteable_object_selector'
        get 'new_update_groupings'
        post 'new_update_groupings'
        get 'notes_dialog'
      end
    end

    resources :course_summaries, only: [:index] do
      collection do
        get 'populate'
        get 'get_marking_scheme_details'
        get 'download_csv_grades_report'
        get 'view_summary'
        get 'grade_distribution'
      end
    end

    resources :marking_schemes, except: [:show] do
      collection do
        get 'populate'
      end
    end

    resources :sections, except: [:show]

    resources :annotations, only: [:create, :destroy, :update] do
      collection do
        post 'add_existing_annotation'
      end
    end

    resources :students, only: [:create, :new, :index, :edit, :update] do
      collection do
        patch 'bulk_modify'
        get 'manage'
        get 'add_new_section'
        get 'download'
        post 'upload'
        get 'settings'
        patch 'update_settings'
      end

      member do
        delete 'delete_grace_period_deduction'
      end
    end

    resources :tas, only: [:create, :new, :index, :edit, :update]  do
      collection do
        get 'download'
        post 'upload'
      end
    end

    resources :extensions, only: [:create, :update, :destroy]

    resources :feedback_files, only: [:show]
  end

  resources :key_pairs, only: [:new, :create, :destroy]

  resources :users, only: [] do
    collection do
      post 'reset_api_key'
      get 'settings'
      post 'settings'
      patch 'update_settings'
    end
  end

  resources :main, only: [] do
    collection do
      post 'logout'
      get 'about'
      get 'check_timeout'
      post 'refresh_session'
      get 'login_remote_auth'
    end
  end

  resources :job_messages, only: [], param: :job_id do
    member do
      get 'get'
    end
  end

  match 'main', controller: 'courses', action: 'index', via: :post
  match 'main/about', controller: 'main', action: 'about', via: :post
  match 'main/logout', controller: 'main', action: 'logout', via: :post

  match '*path', controller: 'main', action: 'page_not_found', via: :all
end
