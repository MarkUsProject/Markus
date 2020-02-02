describe GroupsHelper do
  include ApplicationHelper
  include GroupsHelper

  let(:assignment) { create :assignment, assignment_properties_attributes: { group_min: 1, group_max: 2 } }
  let(:students) { create_list :student, 3 }

  context '#validate_csv_upload_file' do
    shared_examples 'validate_csv' do |valid, suppress_flash|
      it "should#{valid ? '' : ' not'} be valid" do
        expect(validate_csv_upload_file(assignment, @data)).to eq valid
      end

      unless suppress_flash
        if valid
          it 'should not flash any errors' do
            validate_csv_upload_file assignment, @data
            expect(flash.now[:error]).to be_blank
          end
        else
          it 'should flash the errors' do
            validate_csv_upload_file assignment, @data
            expect(flash.now[:error]).not_to be_blank
          end
        end
      end
    end

    context 'with simple valid data' do
      before :each do
        @data = [['group1', 'group1', students.first.user_name]]
      end
      include_examples 'validate_csv', true, false
    end

    context 'with multiple row valid data' do
      before :each do
        @data = [['group1', 'group1', students.first.user_name],
                 ['group2', 'group2', students.second.user_name]]
      end
      include_examples 'validate_csv', true, false
    end

    context 'with an invalid cell' do
      before :each do
        @data = [['group1', 'group1', '']]
      end
      include_examples 'validate_csv', false, false
    end

    context 'with duplicate group names' do
      before :each do
        @data = [['group1', 'group1', students.first.user_name],
                 ['group1', 'group2', students.second.user_name]]
      end
      include_examples 'validate_csv', false, false
    end

    context 'with duplicate repo names' do
      before :each do
        @data = [['group1', 'group1', students.first.user_name],
                 ['group2', 'group1', students.second.user_name]]
      end
      include_examples 'validate_csv', false, false
    end

    context 'with duplicate members in the same group' do
      before :each do
        @data = [['group1', 'group1', students.first.user_name, students.first.user_name],
                 ['group2', 'group2', students.second.user_name]]
      end
      include_examples 'validate_csv', false, false
    end

    context 'with duplicate members in different groups' do
      before :each do
        @data = [['group1', 'group1', students.first.user_name],
                 ['group2', 'group2', students.second.user_name, students.first.user_name]]
      end
      include_examples 'validate_csv', false, false
    end

    context 'with a group that already exists with a different repo name' do
      before :each do
        @data = [['group1', 'group1', students.first.user_name]]
        create :group, group_name: 'group1', repo_name: 'group2'
      end
      after :each do
        destroy_repos
      end
      include_examples 'validate_csv', false, false
    end

    context 'with a member that is already in a grouping for that assignment' do
      before :each do
        @data = [['group1', 'group1', students.first.user_name]]
        group = create :group, group_name: 'group2', repo_name: 'group2'
        create :grouping_with_inviter, group: group, inviter: students.first, assignment: assignment
      end
      after :each do
        destroy_repos
      end
      include_examples 'validate_csv', false, false
    end

    context 'with a group that already exists with different memberships' do
      before :each do
        @data = [['group1', 'group1', students.first.user_name, students.second.user_name]]
        group = create :group, group_name: 'group1', repo_name: 'group1'
        other_assignment = create :assignment
        create :grouping_with_inviter, group: group, inviter: students.first, assignment: other_assignment
      end
      after :each do
        destroy_repos
      end
      include_examples 'validate_csv', false, false
    end

    context 'with a group that already exists with the same memberships' do
      before :each do
        @data = [['group1', 'group1', students.first.user_name]]
        group = create :group, group_name: 'group1', repo_name: 'group1'
        other_assignment = create :assignment
        create :grouping_with_inviter, group: group, inviter: students.first, assignment: other_assignment
      end
      after :each do
        destroy_repos
      end
      include_examples 'validate_csv', true, false
    end

    context 'with a member that does not exist' do
      before :each do
        @data = [%w[group1 group1 ghost_student]]
      end
      include_examples 'validate_csv', false, false
    end
  end
end
