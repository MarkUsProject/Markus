require 'spec_helper'

describe GroupsController do
  describe 'administrator access' do
    let(:grouping) { create(:grouping) }
    let(:assignment) { grouping.assignment }


    before :each do
      # Authenticate user is not timed out, and has administrator rights.
      allow(controller).to receive(:session_expired?).and_return(false)
      allow(controller).to receive(:logged_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(build(:admin))

      allow(Assignment).to receive(:find).and_return(assignment)
    end

    describe '#note_message'

    describe 'GET #new' do
      context 'when no group name is specified' do
        it 'adds a new group to assignment' do
          expect(assignment).to receive(:add_group)
            .with(nil)
            .and_return(grouping)
          get :new, assignment_id: assignment
        end
      end

      context 'when a group name is specified' do
        let(:group_name) { 'g2avatar' }

        context 'when group creation successful' do
          it 'creates a new group with specified name' do
            expect(assignment).to receive(:add_group)
              .with(group_name)
              .and_return(grouping)
            get :new, assignment_id: assignment, new_group_name: group_name
          end
        end

        context 'when group creation unsuccessful' do
          before :each do
            allow(assignment).to receive(:add_group)
              .with(group_name)
              .and_raise('Group #{group_name} already exists')

            get :new, assignment_id: assignment, new_group_name: group_name
          end

          it 'assigns the error message to flash[:error]' do
            expect(flash[:error]).to eq('Group #{group_name} already exists')
          end
        end
      end
    end

    describe 'DELETE #remove_group' do
      before :each do
        allow(Grouping).to receive(:find).and_return(grouping)
      end

      context 'when grouping has no submissions' do
        before :each do
          allow(grouping).to receive(:delete_grouping)
          allow(grouping).to receive(:has_submission?).and_return(false)

          delete :remove_group, grouping_id: grouping, assignment_id: assignment
        end

        it 'assigns the requested grouping\'s assignment to @assignment' do
          expect(assigns(:assignment)).to eq(assignment)
        end

        it 'assigns empty array to @errors' do
          expect(assigns(:errors)).to match_array([])
        end

        it 'populates @removed_groupings with deleted groupings' do
          expect(assigns(:removed_groupings)).to match_array([grouping])
        end

        it 'calls grouping.has_submission?' do
          expect(grouping).to receive(:has_submission?).and_return(false)
          delete :remove_group, grouping_id: grouping, assignment_id: assignment
        end

        it 'calls grouping.delete_groupings' do
          expect(grouping).to receive(:delete_grouping)
          delete :remove_group, grouping_id: grouping, assignment_id: assignment
        end
      end

      context 'when grouping has submissions' do
        before :each do
          allow(grouping).to receive(:has_submission?).and_return(true)

          delete :remove_group, grouping_id: grouping, assignment_id: assignment
        end

        it 'assigns the requested grouping\'s assignment to @assignment' do
          expect(assigns(:assignment)).to eq(assignment)
        end

        it 'populates @errors with group_name of grouping\'s group' do
          expect(assigns(:errors)).to match_array([grouping.group.group_name])
        end

        it 'assigns empty array to @removed_groupings' do
          expect(assigns(:removed_groupings)).to match_array([])
        end

        it 'calls grouping.has_submission?' do
          expect(grouping).to receive(:has_submission?).and_return(true)
          delete :remove_group, grouping_id: grouping, assignment_id: assignment
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
        get :index, assignment_id: assignment
      end

      it 'assigns the requested assignment to @assignment' do
        expect(assigns(:assignment)).to eq(assignment)
      end

      it 'renders the :index template' do
        expect(response).to render_template(:index)
      end
    end

    context 'CSV_Uploads' do
      before :each do
        # We need to mock the rack file to return its content when
        # the '.read' method is called to simulate the behaviour of
        # the http uploaded file
        @file_good = fixture_file_upload(
            'files/groups/form_good.csv', 'text/csv')
        allow(@file_good).to receive(:read).and_return(
            File.read(fixture_file_upload(
                          'files/groups/form_good.csv',
                          'text/csv')))

        @file_invalid_column = fixture_file_upload(
            'files/groups/form_invalid_column.csv', 'text/csv')
        allow(@file_invalid_column).to receive(:read).and_return(
            File.read(fixture_file_upload(
                          'files/groups/form_invalid_column.csv',
                          'text/csv')))

        @file_bad_csv = fixture_file_upload(
            'files/bad_csv.csv', 'text/xls')
        allow(@file_bad_csv).to receive(:read).and_return(
            File.read(fixture_file_upload('files/bad_csv.csv', 'text/csv')))

        @file_wrong_format = fixture_file_upload(
            'files/wrong_csv_format.xls', 'text/xls')
        allow(@file_wrong_format).to receive(:read).and_return(
            File.read(fixture_file_upload(
                          'files/wrong_csv_format.xls', 'text/csv')))

        # Setup for SubversionRepository
        allow(MarkusConfigurator).to receive(:markus_config_repository_type).and_return('svn')

        @assignment = create(:assignment, :allow_web_submits => true,
                     :group_max => 1, :group_min => 1)

        #Create students corresponding to the file_good
        @student_user_names = %w(c8shosta c5bennet)
        @student_user_names.each do |name|
          create(:user, user_name: name, type: 'Student')
        end
      end

      it 'accepts a valid file' do
        post :csv_upload,
             assignment_id: @assignment.id,
             group: {grouplist: @file_good}

        expect(response.status).to eq(302)
        expect(flash[:error]).to be_nil
        expect(flash[:success])
            .to eq(I18n.t('csv.groups_added_msg',
                          number_groups: 1,
                          number_lines: 0))
        expect(response).to redirect_to(action: 'index')

        expect(Group.where(group_name: 'group3').take['repo_name']).
                to eq('group_0003')

        #remove the generated repo so repeated test runs function properly
        FileUtils.rm_r(
            File.join(::Rails.root.to_s, 'data/test/repos/group_0003', '/'),
            :force => true)

      end

      it 'does not accept files with invalid columns' do
        post :csv_upload,
             assignment_id: @assignment.id,
             group: {grouplist: @file_invalid_column}

        expect(response.status).to eq(302)
        expect(flash[:error]).to_not be_empty
        expect(response).to redirect_to(action: 'index')
      end

      it 'does not accept fileless submission' do
        post :csv_upload,
             assignment_id: @assignment.id

        expect(response.status).to eq(302)
        expect(flash[:error]).to_not be_empty
        expect(response).to redirect_to(action: 'index')
      end

      it 'does not accept a non-csv file with .csv extension' do
        post :csv_upload,
             assignment_id: @assignment.id,
             group: {grouplist: @file_bad_csv}

        expect(response.status).to eq(302)
        expect(flash[:error]).to_not be_empty
        expect(response).to redirect_to(action: 'index')
      end

      it 'does not accept a .xls file' do
        post :csv_upload,
             assignment_id: @assignment.id,
             group: {grouplist:  @file_wrong_format}


        expect(response.status).to eq(302)
        expect(flash[:error]).to_not be_empty
        expect(response).to redirect_to(action: 'index')
      end
    end

    describe '#download_grouplist'
    describe '#use_another_assignment_groups'
    describe '#global_actions'
    describe '#invalidate_groupings'
    describe '#validate_groupings'
    describe '#delete_groupings'
    describe '#add_members'
    describe '#add_member'
    describe '#remove_members'
    describe '#remove_member'
  end
end
