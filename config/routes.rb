Rails.application.routes.draw do
  resources :key_pairs

  # Install the default routes as the lowest priority.
  root controller: 'main', action: 'login', via: [:post, :get]

  # optional path scope (denoted by the parentheses)
  scope '(:locale)', locale: /en|es|fr|pt/  do
    # API routes
    namespace :api do
      resources :users, except: [:new, :edit]
      resources :grade_entry_forms, only: [:show]
      resources :assignments, except: [:new, :edit] do
        resources :groups, except: [:new, :edit] do
          collection do
            get 'group_ids_by_name'
          end
          resources :submission_downloads, except: [:new, :edit]
          resources :feedback_files, except: [:new, :edit]
          resources :test_script_results, except: [:new, :edit] do
            resources :test_results, except: [:new, :edit]
          end
          member do
            post 'add_annotations'
            put 'update_marks'
            put 'update_marking_state'
          end
        end
      end
      resources :main_api
    end

    resources :admins

    resources :assignments do

      collection do
        get 'delete_rejected'
        post 'update_collected_submissions'
        get 'download_assignment_list'
        post 'upload_assignment_list'
        get 'batch_runs'
      end

      member do
        get 'refresh_graph'
        get 'student_interface'
        get 'render_feedback_file'
        get 'view_summary'
        get 'populate_file_manager'
        post 'update_files'
        get 'download_starter_code'
        get 'peer_review'
        get 'summary'
        get 'csv_summary'
        get 'batch_runs'
        get 'stop_test'
        get 'stop_batch_tests'
      end

      resources :tags do
        collection do
          get 'download_tag_list'
          post 'csv_upload'
          post 'yml_upload'
        end

        member do
          post 'update_tag'
          get 'edit_tag_dialog'
          get 'destroy'
        end
      end

      resources :criteria do
        collection do
          post 'update_positions'
          post 'upload_yml'
          get  'download_yml'
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
          get 'get_test_runs_students'
        end
      end

      resources :exam_templates do
        member do
          get 'download'
          get 'download_generate'
          get 'assign_errors'
          get 'download_raw_split_file'
          get 'download_error_file'
          get 'error_pages'
          patch 'generate'
          patch 'split'
          post 'fix_error'
        end

        collection do
          get 'view_logs'
        end
      end

      resources :groups do

        member do
          post 'rename_group'
          post 'invite_member'
          get 'join_group'
          get 'decline_invitation'
          post 'disinvite_member'
        end

        collection do
          get 'add_group'
          post 'use_another_assignment_groups'
          get 'manage'
          get 'assign_scans'
          get 'download'
          get 'get_names'
          get 'assign_student_and_next'
          get 'next_grouping'
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

      resources :submissions, only: [:index] do
        collection do
          get 'populate_submissions_table'
          get 'populate_peer_submissions_table'
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
          post 'update_submissions'
          get 'updated_files'
          get 'replace_files'
          get 'delete_files'
          post 'update_files'
          get 'server_time'
          get 'download'
          get 'download_groupings_files'
          get 'check_collect_status'
        end

        member do
          get 'collect_and_begin_grading'
          post 'manually_collect_and_begin_grading'
          get 'repo_browser'
          post 'repo_browser'
          get 'downloads'
          get 'get_file'
        end

        resources :results do
          collection do
            post 'update_mark'
            get 'edit'
            get 'download'
          end

          member do
            get 'get_annotations'
            get 'add_extra_marks'
            get 'add_extra_mark'
            get 'download'
            post 'download'
            get 'download_zip'
            delete 'cancel_remark_request'
            post 'add_extra_mark'
            post 'delete_grace_period_deduction'
            get 'next_grouping'
            post 'remove_extra_mark'
            post 'set_released_to_students'
            post 'update_overall_comment'
            post 'toggle_marking_state'
            patch 'update_remark_request'
            get 'update_positions'
            post 'update_mark'
            get 'view_marks'
            post 'add_tag'
            post 'remove_tag'
            get 'run_tests'
            get 'stop_test'
            get 'get_test_runs_instructors'
            get 'get_test_runs_instructors_released'
          end
        end
      end

      resources :results, only: [:edit], path: '/peer_reviews' do
        collection do
          get 'download'
          post 'update_mark'
        end

        member do
          get 'view_marks'
          post 'add_extra_mark'
          get 'next_grouping'
          post 'toggle_marking_state'
          post 'update_mark'
          post 'update_overall_comment'
          patch 'update_remark_request'
        end
      end

      resources :peer_reviews, only: :index do
        collection do
          get 'populate'
          post 'assign_groups'
          get 'download_reviewer_reviewee_mapping'
          post 'csv_upload_handler'
          get 'show_reviews'
        end

        member do
          get 'show_result'
        end
      end

      resources :graders do
        collection do
          post 'csv_upload_grader_groups_mapping'
          post 'csv_upload_grader_criteria_mapping'
          get 'download_grader_groupings_mapping'
          get 'download_grader_criteria_mapping'
          get 'download_dialog'
          get 'download_grouplist'
          get 'global_actions'
          post 'set_assign_criteria'
          get 'upload_dialog'
          post 'global_actions'
          get 'grader_summary'
        end
      end

      resources :annotation_categories do
        member do
          delete 'delete_annotation_text'
          get 'add_annotation_text'
          post 'add_annotation_text'
          put 'update_annotation'
        end

        collection do
          post 'update_positions'
          post 'csv_upload'
          get 'download'
          post 'yml_upload'
          get 'add_annotation_text'
          post 'delete_annotation_text'
          post 'update_annotation'
          get 'find_annotation_text'
        end
      end
    end

    resources :grade_entry_forms do
      collection do
        get 'student_interface'
      end

      member do
        get 'populate_grades_table'
        get 'get_mark_columns'
        get 'view_summary'
        get 'grades'
        get 'csv_download'
        post 'csv_upload'
        post 'update_grade'
        post 'update_grade_entry_students'
        get 'student_interface'
      end

      resources :marks_graders, only: [:index] do
        collection do
          post 'csv_upload_grader_groups_mapping'
          get 'download_grader_students_mapping'
          post 'assign_all'
          post 'unassign_all'
          post 'unassign_single'
          post 'randomly_assign'
        end
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

    resources :key_pairs

    resources :course_summaries do
      collection do
        get 'populate'
        get 'get_marking_scheme_details'
        get 'download_csv_grades_report'
        get 'view_summary'
      end
    end

    resources :marking_schemes do
      collection do
        get 'populate'
      end
    end

    resources :sections

    resources :annotations do
      collection do
        post 'add_existing_annotation'
        patch 'update_annotation'
        delete '/' => 'annotations#destroy'
      end
    end

    resources :students do
      collection do
        patch 'bulk_modify'
        get 'manage'
        get 'add_new_section'
        get 'download_student_list'
        post 'upload_student_list'
      end

      member do
        post 'delete_grace_period_deduction'
      end
    end

    resources :tas  do
      collection do
        post 'upload_ta_list'
        get 'download_ta_list'
      end
      member do
        get 'refresh_graph'
      end
    end

    resources :main do
      collection do
        post 'logout'
        get 'about'
        post 'login_as'
        get 'role_switch'
        get 'clear_role_switch_session'
        post 'reset_api_key'
        get 'check_timeout'
        post 'refresh_session'
      end
    end
  end

  resources :automated_tests do
    member do
      get 'student_interface'
      post 'execute_test_run'
    end
  end

  resources :job_messages, only: %w(show), param: :job_id do
    member do
      get 'get'
    end
  end

  match 'main', controller: 'main', action: 'index', via: :post
  match 'main/about', controller: 'main', action: 'about', via: :post
  match 'main/logout', controller: 'main', action: 'logout', via: :post

  # Return a 404 when no route is match
  unless Rails.env.test?
    match '*path', controller: 'main', action: 'page_not_found', via: :all
  end
end
