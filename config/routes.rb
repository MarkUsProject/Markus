# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Route Map
#
# Routes for application:
#                                                            Prefix Verb     URI Pattern                                                                                                   Controller#Action
#                                                              root POST|GET /                                                                                                             main#login
#                                      update_by_username_api_users PUT      /api/users/update_by_username(.:format)                                                                       api/users#update_by_username
#                                                         api_users GET      /api/users(.:format)                                                                                          api/users#index
#                                                                   POST     /api/users(.:format)                                                                                          api/users#create
#                                                          api_user GET      /api/users/:id(.:format)                                                                                      api/users#show
#                                                                   PATCH    /api/users/:id(.:format)                                                                                      api/users#update
#                                                                   PUT      /api/users/:id(.:format)                                                                                      api/users#update
#                                    update_autotest_url_api_course PUT      /api/courses/:id/update_autotest_url(.:format)                                                                api/courses#update_autotest_url
#                               test_autotest_connection_api_course GET      /api/courses/:id/test_autotest_connection(.:format)                                                           api/courses#test_autotest_connection
#                              reset_autotest_connection_api_course PUT      /api/courses/:id/reset_autotest_connection(.:format)                                                          api/courses#reset_autotest_connection
#                                                   api_course_tags GET      /api/courses/:course_id/tags(.:format)                                                                        api/tags#index
#                                                                   POST     /api/courses/:course_id/tags(.:format)                                                                        api/tags#create
#                                                    api_course_tag PATCH    /api/courses/:course_id/tags/:id(.:format)                                                                    api/tags#update
#                                                                   PUT      /api/courses/:course_id/tags/:id(.:format)                                                                    api/tags#update
#                                                                   DELETE   /api/courses/:course_id/tags/:id(.:format)                                                                    api/tags#destroy
#                                 create_or_unhide_api_course_roles POST     /api/courses/:course_id/roles/create_or_unhide(.:format)                                                      api/roles#create_or_unhide
#                               update_by_username_api_course_roles PUT      /api/courses/:course_id/roles/update_by_username(.:format)                                                    api/roles#update_by_username
#                                                  api_course_roles GET      /api/courses/:course_id/roles(.:format)                                                                       api/roles#index
#                                                                   POST     /api/courses/:course_id/roles(.:format)                                                                       api/roles#create
#                                                   api_course_role GET      /api/courses/:course_id/roles/:id(.:format)                                                                   api/roles#show
#                                                                   PATCH    /api/courses/:course_id/roles/:id(.:format)                                                                   api/roles#update
#                                                                   PUT      /api/courses/:course_id/roles/:id(.:format)                                                                   api/roles#update
#                         update_grades_api_course_grade_entry_form PUT      /api/courses/:course_id/grade_entry_forms/:id/update_grades(.:format)                                         api/grade_entry_forms#update_grades
#                                      api_course_grade_entry_forms GET      /api/courses/:course_id/grade_entry_forms(.:format)                                                           api/grade_entry_forms#index
#                                                                   POST     /api/courses/:course_id/grade_entry_forms(.:format)                                                           api/grade_entry_forms#create
#                                       api_course_grade_entry_form GET      /api/courses/:course_id/grade_entry_forms/:id(.:format)                                                       api/grade_entry_forms#show
#                                                                   PATCH    /api/courses/:course_id/grade_entry_forms/:id(.:format)                                                       api/grade_entry_forms#update
#                                                                   PUT      /api/courses/:course_id/grade_entry_forms/:id(.:format)                                                       api/grade_entry_forms#update
#                                                                   DELETE   /api/courses/:course_id/grade_entry_forms/:id(.:format)                                                       api/grade_entry_forms#destroy
#                          annotations_api_course_assignment_groups GET      /api/courses/:course_id/assignments/:assignment_id/groups/annotations(.:format)                               api/groups#annotations
#                    group_ids_by_name_api_course_assignment_groups GET      /api/courses/:course_id/assignments/:assignment_id/groups/group_ids_by_name(.:format)                         api/groups#group_ids_by_name
#                               add_tag_api_course_assignment_group PUT      /api/courses/:course_id/assignments/:assignment_id/groups/:id/add_tag(.:format)                               api/groups#add_tag
#                            remove_tag_api_course_assignment_group PUT      /api/courses/:course_id/assignments/:assignment_id/groups/:id/remove_tag(.:format)                            api/groups#remove_tag
#                    collect_submission_api_course_assignment_group POST     /api/courses/:course_id/assignments/:assignment_id/groups/:id/collect_submission(.:format)                    api/groups#collect_submission
#                          add_test_run_api_course_assignment_group POST     /api/courses/:course_id/assignments/:assignment_id/groups/:id/add_test_run(.:format)                          api/groups#add_test_run
#                          test_results_api_course_assignment_group GET      /api/courses/:course_id/assignments/:assignment_id/groups/:id/test_results(.:format)                          api/groups#test_results
#          remove_file_api_course_assignment_group_submission_files DELETE   /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/submission_files/remove_file(.:format)    api/submission_files#remove_file
#        remove_folder_api_course_assignment_group_submission_files DELETE   /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/submission_files/remove_folder(.:format)  api/submission_files#remove_folder
#       create_folders_api_course_assignment_group_submission_files POST     /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/submission_files/create_folders(.:format) api/submission_files#create_folders
#                      api_course_assignment_group_submission_files GET      /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/submission_files(.:format)                api/submission_files#index
#                                                                   POST     /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/submission_files(.:format)                api/submission_files#create
#                        api_course_assignment_group_feedback_files GET      /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/feedback_files(.:format)                  api/feedback_files#index
#                                                                   POST     /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/feedback_files(.:format)                  api/feedback_files#create
#                         api_course_assignment_group_feedback_file GET      /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/feedback_files/:id(.:format)              api/feedback_files#show
#                                                                   PATCH    /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/feedback_files/:id(.:format)              api/feedback_files#update
#                                                                   PUT      /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/feedback_files/:id(.:format)              api/feedback_files#update
#                                                                   DELETE   /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/feedback_files/:id(.:format)              api/feedback_files#destroy
#                           annotations_api_course_assignment_group GET      /api/courses/:course_id/assignments/:assignment_id/groups/:id/annotations(.:format)                           api/groups#annotations
#                       add_annotations_api_course_assignment_group POST     /api/courses/:course_id/assignments/:assignment_id/groups/:id/add_annotations(.:format)                       api/groups#add_annotations
#                           add_members_api_course_assignment_group POST     /api/courses/:course_id/assignments/:assignment_id/groups/:id/add_members(.:format)                           api/groups#add_members
#                    create_extra_marks_api_course_assignment_group POST     /api/courses/:course_id/assignments/:assignment_id/groups/:id/create_extra_marks(.:format)                    api/groups#create_extra_marks
#                          update_marks_api_course_assignment_group PUT      /api/courses/:course_id/assignments/:assignment_id/groups/:id/update_marks(.:format)                          api/groups#update_marks
#                  update_marking_state_api_course_assignment_group PUT      /api/courses/:course_id/assignments/:assignment_id/groups/:id/update_marking_state(.:format)                  api/groups#update_marking_state
#                    remove_extra_marks_api_course_assignment_group DELETE   /api/courses/:course_id/assignments/:assignment_id/groups/:id/remove_extra_marks(.:format)                    api/groups#remove_extra_marks
#                             extension_api_course_assignment_group POST     /api/courses/:course_id/assignments/:assignment_id/groups/:id/extension(.:format)                             api/groups#extension
#                                                                   PATCH    /api/courses/:course_id/assignments/:assignment_id/groups/:id/extension(.:format)                             api/groups#extension
#                                                                   DELETE   /api/courses/:course_id/assignments/:assignment_id/groups/:id/extension(.:format)                             api/groups#extension
#                                      api_course_assignment_groups GET      /api/courses/:course_id/assignments/:assignment_id/groups(.:format)                                           api/groups#index
#                                                                   POST     /api/courses/:course_id/assignments/:assignment_id/groups(.:format)                                           api/groups#create
#                                       api_course_assignment_group GET      /api/courses/:course_id/assignments/:assignment_id/groups/:id(.:format)                                       api/groups#show
#                                                                   PATCH    /api/courses/:course_id/assignments/:assignment_id/groups/:id(.:format)                                       api/groups#update
#                                                                   PUT      /api/courses/:course_id/assignments/:assignment_id/groups/:id(.:format)                                       api/groups#update
#                         api_course_assignment_starter_file_groups GET      /api/courses/:course_id/assignments/:assignment_id/starter_file_groups(.:format)                              api/starter_file_groups#index
#                                                                   POST     /api/courses/:course_id/assignments/:assignment_id/starter_file_groups(.:format)                              api/starter_file_groups#create
#                                  test_files_api_course_assignment GET      /api/courses/:course_id/assignments/:id/test_files(.:format)                                                  api/assignments#test_files
#                              grades_summary_api_course_assignment GET      /api/courses/:course_id/assignments/:id/grades_summary(.:format)                                              api/assignments#grades_summary
#                                  test_specs_api_course_assignment GET      /api/courses/:course_id/assignments/:id/test_specs(.:format)                                                  api/assignments#test_specs
#                           update_test_specs_api_course_assignment POST     /api/courses/:course_id/assignments/:id/update_test_specs(.:format)                                           api/assignments#update_test_specs
#                                 submit_file_api_course_assignment POST     /api/courses/:course_id/assignments/:id/submit_file(.:format)                                                 api/assignments#submit_file
#                                            api_course_assignments GET      /api/courses/:course_id/assignments(.:format)                                                                 api/assignments#index
#                                                                   POST     /api/courses/:course_id/assignments(.:format)                                                                 api/assignments#create
#                                             api_course_assignment GET      /api/courses/:course_id/assignments/:id(.:format)                                                             api/assignments#show
#                                                                   PATCH    /api/courses/:course_id/assignments/:id(.:format)                                                             api/assignments#update
#                                                                   PUT      /api/courses/:course_id/assignments/:id(.:format)                                                             api/assignments#update
#                                                                   DELETE   /api/courses/:course_id/assignments/:id(.:format)                                                             api/assignments#destroy
#                                          api_course_feedback_file GET      /api/courses/:course_id/feedback_files/:id(.:format)                                                          api/feedback_files#show
#                                                                   PATCH    /api/courses/:course_id/feedback_files/:id(.:format)                                                          api/feedback_files#update
#                                                                   PUT      /api/courses/:course_id/feedback_files/:id(.:format)                                                          api/feedback_files#update
#                                                                   DELETE   /api/courses/:course_id/feedback_files/:id(.:format)                                                          api/feedback_files#destroy
#                                        api_course_submission_file PATCH    /api/courses/:course_id/submission_files/:id(.:format)                                                        api/submission_files#update
#                                                                   PUT      /api/courses/:course_id/submission_files/:id(.:format)                                                        api/submission_files#update
#                                                                   DELETE   /api/courses/:course_id/submission_files/:id(.:format)                                                        api/submission_files#destroy
#                             entries_api_course_starter_file_group GET      /api/courses/:course_id/starter_file_groups/:id/entries(.:format)                                             api/starter_file_groups#entries
#                         create_file_api_course_starter_file_group POST     /api/courses/:course_id/starter_file_groups/:id/create_file(.:format)                                         api/starter_file_groups#create_file
#                       create_folder_api_course_starter_file_group POST     /api/courses/:course_id/starter_file_groups/:id/create_folder(.:format)                                       api/starter_file_groups#create_folder
#                         remove_file_api_course_starter_file_group DELETE   /api/courses/:course_id/starter_file_groups/:id/remove_file(.:format)                                         api/starter_file_groups#remove_file
#                       remove_folder_api_course_starter_file_group DELETE   /api/courses/:course_id/starter_file_groups/:id/remove_folder(.:format)                                       api/starter_file_groups#remove_folder
#                    download_entries_api_course_starter_file_group GET      /api/courses/:course_id/starter_file_groups/:id/download_entries(.:format)                                    api/starter_file_groups#download_entries
#                                     api_course_starter_file_group GET      /api/courses/:course_id/starter_file_groups/:id(.:format)                                                     api/starter_file_groups#show
#                                                                   PATCH    /api/courses/:course_id/starter_file_groups/:id(.:format)                                                     api/starter_file_groups#update
#                                                                   PUT      /api/courses/:course_id/starter_file_groups/:id(.:format)                                                     api/starter_file_groups#update
#                                                                   DELETE   /api/courses/:course_id/starter_file_groups/:id(.:format)                                                     api/starter_file_groups#destroy
#                                               api_course_sections GET      /api/courses/:course_id/sections(.:format)                                                                    api/sections#index
#                                                                   POST     /api/courses/:course_id/sections(.:format)                                                                    api/sections#create
#                                                api_course_section GET      /api/courses/:course_id/sections/:id(.:format)                                                                api/sections#show
#                                                                   PATCH    /api/courses/:course_id/sections/:id(.:format)                                                                api/sections#update
#                                                                   PUT      /api/courses/:course_id/sections/:id(.:format)                                                                api/sections#update
#                                                                   DELETE   /api/courses/:course_id/sections/:id(.:format)                                                                api/sections#destroy
#                                                       api_courses GET      /api/courses(.:format)                                                                                        api/courses#index
#                                                                   POST     /api/courses(.:format)                                                                                        api/courses#create
#                                                        api_course GET      /api/courses/:id(.:format)                                                                                    api/courses#show
#                                                                   PATCH    /api/courses/:id(.:format)                                                                                    api/courses#update
#                                                                   PUT      /api/courses/:id(.:format)                                                                                    api/courses#update
#                                                               api          /api/*path(.:format)                                                                                          api/main_api#page_not_found
#                                                upload_admin_users POST     /admin/users/upload(.:format)                                                                                 admin/users#upload
#                                                       admin_users GET      /admin/users(.:format)                                                                                        admin/users#index
#                                                                   POST     /admin/users(.:format)                                                                                        admin/users#create
#                                                    new_admin_user GET      /admin/users/new(.:format)                                                                                    admin/users#new
#                                                   edit_admin_user GET      /admin/users/:id/edit(.:format)                                                                               admin/users#edit
#                                                        admin_user PATCH    /admin/users/:id(.:format)                                                                                    admin/users#update
#                                                                   PUT      /admin/users/:id(.:format)                                                                                    admin/users#update
#                             test_autotest_connection_admin_course GET      /admin/courses/:id/test_autotest_connection(.:format)                                                         admin/courses#test_autotest_connection
#                            reset_autotest_connection_admin_course PUT      /admin/courses/:id/reset_autotest_connection(.:format)                                                        admin/courses#reset_autotest_connection
#                              refresh_autotest_schema_admin_course POST     /admin/courses/:id/refresh_autotest_schema(.:format)                                                          admin/courses#refresh_autotest_schema
#                               destroy_lti_deployment_admin_course DELETE   /admin/courses/:id/destroy_lti_deployment(.:format)                                                           admin/courses#destroy_lti_deployment
#                                                     admin_courses GET      /admin/courses(.:format)                                                                                      admin/courses#index
#                                                                   POST     /admin/courses(.:format)                                                                                      admin/courses#create
#                                                  new_admin_course GET      /admin/courses/new(.:format)                                                                                  admin/courses#new
#                                                 edit_admin_course GET      /admin/courses/:id/edit(.:format)                                                                             admin/courses#edit
#                                                      admin_course PATCH    /admin/courses/:id(.:format)                                                                                  admin/courses#update
#                                                                   PUT      /admin/courses/:id(.:format)                                                                                  admin/courses#update
#                                                             admin GET      /admin(.:format)                                                                                              admin/main_admin#index
#                                                      admin_resque          /admin/resque                                                                                                 #<Resque::Server app_file="/bundle/gems/resque-2.7.0/lib/resque/server.rb">
#                                                 admin_performance          /admin/rails/performance                                                                                      RailsPerformance::Engine
#                                                      admin_pghero          /admin/rails/pghero                                                                                           PgHero::Engine
#                                  clear_role_switch_session_course GET      /courses/:id/clear_role_switch_session(.:format)                                                              courses#clear_role_switch_session
#                                                role_switch_course GET      /courses/:id/role_switch(.:format)                                                                            courses#role_switch
#                                                switch_role_course POST     /courses/:id/switch_role(.:format)                                                                            courses#switch_role
#                                       download_assignments_course GET      /courses/:id/download_assignments(.:format)                                                                   courses#download_assignments
#                                         upload_assignments_course POST     /courses/:id/upload_assignments(.:format)                                                                     courses#upload_assignments
#                                     destroy_lti_deployment_course DELETE   /courses/:id/destroy_lti_deployment(.:format)                                                                 courses#destroy_lti_deployment
#                                                sync_roster_course POST     /courses/:id/sync_roster(.:format)                                                                            courses#sync_roster
#                                            lti_deployments_course GET      /courses/:id/lti_deployments(.:format)                                                                        courses#lti_deployments
#                                               lti_settings_course GET      /courses/:id/lti_settings(.:format)                                                                           courses#lti_settings
#                                                course_instructors GET      /courses/:course_id/instructors(.:format)                                                                     instructors#index
#                                                                   POST     /courses/:course_id/instructors(.:format)                                                                     instructors#create
#                                             new_course_instructor GET      /courses/:course_id/instructors/new(.:format)                                                                 instructors#new
#                                            edit_course_instructor GET      /courses/:course_id/instructors/:id/edit(.:format)                                                            instructors#edit
#                                                 course_instructor PATCH    /courses/:course_id/instructors/:id(.:format)                                                                 instructors#update
#                                                                   PUT      /courses/:course_id/instructors/:id(.:format)                                                                 instructors#update
#                                                                   DELETE   /courses/:course_id/instructors/:id(.:format)                                                                 instructors#destroy
#                           download_file_course_starter_file_group GET      /courses/:course_id/starter_file_groups/:id/download_file(.:format)                                           starter_file_groups#download_file
#                          download_files_course_starter_file_group GET      /courses/:course_id/starter_file_groups/:id/download_files(.:format)                                          starter_file_groups#download_files
#                            update_files_course_starter_file_group POST     /courses/:course_id/starter_file_groups/:id/update_files(.:format)                                            starter_file_groups#update_files
#                                         course_starter_file_group PATCH    /courses/:course_id/starter_file_groups/:id(.:format)                                                         starter_file_groups#update
#                                                                   PUT      /courses/:course_id/starter_file_groups/:id(.:format)                                                         starter_file_groups#update
#                                                                   DELETE   /courses/:course_id/starter_file_groups/:id(.:format)                                                         starter_file_groups#destroy
#                                        edit_tag_dialog_course_tag GET      /courses/:course_id/tags/:id/edit_tag_dialog(.:format)                                                        tags#edit_tag_dialog
#                                              download_course_tags GET      /courses/:course_id/tags/download(.:format)                                                                   tags#download
#                                                upload_course_tags POST     /courses/:course_id/tags/upload(.:format)                                                                     tags#upload
#                                                       course_tags GET      /courses/:course_id/tags(.:format)                                                                            tags#index
#                                                                   POST     /courses/:course_id/tags(.:format)                                                                            tags#create
#                                                   edit_course_tag GET      /courses/:course_id/tags/:id/edit(.:format)                                                                   tags#edit
#                                                        course_tag PATCH    /courses/:course_id/tags/:id(.:format)                                                                        tags#update
#                                                                   PUT      /courses/:course_id/tags/:id(.:format)                                                                        tags#update
#                                                                   DELETE   /courses/:course_id/tags/:id(.:format)                                                                        tags#destroy
#                                             edit_course_criterion GET      /courses/:course_id/criteria/:id/edit(.:format)                                                               criteria#edit
#                                                  course_criterion PATCH    /courses/:course_id/criteria/:id(.:format)                                                                    criteria#update
#                                                                   PUT      /courses/:course_id/criteria/:id(.:format)                                                                    criteria#update
#                                                                   DELETE   /courses/:course_id/criteria/:id(.:format)                                                                    criteria#destroy
#                                     download_course_exam_template GET      /courses/:course_id/exam_templates/:id/download(.:format)                                                     exam_templates#download
#                            download_generate_course_exam_template GET      /courses/:course_id/exam_templates/:id/download_generate(.:format)                                            exam_templates#download_generate
#                                   show_cover_course_exam_template GET      /courses/:course_id/exam_templates/:id/show_cover(.:format)                                                   exam_templates#show_cover
#                                assign_errors_course_exam_template GET      /courses/:course_id/exam_templates/:id/assign_errors(.:format)                                                exam_templates#assign_errors
#                      download_raw_split_file_course_exam_template GET      /courses/:course_id/exam_templates/:id/download_raw_split_file(.:format)                                      exam_templates#download_raw_split_file
#                          download_error_file_course_exam_template GET      /courses/:course_id/exam_templates/:id/download_error_file(.:format)                                          exam_templates#download_error_file
#                                  error_pages_course_exam_template GET      /courses/:course_id/exam_templates/:id/error_pages(.:format)                                                  exam_templates#error_pages
#                                   add_fields_course_exam_template PATCH    /courses/:course_id/exam_templates/:id/add_fields(.:format)                                                   exam_templates#add_fields
#                                     generate_course_exam_template PATCH    /courses/:course_id/exam_templates/:id/generate(.:format)                                                     exam_templates#generate
#                                    fix_error_course_exam_template POST     /courses/:course_id/exam_templates/:id/fix_error(.:format)                                                    exam_templates#fix_error
#                                         edit_course_exam_template GET      /courses/:course_id/exam_templates/:id/edit(.:format)                                                         exam_templates#edit
#                                              course_exam_template PATCH    /courses/:course_id/exam_templates/:id(.:format)                                                              exam_templates#update
#                                                                   PUT      /courses/:course_id/exam_templates/:id(.:format)                                                              exam_templates#update
#                                                                   DELETE   /courses/:course_id/exam_templates/:id(.:format)                                                              exam_templates#destroy
#                                         rename_group_course_group POST     /courses/:course_id/groups/:id/rename_group(.:format)                                                         groups#rename_group
#                       collect_and_begin_grading_course_submission GET      /courses/:course_id/submissions/:id/collect_and_begin_grading(.:format)                                       submissions#collect_and_begin_grading
#                                     get_annotations_course_result GET      /courses/:course_id/results/:id/get_annotations(.:format)                                                     results#get_annotations
#                                     add_extra_marks_course_result GET      /courses/:course_id/results/:id/add_extra_marks(.:format)                                                     results#add_extra_marks
#                                            download_course_result POST     /courses/:course_id/results/:id/download(.:format)                                                            results#download
#                                      add_extra_mark_course_result POST     /courses/:course_id/results/:id/add_extra_mark(.:format)                                                      results#add_extra_mark
#                       delete_grace_period_deduction_course_result DELETE   /courses/:course_id/results/:id/delete_grace_period_deduction(.:format)                                       results#delete_grace_period_deduction
#                                       next_grouping_course_result GET      /courses/:course_id/results/:id/next_grouping(.:format)                                                       results#next_grouping
#                           get_filtered_grouping_ids_course_result GET      /courses/:course_id/results/:id/get_filtered_grouping_ids(.:format)                                           results#get_filtered_grouping_ids
#                                               print_course_result GET      /courses/:course_id/results/:id/print(.:format)                                                               results#print
#                                   remove_extra_mark_course_result DELETE   /courses/:course_id/results/:id/remove_extra_mark(.:format)                                                   results#remove_extra_mark
#                      revert_to_automatic_deductions_course_result PATCH    /courses/:course_id/results/:id/revert_to_automatic_deductions(.:format)                                      results#revert_to_automatic_deductions
#                            set_released_to_students_course_result POST     /courses/:course_id/results/:id/set_released_to_students(.:format)                                            results#set_released_to_students
#                              update_overall_comment_course_result POST     /courses/:course_id/results/:id/update_overall_comment(.:format)                                              results#update_overall_comment
#                                toggle_marking_state_course_result POST     /courses/:course_id/results/:id/toggle_marking_state(.:format)                                                results#toggle_marking_state
#                                    update_positions_course_result GET      /courses/:course_id/results/:id/update_positions(.:format)                                                    results#update_positions
#                                         update_mark_course_result PATCH    /courses/:course_id/results/:id/update_mark(.:format)                                                         results#update_mark
#                                          view_marks_course_result GET      /courses/:course_id/results/:id/view_marks(.:format)                                                          results#view_marks
#                                             add_tag_course_result POST     /courses/:course_id/results/:id/add_tag(.:format)                                                             results#add_tag
#                        random_incomplete_submission_course_result GET      /courses/:course_id/results/:id/random_incomplete_submission(.:format)                                        results#random_incomplete_submission
#                                          remove_tag_course_result POST     /courses/:course_id/results/:id/remove_tag(.:format)                                                          results#remove_tag
#                                           run_tests_course_result POST     /courses/:course_id/results/:id/run_tests(.:format)                                                           results#run_tests
#                                           stop_test_course_result GET      /courses/:course_id/results/:id/stop_test(.:format)                                                           results#stop_test
#                           get_test_runs_instructors_course_result GET      /courses/:course_id/results/:id/get_test_runs_instructors(.:format)                                           results#get_test_runs_instructors
#                  get_test_runs_instructors_released_course_result GET      /courses/:course_id/results/:id/get_test_runs_instructors_released(.:format)                                  results#get_test_runs_instructors_released
#                                    view_token_check_course_result GET      /courses/:course_id/results/:id/view_token_check(.:format)                                                    results#view_token_check
#                                                edit_course_result GET      /courses/:course_id/results/:id/edit(.:format)                                                                results#edit
#                                                     course_result GET      /courses/:course_id/results/:id(.:format)                                                                     results#show
#                                    show_result_course_peer_review GET      /courses/:course_id/peer_reviews/:id/show_result(.:format)                                                    peer_reviews#show_result
#                                        course_annotation_category GET      /courses/:course_id/annotation_categories/:id(.:format)                                                       annotation_categories#show
#                                                                   PATCH    /courses/:course_id/annotation_categories/:id(.:format)                                                       annotation_categories#update
#                                                                   PUT      /courses/:course_id/annotation_categories/:id(.:format)                                                       annotation_categories#update
#                                                                   DELETE   /courses/:course_id/annotation_categories/:id(.:format)                                                       annotation_categories#destroy
#                                delete_rejected_course_assignments GET      /courses/:course_id/assignments/delete_rejected(.:format)                                                     assignments#delete_rejected
#                                     batch_runs_course_assignments GET      /courses/:course_id/assignments/batch_runs(.:format)                                                          assignments#batch_runs
#                            upload_config_files_course_assignments POST     /courses/:course_id/assignments/upload_config_files(.:format)                                                 assignments#upload_config_files
#                   download_sample_starter_files_course_assignment GET      /courses/:course_id/assignments/:id/download_sample_starter_files(.:format)                                   assignments#download_sample_starter_files
#                  download_starter_file_mappings_course_assignment GET      /courses/:course_id/assignments/:id/download_starter_file_mappings(.:format)                                  assignments#download_starter_file_mappings
#                                    view_summary_course_assignment GET      /courses/:course_id/assignments/:id/view_summary(.:format)                                                    assignments#view_summary
#                             update_starter_file_course_assignment POST     /courses/:course_id/assignments/:id/update_starter_file(.:format)                                             assignments#update_starter_file
#                                     peer_review_course_assignment GET      /courses/:course_id/assignments/:id/peer_review(.:format)                                                     assignments#peer_review
#                   populate_starter_file_manager_course_assignment GET      /courses/:course_id/assignments/:id/populate_starter_file_manager(.:format)                                   assignments#populate_starter_file_manager
#                                         summary_course_assignment GET      /courses/:course_id/assignments/:id/summary(.:format)                                                         assignments#summary
#                                      batch_runs_course_assignment GET      /courses/:course_id/assignments/:id/batch_runs(.:format)                                                      assignments#batch_runs
#                     set_boolean_graders_options_course_assignment POST     /courses/:course_id/assignments/:id/set_boolean_graders_options(.:format)                                     assignments#set_boolean_graders_options
#                                       stop_test_course_assignment GET      /courses/:course_id/assignments/:id/stop_test(.:format)                                                       assignments#stop_test
#                                stop_batch_tests_course_assignment GET      /courses/:course_id/assignments/:id/stop_batch_tests(.:format)                                                assignments#stop_batch_tests
#                                          switch_course_assignment GET      /courses/:course_id/assignments/:id/switch(.:format)                                                          assignments#switch
#                          start_timed_assignment_course_assignment PUT      /courses/:course_id/assignments/:id/start_timed_assignment(.:format)                                          assignments#start_timed_assignment
#                                    starter_file_course_assignment GET      /courses/:course_id/assignments/:id/starter_file(.:format)                                                    assignments#starter_file
#                                                                   PUT      /courses/:course_id/assignments/:id/update_starter_file(.:format)                                             assignments#update_starter_file
#                              grade_distribution_course_assignment GET      /courses/:course_id/assignments/:id/grade_distribution(.:format)                                              assignments#grade_distribution
#                           download_config_files_course_assignment GET      /courses/:course_id/assignments/:id/download_config_files(.:format)                                           assignments#download_config_files
#                           download_test_results_course_assignment GET      /courses/:course_id/assignments/:id/download_test_results(.:format)                                           assignments#download_test_results
#                                    lti_settings_course_assignment GET      /courses/:course_id/assignments/:id/lti_settings(.:format)                                                    assignments#lti_settings
#                               create_lti_grades_course_assignment POST     /courses/:course_id/assignments/:id/create_lti_grades(.:format)                                               assignments#create_lti_grades
#                           create_lti_line_items_course_assignment POST     /courses/:course_id/assignments/:id/create_lti_line_items(.:format)                                           assignments#create_lti_line_items
#                             course_assignment_starter_file_groups POST     /courses/:course_id/assignments/:assignment_id/starter_file_groups(.:format)                                  starter_file_groups#create
#                       update_positions_course_assignment_criteria POST     /courses/:course_id/assignments/:assignment_id/criteria/update_positions(.:format)                            criteria#update_positions
#                                 upload_course_assignment_criteria POST     /courses/:course_id/assignments/:assignment_id/criteria/upload(.:format)                                      criteria#upload
#                               download_course_assignment_criteria GET      /courses/:course_id/assignments/:assignment_id/criteria/download(.:format)                                    criteria#download
#                                        course_assignment_criteria GET      /courses/:course_id/assignments/:assignment_id/criteria(.:format)                                             criteria#index
#                                                                   POST     /courses/:course_id/assignments/:assignment_id/criteria(.:format)                                             criteria#create
#                                   new_course_assignment_criterion GET      /courses/:course_id/assignments/:assignment_id/criteria/new(.:format)                                         criteria#new
#                          manage_course_assignment_automated_tests GET      /courses/:course_id/assignments/:assignment_id/automated_tests/manage(.:format)                               automated_tests#manage
#                                 course_assignment_automated_tests POST     /courses/:course_id/assignments/:assignment_id/automated_tests/update(.:format)                               automated_tests#update
#                update_positions_course_assignment_automated_tests POST     /courses/:course_id/assignments/:assignment_id/automated_tests/update_positions(.:format)                     automated_tests#update_positions
#                                                                   GET      /courses/:course_id/assignments/:assignment_id/automated_tests/update_positions(.:format)                     automated_tests#update_positions
#                          upload_course_assignment_automated_tests POST     /courses/:course_id/assignments/:assignment_id/automated_tests/upload(.:format)                               automated_tests#upload
#                        download_course_assignment_automated_tests GET      /courses/:course_id/assignments/:assignment_id/automated_tests/download(.:format)                             automated_tests#download
#          get_test_runs_students_course_assignment_automated_tests GET      /courses/:course_id/assignments/:assignment_id/automated_tests/get_test_runs_students(.:format)               automated_tests#get_test_runs_students
#       populate_autotest_manager_course_assignment_automated_tests GET      /courses/:course_id/assignments/:assignment_id/automated_tests/populate_autotest_manager(.:format)            automated_tests#populate_autotest_manager
#                   download_file_course_assignment_automated_tests GET      /courses/:course_id/assignments/:assignment_id/automated_tests/download_file(.:format)                        automated_tests#download_file
#                  download_files_course_assignment_automated_tests GET      /courses/:course_id/assignments/:assignment_id/automated_tests/download_files(.:format)                       automated_tests#download_files
#                    upload_files_course_assignment_automated_tests POST     /courses/:course_id/assignments/:assignment_id/automated_tests/upload_files(.:format)                         automated_tests#upload_files
#                  download_specs_course_assignment_automated_tests GET      /courses/:course_id/assignments/:assignment_id/automated_tests/download_specs(.:format)                       automated_tests#download_specs
#                    upload_specs_course_assignment_automated_tests POST     /courses/:course_id/assignments/:assignment_id/automated_tests/upload_specs(.:format)                         automated_tests#upload_specs
#               student_interface_course_assignment_automated_tests GET      /courses/:course_id/assignments/:assignment_id/automated_tests/student_interface(.:format)                    automated_tests#student_interface
#                execute_test_run_course_assignment_automated_tests POST     /courses/:course_id/assignments/:assignment_id/automated_tests/execute_test_run(.:format)                     automated_tests#execute_test_run
#                        view_logs_course_assignment_exam_templates GET      /courses/:course_id/assignments/:assignment_id/exam_templates/view_logs(.:format)                             exam_templates#view_logs
#                            split_course_assignment_exam_templates PATCH    /courses/:course_id/assignments/:assignment_id/exam_templates/split(.:format)                                 exam_templates#split
#                                  course_assignment_exam_templates GET      /courses/:course_id/assignments/:assignment_id/exam_templates(.:format)                                       exam_templates#index
#                                                                   POST     /courses/:course_id/assignments/:assignment_id/exam_templates(.:format)                                       exam_templates#create
#                                add_group_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/add_group(.:format)                                     groups#add_group
#            use_another_assignment_groups_course_assignment_groups POST     /courses/:course_id/assignments/:assignment_id/groups/use_another_assignment_groups(.:format)                 groups#use_another_assignment_groups
#                                   manage_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/manage(.:format)                                        groups#manage
#                             assign_scans_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/assign_scans(.:format)                                  groups#assign_scans
#                                 download_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/download(.:format)                                      groups#download
#                    download_starter_file_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/download_starter_file(.:format)                         groups#download_starter_file
#         populate_repo_with_starter_files_course_assignment_groups PATCH    /courses/:course_id/assignments/:assignment_id/groups/populate_repo_with_starter_files(.:format)              groups#populate_repo_with_starter_files
#                                get_names_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/get_names(.:format)                                     groups#get_names
#                  assign_student_and_next_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/assign_student_and_next(.:format)                       groups#assign_student_and_next
#                            next_grouping_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/next_grouping(.:format)                                 groups#next_grouping
#                                   upload_course_assignment_groups POST     /courses/:course_id/assignments/:assignment_id/groups/upload(.:format)                                        groups#upload
#                            add_csv_group_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/add_csv_group(.:format)                                 groups#add_csv_group
#                       download_grouplist_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/download_grouplist(.:format)                            groups#download_grouplist
#   create_groups_when_students_work_alone_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/create_groups_when_students_work_alone(.:format)        groups#create_groups_when_students_work_alone
#                           valid_grouping_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/valid_grouping(.:format)                                groups#valid_grouping
#                         invalid_grouping_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/invalid_grouping(.:format)                              groups#invalid_grouping
#                           global_actions_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/global_actions(.:format)                                groups#global_actions
#                             rename_group_course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups/rename_group(.:format)                                  groups#rename_group
#                             remove_group_course_assignment_groups DELETE   /courses/:course_id/assignments/:assignment_id/groups/remove_group(.:format)                                  groups#remove_group
#                                                                   POST     /courses/:course_id/assignments/:assignment_id/groups/add_group(.:format)                                     groups#add_group
#                                                                   POST     /courses/:course_id/assignments/:assignment_id/groups/global_actions(.:format)                                groups#global_actions
#                        accept_invitation_course_assignment_groups PATCH    /courses/:course_id/assignments/:assignment_id/groups/accept_invitation(.:format)                             groups#accept_invitation
#                       decline_invitation_course_assignment_groups PATCH    /courses/:course_id/assignments/:assignment_id/groups/decline_invitation(.:format)                            groups#decline_invitation
#                          delete_rejected_course_assignment_groups DELETE   /courses/:course_id/assignments/:assignment_id/groups/delete_rejected(.:format)                               groups#delete_rejected
#                            invite_member_course_assignment_groups POST     /courses/:course_id/assignments/:assignment_id/groups/invite_member(.:format)                                 groups#invite_member
#                         disinvite_member_course_assignment_groups PATCH    /courses/:course_id/assignments/:assignment_id/groups/disinvite_member(.:format)                              groups#disinvite_member
#                               auto_match_course_assignment_groups POST     /courses/:course_id/assignments/:assignment_id/groups/auto_match(.:format)                                    groups#auto_match
#                                          course_assignment_groups GET      /courses/:course_id/assignments/:assignment_id/groups(.:format)                                               groups#index
#                                                                   POST     /courses/:course_id/assignments/:assignment_id/groups(.:format)                                               groups#create
#                                       new_course_assignment_group GET      /courses/:course_id/assignments/:assignment_id/groups/new(.:format)                                           groups#new
#                                           course_assignment_group DELETE   /courses/:course_id/assignments/:assignment_id/groups/:id(.:format)                                           groups#destroy
#                        file_manager_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/file_manager(.:format)                             submissions#file_manager
#                              browse_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/browse(.:format)                                   submissions#browse
#               populate_file_manager_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/populate_file_manager(.:format)                    submissions#populate_file_manager
#                           revisions_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/revisions(.:format)                                submissions#revisions
#                 collect_submissions_course_assignment_submissions POST     /courses/:course_id/assignments/:assignment_id/submissions/collect_submissions(.:format)                      submissions#collect_submissions
#           uncollect_all_submissions_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/uncollect_all_submissions(.:format)                submissions#uncollect_all_submissions
#                           run_tests_course_assignment_submissions POST     /courses/:course_id/assignments/:assignment_id/submissions/run_tests(.:format)                                submissions#run_tests
#     download_repo_checkout_commands_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/download_repo_checkout_commands(.:format)          submissions#download_repo_checkout_commands
#                  download_repo_list_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/download_repo_list(.:format)                       submissions#download_repo_list
#            set_result_marking_state_course_assignment_submissions POST     /courses/:course_id/assignments/:assignment_id/submissions/set_result_marking_state(.:format)                 submissions#set_result_marking_state
#                  update_submissions_course_assignment_submissions POST     /courses/:course_id/assignments/:assignment_id/submissions/update_submissions(.:format)                       submissions#update_submissions
#                       updated_files_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/updated_files(.:format)                            submissions#updated_files
#                       replace_files_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/replace_files(.:format)                            submissions#replace_files
#                        delete_files_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/delete_files(.:format)                             submissions#delete_files
#                        update_files_course_assignment_submissions POST     /courses/:course_id/assignments/:assignment_id/submissions/update_files(.:format)                             submissions#update_files
#                            download_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/download(.:format)                                 submissions#download
#                 zip_groupings_files_course_assignment_submissions POST     /courses/:course_id/assignments/:assignment_id/submissions/zip_groupings_files(.:format)                      submissions#zip_groupings_files
#                download_zipped_file_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/download_zipped_file(.:format)                     submissions#download_zipped_file
#                    download_summary_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/download_summary(.:format)                         submissions#download_summary
#                        repo_browser_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/repo_browser(.:format)                             submissions#repo_browser
#                                                                   POST     /courses/:course_id/assignments/:assignment_id/submissions/repo_browser(.:format)                             submissions#repo_browser
#  manually_collect_and_begin_grading_course_assignment_submissions POST     /courses/:course_id/assignments/:assignment_id/submissions/manually_collect_and_begin_grading(.:format)       submissions#manually_collect_and_begin_grading
#                           downloads_course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions/downloads(.:format)                                submissions#downloads
#                        download_file_course_assignment_submission GET      /courses/:course_id/assignments/:assignment_id/submissions/:id/download_file(.:format)                        submissions#download_file
#                    download_file_zip_course_assignment_submission GET      /courses/:course_id/assignments/:assignment_id/submissions/:id/download_file_zip(.:format)                    submissions#download_file_zip
#                cancel_remark_request_course_assignment_submission DELETE   /courses/:course_id/assignments/:assignment_id/submissions/:id/cancel_remark_request(.:format)                submissions#cancel_remark_request
#                update_remark_request_course_assignment_submission PATCH    /courses/:course_id/assignments/:assignment_id/submissions/:id/update_remark_request(.:format)                submissions#update_remark_request
#                                     course_assignment_submissions GET      /courses/:course_id/assignments/:assignment_id/submissions(.:format)                                          submissions#index
#                           populate_course_assignment_peer_reviews GET      /courses/:course_id/assignments/:assignment_id/peer_reviews/populate(.:format)                                peer_reviews#populate
#                      assign_groups_course_assignment_peer_reviews POST     /courses/:course_id/assignments/:assignment_id/peer_reviews/assign_groups(.:format)                           peer_reviews#assign_groups
#                peer_review_mapping_course_assignment_peer_reviews GET      /courses/:course_id/assignments/:assignment_id/peer_reviews/peer_review_mapping(.:format)                     peer_reviews#peer_review_mapping
#                             upload_course_assignment_peer_reviews POST     /courses/:course_id/assignments/:assignment_id/peer_reviews/upload(.:format)                                  peer_reviews#upload
#                       list_reviews_course_assignment_peer_reviews GET      /courses/:course_id/assignments/:assignment_id/peer_reviews/list_reviews(.:format)                            peer_reviews#list_reviews
#                       show_reviews_course_assignment_peer_reviews GET      /courses/:course_id/assignments/:assignment_id/peer_reviews/show_reviews(.:format)                            peer_reviews#show_reviews
#                     populate_table_course_assignment_peer_reviews GET      /courses/:course_id/assignments/:assignment_id/peer_reviews/populate_table(.:format)                          peer_reviews#populate_table
#                                    course_assignment_peer_reviews GET      /courses/:course_id/assignments/:assignment_id/peer_reviews(.:format)                                         peer_reviews#index
#                                  upload_course_assignment_graders POST     /courses/:course_id/assignments/:assignment_id/graders/upload(.:format)                                       graders#upload
#                grader_groupings_mapping_course_assignment_graders GET      /courses/:course_id/assignments/:assignment_id/graders/grader_groupings_mapping(.:format)                     graders#grader_groupings_mapping
#                 grader_criteria_mapping_course_assignment_graders GET      /courses/:course_id/assignments/:assignment_id/graders/grader_criteria_mapping(.:format)                      graders#grader_criteria_mapping
#                          global_actions_course_assignment_graders GET      /courses/:course_id/assignments/:assignment_id/graders/global_actions(.:format)                               graders#global_actions
#                                                                   POST     /courses/:course_id/assignments/:assignment_id/graders/global_actions(.:format)                               graders#global_actions
#                          grader_summary_course_assignment_graders GET      /courses/:course_id/assignments/:assignment_id/graders/grader_summary(.:format)                               graders#grader_summary
#                                         course_assignment_graders GET      /courses/:course_id/assignments/:assignment_id/graders(.:format)                                              graders#index
#          update_positions_course_assignment_annotation_categories POST     /courses/:course_id/assignments/:assignment_id/annotation_categories/update_positions(.:format)               annotation_categories#update_positions
#                    upload_course_assignment_annotation_categories POST     /courses/:course_id/assignments/:assignment_id/annotation_categories/upload(.:format)                         annotation_categories#upload
#                  download_course_assignment_annotation_categories GET      /courses/:course_id/assignments/:assignment_id/annotation_categories/download(.:format)                       annotation_categories#download
#       new_annotation_text_course_assignment_annotation_categories GET      /courses/:course_id/assignments/:assignment_id/annotation_categories/new_annotation_text(.:format)            annotation_categories#new_annotation_text
#    create_annotation_text_course_assignment_annotation_categories POST     /courses/:course_id/assignments/:assignment_id/annotation_categories/create_annotation_text(.:format)         annotation_categories#create_annotation_text
#   destroy_annotation_text_course_assignment_annotation_categories DELETE   /courses/:course_id/assignments/:assignment_id/annotation_categories/destroy_annotation_text(.:format)        annotation_categories#destroy_annotation_text
#    update_annotation_text_course_assignment_annotation_categories PUT      /courses/:course_id/assignments/:assignment_id/annotation_categories/update_annotation_text(.:format)         annotation_categories#update_annotation_text
#      find_annotation_text_course_assignment_annotation_categories GET      /courses/:course_id/assignments/:assignment_id/annotation_categories/find_annotation_text(.:format)           annotation_categories#find_annotation_text
#      annotation_text_uses_course_assignment_annotation_categories GET      /courses/:course_id/assignments/:assignment_id/annotation_categories/annotation_text_uses(.:format)           annotation_categories#annotation_text_uses
# uncategorized_annotations_course_assignment_annotation_categories GET      /courses/:course_id/assignments/:assignment_id/annotation_categories/uncategorized_annotations(.:format)      annotation_categories#uncategorized_annotations
#                           course_assignment_annotation_categories GET      /courses/:course_id/assignments/:assignment_id/annotation_categories(.:format)                                annotation_categories#index
#                                                                   POST     /courses/:course_id/assignments/:assignment_id/annotation_categories(.:format)                                annotation_categories#create
#                         new_course_assignment_annotation_category GET      /courses/:course_id/assignments/:assignment_id/annotation_categories/new(.:format)                            annotation_categories#new
#                     refresh_view_tokens_course_assignment_results PUT      /courses/:course_id/assignments/:assignment_id/results/refresh_view_tokens(.:format)                          results#refresh_view_tokens
#                update_view_token_expiry_course_assignment_results PUT      /courses/:course_id/assignments/:assignment_id/results/update_view_token_expiry(.:format)                     results#update_view_token_expiry
#                    download_view_tokens_course_assignment_results GET      /courses/:course_id/assignments/:assignment_id/results/download_view_tokens(.:format)                         results#download_view_tokens
#                                                course_assignments GET      /courses/:course_id/assignments(.:format)                                                                     assignments#index
#                                                                   POST     /courses/:course_id/assignments(.:format)                                                                     assignments#create
#                                             new_course_assignment GET      /courses/:course_id/assignments/new(.:format)                                                                 assignments#new
#                                            edit_course_assignment GET      /courses/:course_id/assignments/:id/edit(.:format)                                                            assignments#edit
#                                                 course_assignment GET      /courses/:course_id/assignments/:id(.:format)                                                                 assignments#show
#                                                                   PATCH    /courses/:course_id/assignments/:id(.:format)                                                                 assignments#update
#                                                                   PUT      /courses/:course_id/assignments/:id(.:format)                                                                 assignments#update
#                                                                   DELETE   /courses/:course_id/assignments/:id(.:format)                                                                 assignments#destroy
#                        student_interface_course_grade_entry_forms GET      /courses/:course_id/grade_entry_forms/student_interface(.:format)                                             grade_entry_forms#student_interface
#                     populate_grades_table_course_grade_entry_form GET      /courses/:course_id/grade_entry_forms/:id/populate_grades_table(.:format)                                     grade_entry_forms#populate_grades_table
#                          get_mark_columns_course_grade_entry_form GET      /courses/:course_id/grade_entry_forms/:id/get_mark_columns(.:format)                                          grade_entry_forms#get_mark_columns
#                              view_summary_course_grade_entry_form GET      /courses/:course_id/grade_entry_forms/:id/view_summary(.:format)                                              grade_entry_forms#view_summary
#                                    grades_course_grade_entry_form GET      /courses/:course_id/grade_entry_forms/:id/grades(.:format)                                                    grade_entry_forms#grades
#                                  download_course_grade_entry_form GET      /courses/:course_id/grade_entry_forms/:id/download(.:format)                                                  grade_entry_forms#download
#                                    upload_course_grade_entry_form POST     /courses/:course_id/grade_entry_forms/:id/upload(.:format)                                                    grade_entry_forms#upload
#                              update_grade_course_grade_entry_form POST     /courses/:course_id/grade_entry_forms/:id/update_grade(.:format)                                              grade_entry_forms#update_grade
#               update_grade_entry_students_course_grade_entry_form POST     /courses/:course_id/grade_entry_forms/:id/update_grade_entry_students(.:format)                               grade_entry_forms#update_grade_entry_students
#                         student_interface_course_grade_entry_form GET      /courses/:course_id/grade_entry_forms/:id/student_interface(.:format)                                         grade_entry_forms#student_interface
#                        grade_distribution_course_grade_entry_form GET      /courses/:course_id/grade_entry_forms/:id/grade_distribution(.:format)                                        grade_entry_forms#grade_distribution
#                                    switch_course_grade_entry_form GET      /courses/:course_id/grade_entry_forms/:id/switch(.:format)                                                    grade_entry_forms#switch
#                      upload_course_grade_entry_form_marks_graders POST     /courses/:course_id/grade_entry_forms/:grade_entry_form_id/marks_graders/upload(.:format)                     marks_graders#upload
#              grader_mapping_course_grade_entry_form_marks_graders GET      /courses/:course_id/grade_entry_forms/:grade_entry_form_id/marks_graders/grader_mapping(.:format)             marks_graders#grader_mapping
#                  assign_all_course_grade_entry_form_marks_graders POST     /courses/:course_id/grade_entry_forms/:grade_entry_form_id/marks_graders/assign_all(.:format)                 marks_graders#assign_all
#                unassign_all_course_grade_entry_form_marks_graders POST     /courses/:course_id/grade_entry_forms/:grade_entry_form_id/marks_graders/unassign_all(.:format)               marks_graders#unassign_all
#             unassign_single_course_grade_entry_form_marks_graders POST     /courses/:course_id/grade_entry_forms/:grade_entry_form_id/marks_graders/unassign_single(.:format)            marks_graders#unassign_single
#             randomly_assign_course_grade_entry_form_marks_graders POST     /courses/:course_id/grade_entry_forms/:grade_entry_form_id/marks_graders/randomly_assign(.:format)            marks_graders#randomly_assign
#                             course_grade_entry_form_marks_graders GET      /courses/:course_id/grade_entry_forms/:grade_entry_form_id/marks_graders(.:format)                            marks_graders#index
#                                          course_grade_entry_forms POST     /courses/:course_id/grade_entry_forms(.:format)                                                               grade_entry_forms#create
#                                       new_course_grade_entry_form GET      /courses/:course_id/grade_entry_forms/new(.:format)                                                           grade_entry_forms#new
#                                      edit_course_grade_entry_form GET      /courses/:course_id/grade_entry_forms/:id/edit(.:format)                                                      grade_entry_forms#edit
#                                           course_grade_entry_form GET      /courses/:course_id/grade_entry_forms/:id(.:format)                                                           grade_entry_forms#show
#                                                                   PATCH    /courses/:course_id/grade_entry_forms/:id(.:format)                                                           grade_entry_forms#update
#                                                                   PUT      /courses/:course_id/grade_entry_forms/:id(.:format)                                                           grade_entry_forms#update
#                                                                   DELETE   /courses/:course_id/grade_entry_forms/:id(.:format)                                                           grade_entry_forms#destroy
#                                             add_note_course_notes POST     /courses/:course_id/notes/add_note(.:format)                                                                  notes#add_note
#                             noteable_object_selector_course_notes POST     /courses/:course_id/notes/noteable_object_selector(.:format)                                                  notes#noteable_object_selector
#                                 new_update_groupings_course_notes GET      /courses/:course_id/notes/new_update_groupings(.:format)                                                      notes#new_update_groupings
#                                                                   POST     /courses/:course_id/notes/new_update_groupings(.:format)                                                      notes#new_update_groupings
#                                         notes_dialog_course_notes GET      /courses/:course_id/notes/notes_dialog(.:format)                                                              notes#notes_dialog
#                                                      course_notes GET      /courses/:course_id/notes(.:format)                                                                           notes#index
#                                                                   POST     /courses/:course_id/notes(.:format)                                                                           notes#create
#                                                   new_course_note GET      /courses/:course_id/notes/new(.:format)                                                                       notes#new
#                                                  edit_course_note GET      /courses/:course_id/notes/:id/edit(.:format)                                                                  notes#edit
#                                                       course_note PATCH    /courses/:course_id/notes/:id(.:format)                                                                       notes#update
#                                                                   PUT      /courses/:course_id/notes/:id(.:format)                                                                       notes#update
#                                                                   DELETE   /courses/:course_id/notes/:id(.:format)                                                                       notes#destroy
#                                  populate_course_course_summaries GET      /courses/:course_id/course_summaries/populate(.:format)                                                       course_summaries#populate
#                get_marking_scheme_details_course_course_summaries GET      /courses/:course_id/course_summaries/get_marking_scheme_details(.:format)                                     course_summaries#get_marking_scheme_details
#                download_csv_grades_report_course_course_summaries GET      /courses/:course_id/course_summaries/download_csv_grades_report(.:format)                                     course_summaries#download_csv_grades_report
#                              view_summary_course_course_summaries GET      /courses/:course_id/course_summaries/view_summary(.:format)                                                   course_summaries#view_summary
#                        grade_distribution_course_course_summaries GET      /courses/:course_id/course_summaries/grade_distribution(.:format)                                             course_summaries#grade_distribution
#                                           course_course_summaries GET      /courses/:course_id/course_summaries(.:format)                                                                course_summaries#index
#                                   populate_course_marking_schemes GET      /courses/:course_id/marking_schemes/populate(.:format)                                                        marking_schemes#populate
#                                            course_marking_schemes GET      /courses/:course_id/marking_schemes(.:format)                                                                 marking_schemes#index
#                                                                   POST     /courses/:course_id/marking_schemes(.:format)                                                                 marking_schemes#create
#                                         new_course_marking_scheme GET      /courses/:course_id/marking_schemes/new(.:format)                                                             marking_schemes#new
#                                        edit_course_marking_scheme GET      /courses/:course_id/marking_schemes/:id/edit(.:format)                                                        marking_schemes#edit
#                                             course_marking_scheme PATCH    /courses/:course_id/marking_schemes/:id(.:format)                                                             marking_schemes#update
#                                                                   PUT      /courses/:course_id/marking_schemes/:id(.:format)                                                             marking_schemes#update
#                                                                   DELETE   /courses/:course_id/marking_schemes/:id(.:format)                                                             marking_schemes#destroy
#                                                   course_sections GET      /courses/:course_id/sections(.:format)                                                                        sections#index
#                                                                   POST     /courses/:course_id/sections(.:format)                                                                        sections#create
#                                                new_course_section GET      /courses/:course_id/sections/new(.:format)                                                                    sections#new
#                                               edit_course_section GET      /courses/:course_id/sections/:id/edit(.:format)                                                               sections#edit
#                                                    course_section PATCH    /courses/:course_id/sections/:id(.:format)                                                                    sections#update
#                                                                   PUT      /courses/:course_id/sections/:id(.:format)                                                                    sections#update
#                                                                   DELETE   /courses/:course_id/sections/:id(.:format)                                                                    sections#destroy
#                        add_existing_annotation_course_annotations POST     /courses/:course_id/annotations/add_existing_annotation(.:format)                                             annotations#add_existing_annotation
#                                                course_annotations POST     /courses/:course_id/annotations(.:format)                                                                     annotations#create
#                                                 course_annotation PATCH    /courses/:course_id/annotations/:id(.:format)                                                                 annotations#update
#                                                                   PUT      /courses/:course_id/annotations/:id(.:format)                                                                 annotations#update
#                                                                   DELETE   /courses/:course_id/annotations/:id(.:format)                                                                 annotations#destroy
#                                       bulk_modify_course_students PATCH    /courses/:course_id/students/bulk_modify(.:format)                                                            students#bulk_modify
#                                            manage_course_students GET      /courses/:course_id/students/manage(.:format)                                                                 students#manage
#                                   add_new_section_course_students GET      /courses/:course_id/students/add_new_section(.:format)                                                        students#add_new_section
#                                          download_course_students GET      /courses/:course_id/students/download(.:format)                                                               students#download
#                                            upload_course_students POST     /courses/:course_id/students/upload(.:format)                                                                 students#upload
#                                          settings_course_students GET      /courses/:course_id/students/settings(.:format)                                                               students#settings
#                                   update_settings_course_students PATCH    /courses/:course_id/students/update_settings(.:format)                                                        students#update_settings
#                      delete_grace_period_deduction_course_student DELETE   /courses/:course_id/students/:id/delete_grace_period_deduction(.:format)                                      students#delete_grace_period_deduction
#                                                   course_students GET      /courses/:course_id/students(.:format)                                                                        students#index
#                                                                   POST     /courses/:course_id/students(.:format)                                                                        students#create
#                                                new_course_student GET      /courses/:course_id/students/new(.:format)                                                                    students#new
#                                               edit_course_student GET      /courses/:course_id/students/:id/edit(.:format)                                                               students#edit
#                                                    course_student PATCH    /courses/:course_id/students/:id(.:format)                                                                    students#update
#                                                                   PUT      /courses/:course_id/students/:id(.:format)                                                                    students#update
#                                                                   DELETE   /courses/:course_id/students/:id(.:format)                                                                    students#destroy
#                                               download_course_tas GET      /courses/:course_id/tas/download(.:format)                                                                    tas#download
#                                                 upload_course_tas POST     /courses/:course_id/tas/upload(.:format)                                                                      tas#upload
#                                                        course_tas GET      /courses/:course_id/tas(.:format)                                                                             tas#index
#                                                                   POST     /courses/:course_id/tas(.:format)                                                                             tas#create
#                                                     new_course_ta GET      /courses/:course_id/tas/new(.:format)                                                                         tas#new
#                                                    edit_course_ta GET      /courses/:course_id/tas/:id/edit(.:format)                                                                    tas#edit
#                                                         course_ta PATCH    /courses/:course_id/tas/:id(.:format)                                                                         tas#update
#                                                                   PUT      /courses/:course_id/tas/:id(.:format)                                                                         tas#update
#                                                                   DELETE   /courses/:course_id/tas/:id(.:format)                                                                         tas#destroy
#                                                 course_extensions POST     /courses/:course_id/extensions(.:format)                                                                      extensions#create
#                                                  course_extension PATCH    /courses/:course_id/extensions/:id(.:format)                                                                  extensions#update
#                                                                   PUT      /courses/:course_id/extensions/:id(.:format)                                                                  extensions#update
#                                                                   DELETE   /courses/:course_id/extensions/:id(.:format)                                                                  extensions#destroy
#                                              course_feedback_file GET      /courses/:course_id/feedback_files/:id(.:format)                                                              feedback_files#show
#                                                           courses GET      /courses(.:format)                                                                                            courses#index
#                                                       edit_course GET      /courses/:id/edit(.:format)                                                                                   courses#edit
#                                                            course GET      /courses/:id(.:format)                                                                                        courses#show
#                                                                   PATCH    /courses/:id(.:format)                                                                                        courses#update
#                                                                   PUT      /courses/:id(.:format)                                                                                        courses#update
#                                                         key_pairs POST     /key_pairs(.:format)                                                                                          key_pairs#create
#                                                      new_key_pair GET      /key_pairs/new(.:format)                                                                                      key_pairs#new
#                                                          key_pair DELETE   /key_pairs/:id(.:format)                                                                                      key_pairs#destroy
#                                               reset_api_key_users POST     /users/reset_api_key(.:format)                                                                                users#reset_api_key
#                                                    settings_users GET      /users/settings(.:format)                                                                                     users#settings
#                                                                   POST     /users/settings(.:format)                                                                                     users#settings
#                                             update_settings_users PATCH    /users/update_settings(.:format)                                                                              users#update_settings
#                                                 logout_main_index POST     /main/logout(.:format)                                                                                        main#logout
#                                                  about_main_index GET      /main/about(.:format)                                                                                         main#about
#                                          check_timeout_main_index GET      /main/check_timeout(.:format)                                                                                 main#check_timeout
#                                        refresh_session_main_index POST     /main/refresh_session(.:format)                                                                               main#refresh_session
#                                      login_remote_auth_main_index GET      /main/login_remote_auth(.:format)                                                                             main#login_remote_auth
#                                                   get_job_message GET      /job_messages/:job_id/get(.:format)                                                                           job_messages#get
#                                        public_jwk_lti_deployments GET      /lti_deployments/public_jwk(.:format)                                                                         lti_deployments#public_jwk
#                                                 get_config_canvas GET      /lti_deployments/canvas/get_config(.:format)                                                                  canvas#get_config
#                                                     launch_canvas POST     /lti_deployments/canvas/launch(.:format)                                                                      canvas#launch
#                                             redirect_login_canvas POST     /lti_deployments/canvas/redirect_login(.:format)                                                              canvas#redirect_login
#                                                                   GET      /lti_deployments/canvas/redirect_login(.:format)                                                              canvas#redirect_login
#                                      choose_course_lti_deployment GET      /lti_deployments/:id/choose_course(.:format)                                                                  lti_deployments#choose_course
#                                                                   POST     /lti_deployments/:id/choose_course(.:format)                                                                  lti_deployments#choose_course
#                                  course_not_set_up_lti_deployment GET      /lti_deployments/:id/course_not_set_up(.:format)                                                              lti_deployments#course_not_set_up
#                                      create_course_lti_deployment POST     /lti_deployments/:id/create_course(.:format)                                                                  lti_deployments#create_course
#                                                              main POST     /main(.:format)                                                                                               courses#index
#                                                        main_about POST     /main/about(.:format)                                                                                         main#about
#                                                       main_logout POST     /main/logout(.:format)                                                                                        main#logout
#                                                                            /*path(.:format)                                                                                              main#page_not_found
#                                                 rails_performance          /admin/rails/performance                                                                                      RailsPerformance::Engine
#                                     rails_postmark_inbound_emails POST     /rails/action_mailbox/postmark/inbound_emails(.:format)                                                       action_mailbox/ingresses/postmark/inbound_emails#create
#                                        rails_relay_inbound_emails POST     /rails/action_mailbox/relay/inbound_emails(.:format)                                                          action_mailbox/ingresses/relay/inbound_emails#create
#                                     rails_sendgrid_inbound_emails POST     /rails/action_mailbox/sendgrid/inbound_emails(.:format)                                                       action_mailbox/ingresses/sendgrid/inbound_emails#create
#                               rails_mandrill_inbound_health_check GET      /rails/action_mailbox/mandrill/inbound_emails(.:format)                                                       action_mailbox/ingresses/mandrill/inbound_emails#health_check
#                                     rails_mandrill_inbound_emails POST     /rails/action_mailbox/mandrill/inbound_emails(.:format)                                                       action_mailbox/ingresses/mandrill/inbound_emails#create
#                                      rails_mailgun_inbound_emails POST     /rails/action_mailbox/mailgun/inbound_emails/mime(.:format)                                                   action_mailbox/ingresses/mailgun/inbound_emails#create
#                                    rails_conductor_inbound_emails GET      /rails/conductor/action_mailbox/inbound_emails(.:format)                                                      rails/conductor/action_mailbox/inbound_emails#index
#                                                                   POST     /rails/conductor/action_mailbox/inbound_emails(.:format)                                                      rails/conductor/action_mailbox/inbound_emails#create
#                                 new_rails_conductor_inbound_email GET      /rails/conductor/action_mailbox/inbound_emails/new(.:format)                                                  rails/conductor/action_mailbox/inbound_emails#new
#                                     rails_conductor_inbound_email GET      /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                                                  rails/conductor/action_mailbox/inbound_emails#show
#                          new_rails_conductor_inbound_email_source GET      /rails/conductor/action_mailbox/inbound_emails/sources/new(.:format)                                          rails/conductor/action_mailbox/inbound_emails/sources#new
#                             rails_conductor_inbound_email_sources POST     /rails/conductor/action_mailbox/inbound_emails/sources(.:format)                                              rails/conductor/action_mailbox/inbound_emails/sources#create
#                             rails_conductor_inbound_email_reroute POST     /rails/conductor/action_mailbox/:inbound_email_id/reroute(.:format)                                           rails/conductor/action_mailbox/reroutes#create
#                          rails_conductor_inbound_email_incinerate POST     /rails/conductor/action_mailbox/:inbound_email_id/incinerate(.:format)                                        rails/conductor/action_mailbox/incinerates#create
#                                                rails_service_blob GET      /rails/active_storage/blobs/redirect/:signed_id/*filename(.:format)                                           active_storage/blobs/redirect#show
#                                          rails_service_blob_proxy GET      /rails/active_storage/blobs/proxy/:signed_id/*filename(.:format)                                              active_storage/blobs/proxy#show
#                                                                   GET      /rails/active_storage/blobs/:signed_id/*filename(.:format)                                                    active_storage/blobs/redirect#show
#                                         rails_blob_representation GET      /rails/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename(.:format)             active_storage/representations/redirect#show
#                                   rails_blob_representation_proxy GET      /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)                active_storage/representations/proxy#show
#                                                                   GET      /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format)                      active_storage/representations/redirect#show
#                                                rails_disk_service GET      /rails/active_storage/disk/:encoded_key/*filename(.:format)                                                   active_storage/disk#show
#                                         update_rails_disk_service PUT      /rails/active_storage/disk/:encoded_token(.:format)                                                           active_storage/disk#update
#                                              rails_direct_uploads POST     /rails/active_storage/direct_uploads(.:format)                                                                active_storage/direct_uploads#create
#
# Routes for RailsPerformance::Engine:
#                        Prefix Verb URI Pattern            Controller#Action
#             rails_performance GET  /                      rails_performance/rails_performance#index
#    rails_performance_requests GET  /requests(.:format)    rails_performance/rails_performance#requests
#     rails_performance_crashes GET  /crashes(.:format)     rails_performance/rails_performance#crashes
#      rails_performance_recent GET  /recent(.:format)      rails_performance/rails_performance#recent
#        rails_performance_slow GET  /slow(.:format)        rails_performance/rails_performance#slow
#       rails_performance_trace GET  /trace/:id(.:format)   rails_performance/rails_performance#trace
#     rails_performance_summary GET  /summary(.:format)     rails_performance/rails_performance#summary
#     rails_performance_sidekiq GET  /sidekiq(.:format)     rails_performance/rails_performance#sidekiq
# rails_performance_delayed_job GET  /delayed_job(.:format) rails_performance/rails_performance#delayed_job
#       rails_performance_grape GET  /grape(.:format)       rails_performance/rails_performance#grape
#        rails_performance_rake GET  /rake(.:format)        rails_performance/rails_performance#rake
#      rails_performance_custom GET  /custom(.:format)      rails_performance/rails_performance#custom
#   rails_performance_resources GET  /resources(.:format)   rails_performance/rails_performance#resources
#
# Routes for PgHero::Engine:
#                    Prefix Verb URI Pattern                                      Controller#Action
#                     space GET  (/:database)/space(.:format)                     pg_hero/home#space
#            relation_space GET  (/:database)/space/:relation(.:format)           pg_hero/home#relation_space
#               index_bloat GET  (/:database)/index_bloat(.:format)               pg_hero/home#index_bloat
#              live_queries GET  (/:database)/live_queries(.:format)              pg_hero/home#live_queries
#                   queries GET  (/:database)/queries(.:format)                   pg_hero/home#queries
#                show_query GET  (/:database)/queries/:query_hash(.:format)       pg_hero/home#show_query
#                    system GET  (/:database)/system(.:format)                    pg_hero/home#system
#                 cpu_usage GET  (/:database)/cpu_usage(.:format)                 pg_hero/home#cpu_usage
#          connection_stats GET  (/:database)/connection_stats(.:format)          pg_hero/home#connection_stats
#     replication_lag_stats GET  (/:database)/replication_lag_stats(.:format)     pg_hero/home#replication_lag_stats
#                load_stats GET  (/:database)/load_stats(.:format)                pg_hero/home#load_stats
#          free_space_stats GET  (/:database)/free_space_stats(.:format)          pg_hero/home#free_space_stats
#                   explain GET  (/:database)/explain(.:format)                   pg_hero/home#explain
#                      tune GET  (/:database)/tune(.:format)                      pg_hero/home#tune
#               connections GET  (/:database)/connections(.:format)               pg_hero/home#connections
#               maintenance GET  (/:database)/maintenance(.:format)               pg_hero/home#maintenance
#                      kill POST (/:database)/kill(.:format)                      pg_hero/home#kill
# kill_long_running_queries POST (/:database)/kill_long_running_queries(.:format) pg_hero/home#kill_long_running_queries
#                  kill_all POST (/:database)/kill_all(.:format)                  pg_hero/home#kill_all
#        enable_query_stats POST (/:database)/enable_query_stats(.:format)        pg_hero/home#enable_query_stats
#                           POST (/:database)/explain(.:format)                   pg_hero/home#explain
#         reset_query_stats POST (/:database)/reset_query_stats(.:format)         pg_hero/home#reset_query_stats
#              system_stats GET  (/:database)/system_stats(.:format)              redirect(301, system)
#               query_stats GET  (/:database)/query_stats(.:format)               redirect(301, queries)
#                      root GET  /(:database)(.:format)                           pg_hero/home#index
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective

require 'resque/server'
require 'rails_performance'

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
        get 'test_autotest_connection'
        put 'reset_autotest_connection'
      end
      resources :tags, only: [:index, :create, :update, :destroy]
      resources :roles, except: [:new, :edit, :destroy] do
        collection do
          post 'create_or_unhide'
          put 'update_by_username'
        end
      end
      resources :grade_entry_forms, only: [:show, :index, :create, :update, :destroy] do
        member do
          put 'update_grades'
        end
      end
      resources :assignments, except: [:new, :edit] do
        resources :groups, except: [:new, :edit, :destroy] do
          collection do
            get 'annotations'
            get 'group_ids_by_name'
          end
          member do
            put 'add_tag'
            put 'remove_tag'
            post 'collect_submission'
            post 'add_test_run'
            get 'test_results'
          end
          resources :submission_files, only: [:index, :create] do
            collection do
              delete 'remove_file'
              delete 'remove_folder'
              post 'create_folders'
            end
          end
          resources :feedback_files, only: [:index, :show, :create, :update, :destroy]
          member do
            get 'annotations'
            post 'add_annotations'
            post 'add_members'
            post 'create_extra_marks'
            put 'update_marks'
            put 'update_marking_state'
            delete 'remove_extra_marks'
          end
          member do
            post 'extension'
            patch 'extension'
            delete 'extension'
          end
        end
        resources :starter_file_groups, only: [:index, :create]
        member do
          get 'test_files'
          get 'grades_summary'
          get 'test_specs'
          post 'update_test_specs'
          post 'submit_file'
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
      resources :sections, only: [:create, :destroy, :index, :show, :update]
    end
    # Return a 404 when no route is match
    match '*path', controller: 'main_api', action: 'page_not_found', via: :all
  end

  namespace :admin do
    resources :users, only: [:index, :new, :create, :edit, :update] do
      collection do
        post 'upload'
      end
    end
    resources :courses, only: [:index, :new, :create, :edit, :update] do
      member do
        get 'test_autotest_connection'
        put 'reset_autotest_connection'
        post 'refresh_autotest_schema'
        delete 'destroy_lti_deployment'
      end
    end
    get '/', controller: 'main_admin', action: 'index'

    mount Resque::Server.new, at: '/resque', as: 'resque'
    mount RailsPerformance::Engine, at: '/rails/performance', as: 'performance'
    mount PgHero::Engine, at: '/rails/pghero', as: 'pghero'
  end

  resources :courses, only: [:show, :index, :edit, :update] do
    member do
      get 'clear_role_switch_session'
      get 'role_switch'
      post 'switch_role'
      get 'download_assignments'
      post 'upload_assignments'
      delete 'destroy_lti_deployment'
      post 'sync_roster'
      get 'lti_deployments'
      get 'lti_settings'
    end

    resources :instructors, only: [:index, :new, :create, :edit, :update, :destroy]

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
      end
    end

    resources :results, only: [:show, :edit] do
      member do
        get 'get_annotations'
        get 'add_extra_marks'
        post 'download'
        post 'add_extra_mark'
        delete 'delete_grace_period_deduction'
        get 'next_grouping'
        get 'get_filtered_grouping_ids'
        get 'print'
        delete 'remove_extra_mark'
        patch 'revert_to_automatic_deductions'
        post 'set_released_to_students'
        post 'update_overall_comment'
        post 'toggle_marking_state'
        get 'update_positions'
        patch 'update_mark'
        get 'view_marks'
        post 'add_tag'
        get 'random_incomplete_submission'
        post 'remove_tag'
        post 'run_tests'
        get 'stop_test'
        get 'get_test_runs_instructors'
        get 'get_test_runs_instructors_released'
        get 'view_token_check'
      end
    end

    resources :peer_reviews, only: [] do
      member do
        get 'show_result'
      end
    end

    resources :annotation_categories, only: [:show, :destroy, :update]

    resources :assignments do
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
        get 'lti_settings'
        post 'create_lti_grades'
        post 'create_lti_line_items'
      end

      resources :starter_file_groups, only: [:create]

      resources :criteria, only: [:create, :index, :new] do
        collection do
          post 'update_positions'
          post 'upload'
          get 'download'
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
          patch 'split'
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
          patch 'populate_repo_with_starter_files'
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
          post 'auto_match'
        end
      end

      resources :submissions, only: [:index] do
        collection do
          get 'file_manager'
          get 'browse'
          get 'populate_file_manager'
          get 'revisions'
          post 'collect_submissions'
          get 'uncollect_all_submissions'
          post 'run_tests'
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
          get 'download_summary'
          get 'repo_browser'
          post 'repo_browser'
          post 'manually_collect_and_begin_grading'
          get 'downloads'
        end
        member do
          get 'download_file'
          get 'download_file_zip'
          delete 'cancel_remark_request'
          patch 'update_remark_request'
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
          get 'populate_table'
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

      resources :results, only: [] do
        collection do
          put 'refresh_view_tokens'
          put 'update_view_token_expiry'
          get 'download_view_tokens'
        end
      end
    end

    resources :grade_entry_forms, except: [:index] do
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

    resources :students, only: [:create, :new, :index, :edit, :update, :destroy] do
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

    resources :tas, only: [:create, :new, :index, :edit, :update, :destroy] do
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

  resources :lti_deployments, only: [] do
    collection do
      get 'public_jwk'
      resources :canvas, only: [] do
        collection do
          get 'get_config'
          post 'launch'
          post 'redirect_login'
          get 'redirect_login'
        end
      end
    end
    member do
      get 'choose_course'
      post 'choose_course'
      get 'course_not_set_up'
      post 'create_course'
    end
  end

  post 'main', controller: 'courses', action: 'index'
  post 'main/about', controller: 'main', action: 'about'
  post 'main/logout', controller: 'main', action: 'logout'

  match '*path', controller: 'main', action: 'page_not_found', via: :all
end
