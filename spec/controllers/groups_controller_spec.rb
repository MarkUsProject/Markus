describe GroupsController do
  let(:grouping) { create(:grouping) }
  let(:assignment) { grouping.assignment }

  describe 'administrator access' do
    before :each do
      # Authenticate user is not timed out, and has administrator rights.
      allow(controller).to receive(:session_expired?).and_return(false)
      allow(controller).to receive(:logged_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(build(:admin))
    end

    describe 'GET #new' do
      before :each do
        allow(Assignment).to receive(:find).and_return(assignment)
      end

      context 'when no group name is specified' do
        it 'adds a new group to assignment' do
          expect(assignment).to receive(:add_group)
                                  .with(nil)
                                  .and_return(grouping)
          get :new, params: { assignment_id: assignment }
        end
      end

      context 'when a group name is specified' do
        let(:group_name) { 'g2avatar' }

        context 'when group creation successful' do
          it 'creates a new group with specified name' do
            expect(assignment).to receive(:add_group)
                                    .with(group_name)
                                    .and_return(grouping)
            get :new, params: { assignment_id: assignment, new_group_name: group_name }
          end
        end

        context 'when group creation unsuccessful' do
          before :each do
            allow(assignment).to receive(:add_group)
                                   .with(group_name)
                                   .and_raise('Group #{group_name} already exists')

            get :new, params: { assignment_id: assignment, new_group_name: group_name }
          end

          it 'assigns the error message to flash[:error]' do
            expect(flash[:error]).to eq('Group #{group_name} already exists')
          end
        end
      end
    end

    describe 'DELETE #remove_group' do
      before :each do
        allow(Grouping).to receive(:where).and_return([grouping])
      end

      context 'when grouping has no submissions' do
        before :each do
          allow(grouping).to receive(:delete_grouping)
          allow(grouping).to receive(:has_submission?).and_return(false)
        end

        it 'assigns empty array to @errors' do
          delete :remove_group, params: { grouping_id: [grouping.id], assignment_id: assignment }
          expect(assigns(:errors)).to match_array([])
        end

        it 'populates @removed_groupings with deleted groupings' do
          delete :remove_group, params: { grouping_id: [grouping.id], assignment_id: assignment }
          expect(assigns(:removed_groupings)).to match_array([grouping])
        end

        it 'calls grouping.has_submission?' do
          expect(grouping).to receive(:has_submission?).and_return(false)
          delete :remove_group, params: { grouping_id: [grouping.id], assignment_id: assignment }
        end

        it 'calls grouping.delete_groupings' do
          expect(grouping).to receive(:delete_grouping)
          delete :remove_group, params: { grouping_id: [grouping.id], assignment_id: assignment }
        end

        it 'should attempt to update permissions file' do
          expect(Repository.get_class).to receive(:update_permissions_after)
          delete :remove_group, params: { grouping_id: [grouping.id], assignment_id: assignment }
        end
      end

      context 'when grouping has submissions' do
        before :each do
          allow(grouping).to receive(:has_submission?).and_return(true)

          delete :remove_group, params: { grouping_id: [grouping.id], assignment_id: assignment }
        end

        it 'populates @errors with group_name of grouping\'s group' do
          expect(assigns(:errors)).to match_array([grouping.group.group_name])
        end

        it 'assigns empty array to @removed_groupings' do
          expect(assigns(:removed_groupings)).to match_array([])
        end

        it 'calls grouping.has_submission?' do
          expect(grouping).to receive(:has_submission?).and_return(true)
          delete :remove_group, params: { grouping_id: [grouping.id], assignment_id: assignment }
        end

        it 'should attempt to update permissions file' do
          expect(Repository.get_class).to receive(:update_permissions_after)
          delete :remove_group, params: { grouping_id: [grouping.id], assignment_id: assignment }
        end
      end
    end

    describe '#rename_group'
    describe '#valid_grouping'
    describe '#invalid_grouping'
    describe '#populate'
    describe '#populate_students'

    describe 'GET #index' do
      before :each do
        allow(Assignment).to receive(:find).and_return(assignment)
        get :index, params: { assignment_id: assignment }
      end

      it 'assigns the requested assignment to @assignment' do
        expect(assigns(:assignment)).to eq(assignment)
      end

      it 'renders the :index template' do
        expect(response).to render_template(:index)
      end
    end

    describe '#upload', keep_memory_repos: true do
      before :all do
        # remove a generated repo so repeated test runs function properly
        FileUtils.rm_r(
          File.join(::Rails.root.to_s, 'data/test/repos/group_0001', '/'),
          force: true)
      end

      before :each do
        # since the git
        allow(Repository.get_class).to receive(:purge_all).and_return nil

        # Setup for Git Repository
        allow(MarkusConfigurator)
          .to receive(:markus_config_repository_type).and_return('git')

        @assignment = create(:assignment)

        # Create students corresponding to the file_good
        @student_user_names = %w(c8shosta c5bennet)
        @student_user_names.each do |name|
          create(:user, user_name: name, type: 'Student')
        end
      end

      include_examples 'a controller supporting upload' do
        let(:params) { { assignment_id: @assignment.id } }
      end

      it 'accepts a valid file' do
        ActiveJob::Base.queue_adapter = :test
        expect do
          post :upload, params: {
            assignment_id: @assignment.id,
            upload_file: fixture_file_upload('files/groups/form_good.csv', 'text/csv')
          }
        end.to have_enqueued_job(CreateGroupsJob)
        expect(response.status).to eq(302)
        expect(flash[:error]).to be_blank
        expect(response).to redirect_to(action: 'index')
      end

      it 'does not accept files with invalid columns' do
        post :upload, params: {
          assignment_id: @assignment.id,
          upload_file: fixture_file_upload('files/groups/form_invalid_column.csv', 'text/csv')
        }

        expect(response.status).to eq(302)
        expect(flash[:error]).to_not be_blank
        expect(response).to redirect_to(action: 'index')
      end
    end

    describe '#download_grouplist' do
      let(:csv_options) do
        {
          type: 'text/csv',
          filename: "#{@assignment.short_identifier}_group_list.csv",
          disposition: 'attachment'
        }
      end

      before :each do
        @assignment = FactoryBot.create(:assignment)

        @group = FactoryBot.create(:group)

        @student1 = create(:student, user_name: 'c8shosta')
        @student2 = create(:student, user_name: 'c5bennet')

        grouping = Grouping.new(assignment: @assignment, group: @group)
        grouping.save

        grouping.add_member(@student1, StudentMembership::STATUSES[:inviter])
        grouping.add_member(@student2, StudentMembership::STATUSES[:accepted])

        @ta_name = 'c8shacd'
        @ta = create(:ta, user_name: @ta_name)
        # For each grouping for Assignment 1, assign 2 TAs
        @assignment.groupings.each do |grouping|
          grouping.add_tas([@ta])
        end
      end

      it 'responds with appropriate status' do
        get :download_grouplist, params: { assignment_id: @assignment.id }, format: 'csv'
        expect(response.status).to eq(200)
      end

      # parse header object to check for the right disposition
      it 'sets disposition as attachment' do
        get :download_grouplist, params: { assignment_id: @assignment.id }, format: 'csv'
        d = response.header['Content-Disposition'].split.first
        expect(d).to eq 'attachment;'
      end

      it 'expects a call to send_data' do
        csv_data = "#{@group.group_name},#{@group.repo_name}," +
          "#{@student1.user_name},#{@student2.user_name}\n"
        expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
          # to prevent a 'missing template' error
          @controller.head :ok
        }
        get :download_grouplist, params: { assignment_id: @assignment.id }, format: 'csv'
      end

      # parse header object to check for the right content type
      it 'returns text/csv type' do
        get :download_grouplist, params: { assignment_id: @assignment.id }, format: 'csv'
        expect(response.media_type).to eq 'text/csv'
      end

      # parse header object to check for the right file naming convention
      it 'filename passes naming conventions' do
        get :download_grouplist, params: { assignment_id: @assignment.id }, format: 'csv'
        filename = response.header['Content-Disposition']
                           .split[1].split('"').second
        expect(filename).to eq "#{@assignment.short_identifier}_group_list.csv"
      end
    end

    describe '#use_another_assignment_groups'
    describe '#global_actions' do
      describe 'remove_members' do
        let(:grouping) { create :grouping_with_inviter }
        let(:pending_student) { create :student }
        let(:accepted_student) { create :student }

        before :each do
          create :student_membership, user: pending_student, grouping: grouping
          create :accepted_student_membership, user: accepted_student, grouping: grouping
        end

        it 'should remove an accepted membership' do
          post :global_actions, params: { assignment_id: grouping.assignment.id,
                                          groupings: [grouping.id],
                                          students_to_remove: [accepted_student.id],
                                          global_actions: 'unassign' }
          expect(grouping.memberships).not_to include(accepted_student)
        end

        it 'should remove a pending membership' do
          post :global_actions, params: { assignment_id: grouping.assignment.id,
                                          groupings: [grouping.id],
                                          students_to_remove: [pending_student.id],
                                          global_actions: 'unassign' }
          expect(grouping.memberships).not_to include(pending_student)
        end
      end
    end
    describe '#invalidate_groupings'
    describe '#validate_groupings'
    describe '#delete_groupings'
    describe '#add_members'
    describe '#add_member'
    describe '#remove_members'
    describe '#remove_member'
  end

  describe 'student access' do
    before :each do
      # Authenticate user is not timed out, and has administrator rights.
      allow(controller).to receive(:session_expired?).and_return(false)
      allow(controller).to receive(:logged_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(build(:student))

      @student = create(:student, user_name: 'c9test1')
      @assignment = create(:assignment, student_form_groups: true)
    end

    describe 'POST #create' do
      before :each do
        post_as @student, :create, params: { assignment_id: assignment }
      end

      it 'should respond with redirect' do
        is_expected.to respond_with(:redirect)
      end
    end

    describe 'DELETE #destroy' do
      before :each do
        delete_as @student, :destroy, params: { assignment_id: assignment, id: 1 }
      end

      it 'should respond with success' do
        is_expected.to respond_with(:redirect)
      end
    end
  end
end
