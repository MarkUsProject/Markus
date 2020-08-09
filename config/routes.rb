Rails.application.routes.draw do
  # Install the default routes as the lowest priority.
  root controller: 'main', action: 'login', via: [:post, :get]

  # optional path scope (denoted by the parentheses)
  scope '(:locale)', locale: /en|es|fr|pt/  do
    # API routes
    namespace :api do
      resources :users, except: [:new, :edit] do
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
        resources :groups, except: [:new, :edit] do
          collection do
            get 'annotations'
            get 'group_ids_by_name'
          end
          resources :submission_files, except: [:new, :edit] do
            collection do
              delete 'remove_file'
              delete 'remove_folder'
              post 'create_folders'
            end
          end
          resources :feedback_files, except: [:new, :edit]
          resources :test_group_results, except: [:new, :edit] do
            resources :test_results, except: [:new, :edit]
          end
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
        resources :starter_file_groups do
          member do
            get 'entries'
            post 'create_file'
            post 'create_folder'
            delete 'remove_file'
            delete 'remove_folder'
            get 'download_entries'
          end
        end
        member do
          get 'test_files'
          get 'grades_summary'
          get 'test_specs'
          post 'update_test_specs'
        end
      end
      resources :main_api
    end

    resources :admins

    resources :assignments do

      collection do
        get 'delete_rejected'
        get 'download'
        post 'upload'
        get 'batch_runs'
      end

      member do
        get 'download_starter_file_mappings'
        get 'refresh_graph'
        get 'view_summary'
        post 'update_starter_file'
        get 'peer_review'
        get 'populate_starter_file_manager'
        get 'summary'
        get 'batch_runs'
        post 'set_boolean_graders_options'
        get 'stop_test'
        get 'stop_batch_tests'
        get 'switch_assignment'
        put 'start_timed_assignment'
        get 'starter_file'
        put 'update_starter_file'
      end

      resources :starter_file_groups do
        member do
          get 'download_file'
          get 'download_files'
          post 'update_files'
        end
      end

      resources :tags do
        collection do
          get 'download'
          post 'upload'
        end

        member do
          get 'edit_tag_dialog'
        end
      end

      resources :criteria do
        collection do
          post 'update_positions'
          post 'upload'
          get  'download'
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
          get 'populate_autotest_manager'
          get 'download_file'
          get 'download_files'
          post 'upload_files'
          get 'download_specs'
          post 'upload_specs'
        end
      end

      resources :exam_templates do
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

        collection do
          get 'view_logs'
        end
      end

      resources :groups do
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

        member do
          post 'rename_group'
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
          get 'server_time'
          get 'download'
          post 'zip_groupings_files'
          get 'download_zipped_file'
        end

        member do
          get 'collect_and_begin_grading'
          post 'manually_collect_and_begin_grading'
          get 'repo_browser'
          post 'repo_browser'
          get 'downloads'
          get 'get_file'
          get 'get_feedback_file'
        end

        resources :results do
          collection do
            get 'edit'
            get 'download'
          end

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
            post 'remove_extra_mark'
            patch 'revert_to_automatic_deductions'
            post 'set_released_to_students'
            post 'update_overall_comment'
            post 'toggle_marking_state'
            patch 'update_remark_request'
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
      end

      resources :results, only: [:edit], path: '/peer_reviews' do
        collection do
          get 'download'
        end

        member do
          get 'view_marks'
          get 'next_grouping'
          post 'toggle_marking_state'
          patch 'update_mark'
          post 'update_overall_comment'
          patch 'update_remark_request'
        end
      end

      resources :peer_reviews, only: :index do
        collection do
          get 'populate'
          post 'assign_groups'
          get 'peer_review_mapping'
          post 'upload'
          get 'list_reviews'
          get 'show_reviews'
        end

        member do
          get 'show_result'
        end
      end

      resources :graders do
        collection do
          post 'upload'
          get 'grader_groupings_mapping'
          get 'grader_criteria_mapping'
          get 'global_actions'
          post 'global_actions'
          get 'grader_summary'
        end
      end

      resources :annotation_categories do
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

    resources :grade_entry_forms do
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

    resources :notes do

      collection do
        post 'add_note'
        post 'noteable_object_selector'
        get 'new_update_groupings'
        post 'new_update_groupings'
        get 'notes_dialog'
      end

      member do
        get 'student_interface'
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
      end
    end

    resources :students do
      collection do
        patch 'bulk_modify'
        patch 'update_mailer_settings'
        get 'manage'
        get 'add_new_section'
        get 'download'
        post 'upload'
        get 'mailer_settings'
      end

      member do
        delete 'delete_grace_period_deduction'
      end
    end

    resources :tas  do
      collection do
        get 'download'
        post 'upload'
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

    resources :automated_tests do
      member do
        get 'student_interface'
        post 'execute_test_run'
      end
    end

    resources :extensions
  end

  resources :job_messages, param: :job_id do
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
