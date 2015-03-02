# referensed from bug664-1.patch
# https://gist.github.com/benjaminvialle/4055208
require 'spec_helper'

describe 'Routing to main page', :type => :routing do
  
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
  
  #it 'routes PUT update correctly' do
  # expect(post: path).to route_to(
  #   controller: ctrl,
  #   action: 'update',
  #   id: admin.id.to_s,
  #   locale: 'en')
  #end
  
  it 'routes DELETE destroy correctly' do
    expect(delete: path + '/' + admin.id.to_s).to route_to(
      controller: ctrl,
      action: 'destroy',
      id: admin.id.to_s,
      locale: 'en')
  end
  
  #it 'routes POST populate on a collection correctly' do
  # expect(post: path + '/populate').to route_to(
  #   controller: ctrl,
  #   action: 'populate',
  #   locale: 'en')
  #end
end
# end Admin route tests

# start Assignment route tests
describe 'An Assignment' do
  
  let(:assignment) { create(:assignment) }
  let(:path) { '/en/assignments' }
  let(:ctrl) { 'assignments' }
  
  # start Assignment collection route tests
  context 'collection' do
    
    it 'routes GET download_csv_grades_report properly' do
      expect(get: path + '/download_csv_grades_report').to route_to(
        controller: ctrl,
        action: 'download_csv_grades_report',
        locale: 'en')
    end
    
    it 'routes GET update_group_properties_on_persist properly' do
      expect(get: path + '/update_group_properties_on_persist').to route_to(
        controller: ctrl,
        action: 'show',
        id: 'update_group_properties_on_persist',
        locale: 'en')
    end
    
    it 'routes GET delete_rejected properly' do
      expect(get: path + '/delete_rejected').to route_to(
        controller: ctrl,
        action: 'delete_rejected',
        locale: 'en')
    end
    
    it 'routes POST update_collected_submissions' do
      expect(post: path + '/update_collected_submissions').to route_to(
        controller: ctrl,
        action: 'update_collected_submissions',
        locale: 'en')
    end
  end
  # end Assignment collection route tests
  
  # start Assignment member route tests
  context 'member' do
    
    it 'routs GET refresh_graph properly' do
      expect(get: path + '/' + assignment.id.to_s + '/refresh_graph').to route_to(
        controller: ctrl,
        action: 'refresh_graph',
        id: assignment.id.to_s,
        locale: 'en')
    end
    
    it 'routes GET student_interface properly' do
      expect(get: path + '/' + assignment.id.to_s + '/student_interface').to route_to(
        controller: ctrl,
        action: 'student_interface',
        id: assignment.id.to_s,
        locale: 'en')
    end
    
    it 'routes GET update_group_properties_on_persist properly' do
      expect(get: path + '/' + assignment.id.to_s + '/update_group_properties_on_persist').to route_to(
        controller: ctrl,
        action: 'update_group_properties_on_persist',
        id: assignment.id.to_s,
        locale: 'en')
    end
    
    it 'routes POST invite_member properly' do
      expect(post: path + '/' + assignment.id.to_s + '/invite_member').to route_to(
        controller: ctrl,
        action: 'invite_member',
        id: assignment.id.to_s,
        locale: 'en')
    end
    
    it 'routes GET creategroup properly' do
      expect(get: path + '/' + assignment.id.to_s + '/creategroup').to route_to(
        controller: ctrl,
        action: 'creategroup',
        id: assignment.id.to_s,
        locale: 'en')
    end
    
    it 'routes GET join_group properly' do
      expect(get: path + '/' + assignment.id.to_s + '/join_group').to route_to(
        controller: ctrl,
        action: 'join_group',
        id: assignment.id.to_s,
        locale: 'en')
    end
    
    it 'routes GET deletegroup properly' do
      expect(get: path + '/' + assignment.id.to_s + '/deletegroup').to route_to(
        controller: ctrl,
        action: 'deletegroup',
        id: assignment.id.to_s,
        locale: 'en')
    end
    
    it 'routes GET decline_invitation properly' do
      expect(get: path + '/' + assignment.id.to_s + '/decline_invitation').to route_to(
        controller: ctrl,
        action: 'decline_invitation',
        id: assignment.id.to_s,
        locale: 'en')
    end
    
    #it 'routes GET disinvite_member properly' do
    #  expect(get: path + '/' + assignment.id.to_s + '/disinvite_member').to route_to(
    #    controller: ctrl,
    #   action: 'disinvite_member',
    #   id: assignment.id.to_s,
    #   locale: 'en')
    #end
    
    it 'routes GET render_test_result properly' do
      expect(get: path + '/' + assignment.id.to_s + '/render_test_result').to route_to(
        controller: ctrl,
        action: 'render_test_result',
        id: assignment.id.to_s,
        locale: 'en')
    end
  end
  # end Assignment member route tests
  
  # start Assignment's rubrics route tests
  context 's rubrics' do
    
    let(:rubric_path) { path + '/' + assignment.id.to_s + '/rubrics' }
    let(:rubric_ctrl) { 'rubrics' }
    
    # start assignment rubric member route tests
    context 'member' do
      it 'routes DELETE destroy properly' do
        expect(delete: rubric_path + '/1').to route_to(
          controller: rubric_ctrl,
          action: 'destroy',
          id: '1',
          assignment_id: assignment.id.to_s,
          locale: 'en')

      end
    end
    # end assignment rubric member route tests
    
    # start assignment rubric collection route tests
    context 'collection' do
      it 'routes POST update_positions properly' do
        expect(post: rubric_path + '/update_positions').to route_to(
          controller: rubric_ctrl,
          action: 'update_positions',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end
      it 'routes POST csv_upload properly' do
        expect(post: rubric_path + '/csv_upload').to route_to(
          controller: rubric_ctrl,
          action: 'csv_upload',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end
      it 'routes POST yml_upload properly' do
        expect(post: rubric_path + '/yml_upload').to route_to(
          controller: rubric_ctrl,
          action: 'yml_upload',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end
      it 'routes GET download_csv properly' do
        expect(get: rubric_path + '/download_csv').to route_to(
          controller: rubric_ctrl,
          action: 'download_csv',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end
      it 'routes GET download_yml properly' do
        expect(get: rubric_path + '/download_yml').to route_to(
          controller: rubric_ctrl,
          action: 'download_yml',
          assignment_id: assignment.id.to_s,
          locale: 'en')
      end
    end
    # end assignment rubric collection route tests
  # end Assignment's rubrics route tests
    
  # start assignment flexible criteria route tests
  context 's flexible_criteria' do
    
    context 'collection' do
      
      let(:criter_path) { path + '/' + assignment.id.to_s + '/flexible_criteria' }
      let(:criter_ctrl) { 'flexible_criteria' }
      
        it 'routes POST upload properly' do
          expect(post: criter_path + '/upload').to route_to(
            controller: criter_ctrl,
            action: 'upload',
            assignment_id: assignment.id.to_s,
            locale: 'en')
        end
        
        it 'routes GET show id: update_positions' do
          expect(get: criter_path + '/update_positions').to route_to(
            controller: criter_ctrl,
            action: 'show',
            id: 'update_positions',
            assignment_id: assignment.id.to_s,
            locale: 'en')
        end
        
        it 'routes GET show id: move_criterion' do
          expect(get: criter_path + '/move_criterion').to route_to(
            controller: criter_ctrl,
            action: 'show',
            id: 'move_criterion',
            assignment_id: assignment.id.to_s,
            locale: 'en')
        end
        
        it 'routes GET download properly' do
          expect(get: criter_path + '/download').to route_to(
            controller: criter_ctrl,
            action: 'download',
            assignment_id: assignment.id.to_s,
            locale: 'en')
        end
      end
    end
    # end assignment flexible criteria route tests
    
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
            action: 'update',
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
        
        it 'routes GET move_criterion properly' do
          expect(get: autom_path + '/move_criterion').to route_to(
            controller: autom_ctrl,
            action: 'show',
            id: 'move_criterion',
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
        
        it 'routes POST rename_group properly' do
         expect(post: group_path + '/' + group.id.to_s + '/rename_group').to route_to(
           controller: group_ctrl,
           action: 'rename_group',
           id: group.id.to_s,
           assignment_id: assignment.id.to_s,
           locale: 'en')
        end
        
        it 'routes GET rename_group_dialog properly' do
          expect(get: group_path + '/' + group.id.to_s + '/rename_group_dialog').to route_to(
            controller: group_ctrl,
            action: 'rename_group_dialog',
            id: group.id.to_s,
            assignment_id: assignment.id.to_s,
            locale: 'en')
        end
      end
      
      context 'collection' do
        
        #it 'routes POST populate properly' do
        #  expect(post: group_path + '/populate').to route_to(
        #   controller: group_ctrl,
        #   action: 'populate',
        #   assignment_id: assignment.id.to_s,
        #   locale: 'en')
        #end
        
        #it 'routes POST populate_students properly' do
        # expect(post: group_path + '/populate_students').to route_to(
        #   controller: group_ctrl,
        #   action: 'populate_students',
        #   assignment_id: assignment.id.to_s,
        #   locale: 'en')
        #end
        
        it 'routes GET add_group properly' do
          expect(get: group_path + '/add_group').to route_to(
            controller: group_ctrl,
            action: 'add_group',
            assignment_id: assignment.id.to_s,
            locale: 'en')
        end
        
        it 'routes GET use_another_assignment_groups properly' do
          expect(get: group_path + '/use_another_assignment_groups').to route_to(
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
        
        it 'routes POST csv_upload properly' do
          expect(post: group_path + '/csv_upload').to route_to(
            controller: group_ctrl,
            action: 'csv_upload',
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
          expect(get: group_path + '/create_groups_when_students_work_alone').to route_to(
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
      
      it 'routes POST populate_file_manager properly' do
        expect(post: sub_path + '/populate_file_manager').to route_to(
                                                      controller: sub_ctrl,
                                                      action: 'populate_file_manager',
                                                      assignment_id: assignment.id.to_s,
                                                      locale: 'en')
      end
      
      it 'routes GET collect_all_submissions properly' do
        expect(get: sub_path + '/collect_all_submissions').to route_to(
                                                                      controller: sub_ctrl,
                                                                      action: 'collect_all_submissions',
                                                                      assignment_id: assignment.id.to_s,
                                                                      locale: 'en')
      end
      
      it 'routes GET download_simple_csv_report properly' do
        expect(get: sub_path + '/download_simple_csv_report').to route_to(
                                                                       controller: sub_ctrl,
                                                                       action: 'download_simple_csv_report',
                                                                       assignment_id: assignment.id.to_s,
                                                                       locale: 'en')
     end
      
    end
  end
  end
  
  
end
# end Assignment route tests
