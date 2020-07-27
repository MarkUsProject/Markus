describe 'Routing to main page', type: :routing do
  context 'Locale-less root' do
    it 'routes / to login' do
      expect(get: '/').to route_to(
        controller: 'main',
        action: 'login'
      )
    end
  end

  context 'Root with locale' do
    it 'routes /en/ to error' do
      expect(get: '/en/').not_to be_routable
    end
  end
end

# start Admin route tests
context 'Admin resource' do
  let(:admin) { create(:admin) }
  let(:path) { '/en/admins' }
  let(:ctrl) { 'admins' }

  it 'routes GET index correctly' do
    expect(get: path).to route_to(
      controller: ctrl,
      action: 'index',
      locale: 'en')
  end

  it 'routes GET new correctly' do
    expect(get: path + '/new').to route_to(
      controller: ctrl,
      action: 'new',
      locale: 'en')
  end

  it 'routes POST create correctly' do
    expect(post: path).to route_to(
      controller: ctrl,
      action: 'create',
      locale: 'en')
  end

  it 'routes GET show correctly' do
    expect(get: path + '/' + admin.id.to_s).to route_to(
      controller: ctrl,
      action: 'show',
      id: admin.id.to_s,
      locale: 'en')
  end

  it 'routes GET edit correctly' do
    expect(get: path + '/' + admin.id.to_s + '/edit').to route_to(
      controller: ctrl,
      action: 'edit',
      id: admin.id.to_s,
      locale: 'en')
  end

  it 'routes PUT update correctly' do
    expect(put: path + '/' + admin.id.to_s).to route_to(
      controller: ctrl,
      action: 'update',
      id: admin.id.to_s,
      locale: 'en')
  end

  it 'routes DELETE destroy correctly' do
    expect(delete: path + '/' + admin.id.to_s).to route_to(
      controller: ctrl,
      action: 'destroy',
      id: admin.id.to_s,
      locale: 'en')
  end
end
# end Admin route tests

# start Assignment route tests
describe 'An Assignment' do
  let(:assignment) { create(:assignment) }
  let(:path) { '/en/assignments' }
  let(:ctrl) { 'assignments' }

  # start Assignment collection route tests
  context 'collection' do
    it 'routes GET delete_rejected properly' do
      expect(get: path + '/delete_rejected').to route_to(
        controller: ctrl,
        action: 'delete_rejected',
        locale: 'en')
    end
  end
  # end Assignment collection route tests

  # start Assignment member route tests
  context 'member' do
    it 'routs GET refresh_graph properly' do
      expect(get: path + '/' + assignment.id.to_s + '/refresh_graph')
        .to route_to(
          controller: ctrl,
          action: 'refresh_graph',
          id: assignment.id.to_s,
          locale: 'en')
    end

    it 'routes POST set_boolean_graders_options properly' do
      expect(post: path + '/' + assignment.id.to_s + '/set_boolean_graders_options')
        .to route_to(controller: ctrl,
                     action: 'set_boolean_graders_options',
                     id: assignment.id.to_s,
                     locale: 'en')
    end

    it 'routes GET show properly' do
      expect(get: path + '/' + assignment.id.to_s)
        .to route_to(
          controller: ctrl,
          action: 'show',
          id: assignment.id.to_s,
          locale: 'en')
    end

    it 'routes PUT start_timed_assignment properly' do
      expect(put: path + '/' + assignment.id.to_s + '/start_timed_assignment')
        .to route_to(controller: ctrl,
                     action: 'start_timed_assignment',
                     id: assignment.id.to_s,
                     locale: 'en')
    end
  end
  # end Assignment member route tests

  # start assignment criteria route tests
  context 's criteria' do
    context 'collection' do
      let(:criteria_path) { path + '/' + assignment.id.to_s + '/criteria' }
      let(:criteria_ctrl) { 'criteria' }

      it 'routes POST update_positions properly' do
        expect(post: criteria_path + '/update_positions').to route_to(
          controller: criteria_ctrl,
          action: 'update_positions',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET show id: update_positions' do
        expect(get: criteria_path + '/update_positions').to route_to(
          controller: criteria_ctrl,
          action: 'show',
          id: 'update_positions',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET download properly' do
        expect(get: criteria_path + '/download').to route_to(
          controller: criteria_ctrl,
          action: 'download',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST upload properly' do
        expect(post: criteria_path + '/upload').to route_to(
          controller: criteria_ctrl,
          action: 'upload',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end
    end
  end
  # end assignment criteria route tests

  # start assignment automated_tests resource route tests
  context 's automated_tests' do
    let(:autom_path) { path + '/' + assignment.id.to_s + '/automated_tests' }
    let(:autom_ctrl) { 'automated_tests' }

    context 'collection' do
      it 'routes GET manage properly' do
        expect(get: autom_path + '/manage').to route_to(
          controller: autom_ctrl,
          action: 'manage',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST update properly' do
        expect(post: autom_path).to route_to(
          controller: autom_ctrl,
          action: 'create',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST update_positions properly' do
        expect(post: autom_path + '/update_positions').to route_to(
          controller: autom_ctrl,
          action: 'update_positions',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET update_positions properly' do
        expect(get: autom_path + '/update_positions').to route_to(
          controller: autom_ctrl,
          action: 'update_positions',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST upload properly' do
        expect(post: autom_path + '/upload').to route_to(
          controller: autom_ctrl,
          action: 'upload',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET download properly' do
        expect(get: autom_path + '/download').to route_to(
          controller: autom_ctrl,
          action: 'download',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET get_test_runs_students properly' do
        expect(get: autom_path + '/get_test_runs_students').to route_to(controller: autom_ctrl,
                                                                        action: 'get_test_runs_students',
                                                                        assignment_id: assignment.id.to_s,
                                                                        locale: 'en')
      end

      it 'routes GET populate_autotest_manager properly' do
        expect(get: autom_path + '/populate_autotest_manager').to route_to(controller: autom_ctrl,
                                                                           action: 'populate_autotest_manager',
                                                                           assignment_id: assignment.id.to_s,
                                                                           locale: 'en')
      end

      it 'routes GET download_file properly' do
        expect(get: autom_path + '/download_file').to route_to(controller: autom_ctrl,
                                                               action: 'download_file',
                                                               assignment_id: assignment.id.to_s,
                                                               locale: 'en')
      end

      it 'routes GET download_files properly' do
        expect(get: autom_path + '/download_files').to route_to(controller: autom_ctrl,
                                                                action: 'download_files',
                                                                assignment_id: assignment.id.to_s,
                                                                locale: 'en')
      end

      it 'routes GET download_specs properly' do
        expect(get: autom_path + '/download_specs').to route_to(controller: autom_ctrl,
                                                                action: 'download_specs',
                                                                assignment_id: assignment.id.to_s,
                                                                locale: 'en')
      end

      it 'routes POST upload_files properly' do
        expect(post: autom_path + '/upload_files').to route_to(controller: autom_ctrl,
                                                               action: 'upload_files',
                                                               assignment_id: assignment.id.to_s,
                                                               locale: 'en')
      end

      it 'routes POST upload_specs properly' do
        expect(post: autom_path + '/upload_specs').to route_to(controller: autom_ctrl,
                                                               action: 'upload_specs',
                                                               assignment_id: assignment.id.to_s,
                                                               locale: 'en')
      end
    end
  end
  # end assignment automated_tests resource route tests

  # start assignment group route tests
  context 'groups' do
    let(:group) { create(:group) }
    let(:group_path) { path + '/' + assignment.id.to_s + '/groups' }
    let(:group_ctrl) { 'groups' }

    context 'resource members' do
      it 'routes DELETE destroy properly' do
        expect(delete: group_path + '/' + group.id.to_s).to route_to(
          controller: group_ctrl,
          action: 'destroy',
          id: group.id.to_s,
          assignment_id: assignment.id.to_s,
          locale: 'en'
        )
      end

      it 'routes POST rename_group properly' do
        expect(post: group_path + '/' + group.id.to_s + '/rename_group')
          .to route_to(
            controller: group_ctrl,
            action: 'rename_group',
            id: group.id.to_s,
            assignment_id: assignment.id.to_s,
            locale: 'en')
      end
    end

    context 'collection' do
      it 'routes POST create properly' do
        expect(post: group_path).to route_to(
          controller: group_ctrl,
          action: 'create',
          assignment_id: assignment.id.to_s,
          locale: 'en'
        )
      end

      it 'routes PATCH accept_invitation properly' do
        expect(patch: group_path + '/accept_invitation').to route_to(
          controller: group_ctrl,
          action: 'accept_invitation',
          assignment_id: assignment.id.to_s,
          locale: 'en'
        )
      end

      it 'routes PATCH decline_invitation properly' do
        expect(patch: group_path + '/decline_invitation').to route_to(
          controller: group_ctrl,
          action: 'decline_invitation',
          assignment_id: assignment.id.to_s,
          locale: 'en'
        )
      end

      it 'routes POST invite_member properly' do
        expect(post: group_path + '/invite_member').to route_to(
          controller: group_ctrl,
          action: 'invite_member',
          assignment_id: assignment.id.to_s,
          locale: 'en'
        )
      end

      it 'routes PATCH disinvite_member properly' do
        expect(patch: group_path + '/disinvite_member').to route_to(
          controller: group_ctrl,
          action: 'disinvite_member',
          assignment_id: assignment.id.to_s,
          locale: 'en'
        )
      end

      it 'routes DELETE delete_rejected properly' do
        expect(delete: group_path + '/delete_rejected').to route_to(
          controller: group_ctrl,
          action: 'delete_rejected',
          assignment_id: assignment.id.to_s,
          locale: 'en'
        )
      end

      it 'routes GET index properly' do
        expect(get: group_path).to route_to(
          controller: group_ctrl,
          action: 'index',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET add_group properly' do
        expect(get: group_path + '/add_group').to route_to(
          controller: group_ctrl,
          action: 'add_group',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST use_another_assignment_groups properly' do
        expect(post: group_path + '/use_another_assignment_groups').to route_to(
          controller: group_ctrl,
          action: 'use_another_assignment_groups',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET manage properly' do
        expect(get: group_path + '/manage').to route_to(
          controller: group_ctrl,
          action: 'manage',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST upload properly' do
        expect(post: group_path + '/upload').to route_to(
          controller: group_ctrl,
          action: 'upload',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET add_csv_group properly' do
        expect(get: group_path + '/add_csv_group').to route_to(
          controller: group_ctrl,
          action: 'add_csv_group',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET download_grouplist properly' do
        expect(get: group_path + '/download_grouplist').to route_to(
          controller: group_ctrl,
          action: 'download_grouplist',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'route GET create_groups_when_students_work_alone properly' do
        expect(get: group_path + '/create_groups_when_students_work_alone')
          .to route_to(
            controller: group_ctrl,
            action: 'create_groups_when_students_work_alone',
            assignment_id: assignment.id.to_s,
            locale: 'en')
      end

      it 'routes GET valid_grouping properly' do
        expect(get: group_path + '/valid_grouping').to route_to(
          controller: group_ctrl,
          action: 'valid_grouping',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET invalid_grouping properly' do
        expect(get: group_path + '/invalid_grouping').to route_to(
          controller: group_ctrl,
          action: 'invalid_grouping',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET global_actions properly' do
        expect(get: group_path + '/global_actions').to route_to(
          controller: group_ctrl,
          action: 'global_actions',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET rename_group properly' do
        expect(get: group_path + '/rename_group').to route_to(
          controller: group_ctrl,
          action: 'rename_group',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes DELETE remove_group properly' do
        expect(delete: group_path + '/remove_group').to route_to(
          controller: group_ctrl,
          action: 'remove_group',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST add_group properly' do
        expect(post: group_path + '/add_group').to route_to(
          controller: group_ctrl,
          action: 'add_group',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST global_actions properly' do
        expect(post: group_path + '/global_actions').to route_to(
          controller: group_ctrl,
          action: 'global_actions',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end
    end
  end
  # end assignment group route tests

  # start assignment submissions route tests
  context 'submission' do
    let(:submission) { create(:submission) }
    let(:sub_path) { path + '/' + assignment.id.to_s + '/submissions' }
    let(:sub_ctrl) { 'submissions' }

    context 'collection' do
      it 'routes GET file_manager properly' do
        expect(get: sub_path + '/file_manager').to route_to(
          controller: sub_ctrl,
          action: 'file_manager',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET browse properly' do
        expect(get: sub_path + '/browse').to route_to(
          controller: sub_ctrl,
          action: 'browse',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET populate_file_manager properly' do
        expect(get: sub_path + '/populate_file_manager').to route_to(
          controller: sub_ctrl,
          action: 'populate_file_manager',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET download_repo_checkout_commands properly' do
        expect(get: sub_path + '/download_repo_checkout_commands').to route_to(
          controller: sub_ctrl,
          action: 'download_repo_checkout_commands',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET download_repo_list properly' do
        expect(get: sub_path + '/download_repo_list').to route_to(
          controller: sub_ctrl,
          action: 'download_repo_list',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET populate_submissions_table' do
        expect(get: sub_path + '/populate_submissions_table').to route_to(
          controller: sub_ctrl,
          action: 'populate_submissions_table',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET populate_file_manager' do
        expect(get: sub_path + '/populate_file_manager').to route_to(
          controller: sub_ctrl,
          action: 'populate_file_manager',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET updated_files properly' do
        expect(get: sub_path + '/updated_files').to route_to(
          controller: sub_ctrl,
          action: 'updated_files',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET replace_files properly' do
        expect(get: sub_path + '/replace_files').to route_to(
          controller: sub_ctrl,
          action: 'replace_files',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET delete_files properly' do
        expect(get: sub_path + '/delete_files').to route_to(
          controller: sub_ctrl,
          action: 'delete_files',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST update_files properly' do
        expect(post: sub_path + '/update_files').to route_to(
          controller: sub_ctrl,
          action: 'update_files',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST update_submissions properly' do
        expect(post: sub_path + '/update_submissions').to route_to(
          controller: sub_ctrl,
          action: 'update_submissions',
          assignment_id: assignment.id.to_s,
          locale: 'en'
        )
      end

      it 'routes POST set_result_marking_state properly' do
        expect(post: sub_path + '/set_result_marking_state').to route_to(
          controller: sub_ctrl,
          action: 'set_result_marking_state',
          assignment_id: assignment.id.to_s,
          locale: 'en'
        )
      end

      it 'routes GET server_time properly' do
        expect(get: sub_path + '/server_time').to route_to(
          controller: sub_ctrl,
          action: 'server_time',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET download properly' do
        expect(get: sub_path + '/download').to route_to(
          controller: sub_ctrl,
          action: 'download',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end
    end

    context 'member' do
      it 'routes GET collect_and_begin_grading properly' do
        expect(get: sub_path + '/' + submission.id.to_s +
          '/collect_and_begin_grading').to route_to(
            controller: sub_ctrl,
            action: 'collect_and_begin_grading',
            id: submission.id.to_s,
            assignment_id: assignment.id.to_s,
            locale: 'en')
      end

      it 'routes POST manually_collect_and_begin_grading properly' do
        expect(post: sub_path + '/' + submission.id.to_s +
          '/manually_collect_and_begin_grading').to route_to(
            controller: sub_ctrl,
            action: 'manually_collect_and_begin_grading',
            id: submission.id.to_s,
            assignment_id: assignment.id.to_s,
            locale: 'en')
      end

      it 'routes GET repo_browser properly' do
        expect(get: sub_path + '/' + submission.id.to_s + '/repo_browser')
          .to route_to(
            controller: sub_ctrl,
            action: 'repo_browser',
            id: submission.id.to_s,
            assignment_id: assignment.id.to_s,
            locale: 'en')
      end
    end

    context 'results' do
      let(:res_path) { sub_path + '/' + submission.id.to_s + '/results' }
      let(:res_ctrl) { 'results' }

      context 'collection' do
        it 'routes PATCH update_mark properly' do
          expect(patch: res_path + '/1/update_mark').to route_to(
            controller: res_ctrl,
            action: 'update_mark',
            id: '1',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes GET expand_criteria properly' do
          expect(get: res_path + '/expand_criteria').to route_to(
            controller: res_ctrl,
            action: 'show',
            id: 'expand_criteria',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes GET collapse_criteria properly' do
          expect(get: res_path + '/collapse_criteria').to route_to(
            controller: res_ctrl,
            action: 'show',
            id: 'collapse_criteria',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes GET expand_unmarked_criteria properly' do
          expect(get: res_path + '/expand_unmarked_criteria').to route_to(
            controller: res_ctrl,
            action: 'show',
            id: 'expand_unmarked_criteria',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes GET edit properly' do
          expect(get: res_path + '/edit').to route_to(
            controller: res_ctrl,
            action: 'edit',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes GET download properly' do
          expect(get: res_path + '/download').to route_to(
            controller: res_ctrl,
            action: 'download',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end
      end

      context 'member' do
        it 'routes GET download properly' do
          expect(get: res_path + '/1/download').to route_to(
            controller: res_ctrl,
            action: 'download',
            id: '1',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes POST download properly' do
          expect(post: res_path + '/1/download').to route_to(
            controller: res_ctrl,
            action: 'download',
            id: '1',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes DELETE cancel_remark_request properly' do
          expect(delete: res_path + '/1/cancel_remark_request').to route_to(
            controller: res_ctrl,
            action: 'cancel_remark_request',
            id: '1',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes POST add_extra_mark properly' do
          expect(post: res_path + '/1/add_extra_mark').to route_to(
            controller: res_ctrl,
            action: 'add_extra_mark',
            id: '1',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes GET next_grouping properly' do
          expect(get: res_path + '/1/next_grouping').to route_to(
            controller: res_ctrl,
            action: 'next_grouping',
            id: '1',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes POST remove_extra_mark properly' do
          expect(post: res_path + '/1/remove_extra_mark').to route_to(
            controller: res_ctrl,
            action: 'remove_extra_mark',
            id: '1',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes POST set_released_to_students properly' do
          expect(post: res_path + '/1/set_released_to_students').to route_to(
            controller: res_ctrl,
            action: 'set_released_to_students',
            id: '1',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes POST update_overall_comment properly' do
          expect(post: res_path + '/1/update_overall_comment').to route_to(
            controller: res_ctrl,
            action: 'update_overall_comment',
            id: '1',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes POST toggle_marking_state properly' do
          expect(post: res_path + '/1/toggle_marking_state').to route_to(
            controller: res_ctrl,
            action: 'toggle_marking_state',
            id: '1',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes PATCH update_remark_request properly' do
          expect(patch: res_path + '/1/update_remark_request').to route_to(
            controller: res_ctrl,
            action: 'update_remark_request',
            id: '1',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes GET update_positions properly' do
          expect(get: res_path + '/1/update_positions').to route_to(
            controller: res_ctrl,
            action: 'update_positions',
            id: '1',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end

        it 'routes GET view_marks properly' do
          expect(get: res_path + '/1/view_marks').to route_to(
            controller: res_ctrl,
            action: 'view_marks',
            id: '1',
            assignment_id: assignment.id.to_s,
            submission_id: submission.id.to_s,
            locale: 'en')
        end
      end
    end
  end
  # end assignment submissions route tests

  context 'grader' do
    let(:grader_path) { path + '/' + assignment.id.to_s + '/graders' }
    let(:grader_ctrl) { 'graders' }

    context 'collection' do
      it 'routes POST upload properly' do
        expect(post: grader_path + '/upload')
          .to route_to(
            controller: grader_ctrl,
            action: 'upload',
            assignment_id: assignment.id.to_s,
            locale: 'en')
      end

      it 'routes GET grader_groupings_mapping properly' do
        expect(get: grader_path + '/grader_groupings_mapping')
          .to route_to(
            controller: grader_ctrl,
            action: 'grader_groupings_mapping',
            assignment_id: assignment.id.to_s,
            locale: 'en')
      end

      it 'routes GET grader_criteria_mapping properly' do
        expect(get: grader_path + '/grader_criteria_mapping')
          .to route_to(
            controller: grader_ctrl,
            action: 'grader_criteria_mapping',
            assignment_id: assignment.id.to_s,
            locale: 'en')
      end

      it 'routes GET global_actions properly' do
        expect(get: grader_path + '/global_actions').to route_to(
          controller: grader_ctrl,
          action: 'global_actions',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST global_actions properly' do
        expect(post: grader_path + '/global_actions').to route_to(
          controller: grader_ctrl,
          action: 'global_actions',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end
    end
  end
  # end assignment graders route tests

  context 'annotation_categories' do
    let(:annot_path) do
      path + '/' + assignment.id.to_s +
        '/annotation_categories'
    end
    let(:annot_ctrl) { 'annotation_categories' }

    context 'members' do
      let(:id) { '1' }
      it 'routes GET properly' do
        expect(get: annot_path + "/#{1}").to route_to(
          controller: annot_ctrl,
          action: 'show',
          id: id,
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes DELETE properly' do
        expect(delete: annot_path + "/#{1}").to route_to(
          controller: annot_ctrl,
          action: 'destroy',
          id: id,
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes PUT properly' do
        expect(put: annot_path + "/#{1}").to route_to(
          controller: annot_ctrl,
          action: 'update',
          id: id,
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end
    end

    context 'collection' do
      it 'routes GET new properly' do
        expect(get: annot_path + '/new').to route_to(
          controller: annot_ctrl,
          action: 'new',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST properly' do
        expect(post: annot_path).to route_to(
          controller: annot_ctrl,
          action: 'create',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET properly' do
        expect(get: annot_path).to route_to(
          controller: annot_ctrl,
          action: 'index',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST upload properly' do
        expect(post: annot_path + '/upload').to route_to(
          controller: annot_ctrl,
          action: 'upload',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes GET download properly' do
        expect(get: annot_path + '/download').to route_to(
          controller: annot_ctrl,
          action: 'download',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes POST create_annotation_text properly' do
        expect(post: annot_path + '/create_annotation_text').to route_to(
          controller: annot_ctrl,
          action: 'create_annotation_text',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes DELETE destroy_annotation_text properly' do
        expect(delete: annot_path + '/destroy_annotation_text').to route_to(
          controller: annot_ctrl,
          action: 'destroy_annotation_text',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end

      it 'routes PUT update_annotation_text properly' do
        expect(put: annot_path + '/update_annotation_text').to route_to(
          controller: annot_ctrl,
          action: 'update_annotation_text',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end
    end
  end
end
# end assignment route tests

# start grade entry forms route tests
context 'grade_entry_forms' do
  let(:grade_entry_form) { create(:grade_entry_form) }
  let(:path) { '/en/grade_entry_forms' }
  let(:ctrl) { 'grade_entry_forms' }

  context 'collection' do
    it 'routes GET student_interface properly' do
      expect(get: path + '/student_interface').to route_to(
        controller: ctrl,
        action: 'student_interface',
        locale: 'en')
    end
  end
  # end grade_entry_forms collection route tests

  context 'member' do
    it 'routes GET grades properly' do
      expect(get: path + '/' + grade_entry_form.id.to_s + '/grades')
        .to route_to(
          controller: ctrl,
          action: 'grades',
          id: grade_entry_form.id.to_s,
          locale: 'en')
    end

    it 'routes GET download properly' do
      expect(get: path + '/' + grade_entry_form.id.to_s + '/download')
        .to route_to(
          controller: ctrl,
          action: 'download',
          id: grade_entry_form.id.to_s,
          locale: 'en')
    end

    it 'routes POST upload properly' do
      expect(post: path + '/' + grade_entry_form.id.to_s + '/upload')
        .to route_to(
          controller: ctrl,
          action: 'upload',
          id: grade_entry_form.id.to_s,
          locale: 'en')
    end

    it 'routes POST update_grade properly' do
      expect(post: path + '/' + grade_entry_form.id.to_s + '/update_grade')
        .to route_to(
          controller: ctrl,
          action: 'update_grade',
          id: grade_entry_form.id.to_s,
          locale: 'en')
    end

    it 'routes POST update_grade_entry_students properly' do
      expect(post: path + '/' + grade_entry_form.id.to_s +
        '/update_grade_entry_students').to route_to(
          controller: ctrl,
          action: 'update_grade_entry_students',
          id: grade_entry_form.id.to_s,
          locale: 'en')
    end

    it 'routes GET student_interface properly' do
      expect(get: path + '/' + grade_entry_form.id.to_s + '/student_interface')
        .to route_to(
          controller: ctrl,
          action: 'student_interface',
          id: grade_entry_form.id.to_s,
          locale: 'en')
    end
  end
end
# end grade_entry_forms route tests

# start notes route tests
context 'notes' do
  let(:path) { '/en/notes' }
  let(:ctrl) { 'notes' }

  context 'collection' do
    it 'routes POST add_note properly' do
      expect(post: path + '/add_note').to route_to(
        controller: ctrl,
        action: 'add_note',
        locale: 'en')
    end

    it 'routes POST noteable_object_selector properly' do
      expect(post: path + '/noteable_object_selector').to route_to(
        controller: ctrl,
        action: 'noteable_object_selector',
        locale: 'en')
    end

    it 'routes GET new_update_groupings properly' do
      expect(get: path + '/new_update_groupings').to route_to(
        controller: ctrl,
        action: 'new_update_groupings',
        locale: 'en')
    end

    it 'routes POST new_update_groupings properly' do
      expect(post: path + '/new_update_groupings').to route_to(
        controller: ctrl,
        action: 'new_update_groupings',
        locale: 'en')
    end

    it 'routes GET notes_dialog properly' do
      expect(get: path + '/notes_dialog').to route_to(
        controller: ctrl,
        action: 'notes_dialog',
        locale: 'en' )
    end
  end
  # end notes collection route tests

  context 'member' do
    it 'routes GET student_interface properly' do
      expect(get: path + '/student_interface').to route_to(
        controller: ctrl,
        action: 'show',
        id: 'student_interface',
        locale: 'en')
    end

    it 'routes POST grades properly' do
      expect(post: path + '/1/grades').to route_to(
        controller: ctrl,
        action: 'grades',
        id: '1',
        locale: 'en')
    end
  end
  # end notes member route tests
end
# end notes route tests

# start annotation collection route tests
context 'annotation collection' do
  let(:path) { '/en/annotations' }
  let(:ctrl) { 'annotations' }

  it 'routes POST add_existing_annotation properly' do
    expect(post: path + '/add_existing_annotation').to route_to(
      controller: ctrl,
      action: 'add_existing_annotation',
      locale: 'en')
  end
end
# end annotation route tests

# start student collection route tests
context 'students collection' do
  let(:path) { '/en/students' }
  let(:ctrl) { 'students' }

  it 'routes PATCH bulk_modify properly' do
    expect(patch: path + '/bulk_modify').to route_to(
      controller: ctrl,
      action: 'bulk_modify',
      locale: 'en')
  end

  it 'routes GET manage properly' do
    expect(get: path + '/manage').to route_to(
      controller: ctrl,
      action: 'manage',
      locale: 'en')
  end

  it 'routes GET add_new_section properly' do
    expect(get: path + '/add_new_section').to route_to(
      controller: ctrl,
      action: 'add_new_section',
      locale: 'en')
  end

  it 'routes GET download properly' do
    expect(get: path + '/download').to route_to(
      controller: ctrl,
      action: 'download',
      locale: 'en')
  end

  it 'routes POST upload properly' do
    expect(post: path + '/upload').to route_to(
      controller: ctrl,
      action: 'upload',
      locale: 'en')
  end
end
# end students collection route tests

# start tas collection route tests
context 'tas collection' do
  let(:path) { '/en/tas' }
  let(:ctrl) { 'tas' }

  it 'routes POST upload properly' do
    expect(post: path + '/upload').to route_to(
      controller: ctrl,
      action: 'upload',
      locale: 'en')
  end

  it 'routes GET download properly' do
    expect(get: path + '/download').to route_to(
      controller: ctrl,
      action: 'download',
      locale: 'en')
  end
end
# end tas collection route tests

# start main route tests
context 'main' do
  let(:path) { '/en/main' }
  let(:ctrl) { 'main' }

  context 'collection' do
    it 'routes GET logout properly' do
      expect(post: path + '/logout').to route_to(
        controller: ctrl,
        action: 'logout',
        locale: 'en')
    end

    it 'routes GET about properly' do
      expect(get: path + '/about').to route_to(
        controller: ctrl,
        action: 'about',
        locale: 'en')
    end

    it 'routes POST login_as properly' do
      expect(post: path + '/login_as').to route_to(
        controller: ctrl,
        action: 'login_as',
        locale: 'en')
    end

    it 'routes GET role_switch properly' do
      expect(get: path + '/role_switch').to route_to(
        controller: ctrl,
        action: 'role_switch',
        locale: 'en')
    end

    it 'routes GET clear_role_switch_session properly' do
      expect(get: path + '/clear_role_switch_session').to route_to(
        controller: ctrl,
        action: 'clear_role_switch_session',
        locale: 'en')
    end

    it 'routes POST reset_api_key properly' do
      expect(post: path + '/reset_api_key').to route_to(
        controller: ctrl,
        action: 'reset_api_key',
        locale: 'en')
    end
  end
  # end main collection route tests
  it 'routes GET index properly' do
    expect(get: path + '/index').to route_to(
      controller: ctrl,
      action: 'show',
      id: 'index',
      locale: 'en')
  end

  it 'routes GET about properly' do
    expect(get: path + '/about').to route_to(
      controller: ctrl,
      action: 'about',
      locale: 'en')
  end

  it 'routes GET logout properly' do
    expect(post: path + '/logout').to route_to(
      controller: ctrl,
      action: 'logout',
      locale: 'en')
  end
end
# end main route tests
