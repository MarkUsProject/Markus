describe CreateGroupsJob do
  let(:assignment) { create :assignment }
  let(:student1) { create :student }
  let(:student2) { create :student }
  let(:group_name) { 'group1' }

  after :each do
    destroy_repos
  end

  shared_examples 'create objects' do |groups_diff, groupings_diff, membership_diff|
    it 'should attempt to update permissions file' do
      expect(Repository.get_class).to receive(:update_permissions_after)
      CreateGroupsJob.perform_now(assignment, @data)
    end

    it "should create #{groups_diff} new group(s)" do
      expect { CreateGroupsJob.perform_now(assignment, @data) }.to change { Group.count }.by groups_diff
    end

    it "should create #{groupings_diff} new grouping(s)" do
      expect { CreateGroupsJob.perform_now(assignment, @data) }.to change { Grouping.count }.by groupings_diff
    end

    it "should create #{membership_diff} new student membership(s)" do
      expect { CreateGroupsJob.perform_now(assignment, @data) }.to change { StudentMembership.count }.by membership_diff
    end

    if groups_diff.positive?
      it 'should create a new repo' do
        CreateGroupsJob.perform_now(assignment, @data)
        Group.find_by_group_name(group_name).access_repo do |repo|
          expect(repo).to be_an_instance_of(MemoryRepository)
        end
      end
    end
  end

  context 'when running as a background job' do
    let(:job_args) { [assignment, [['group1', 'group_0001', student1.user_name, student2.user_name]]] }
    include_examples 'background job'
  end

  context 'when creating one group from scratch' do
    context 'and group limit is set to 1' do
      context 'and there are two students specified for the group' do
        before :each do
          @data = [['group1', student1.user_name, student2.user_name]]
        end

        include_examples 'create objects', 0, 0, 0
      end

      context 'and there is one student specified for the group' do
        let(:group_name) { student1.user_name }
        before :each do
          @data = [[student1.user_name, student1.user_name]]
        end

        include_examples 'create objects', 1, 1, 1

        it 'creates an individual repository for the student' do
          CreateGroupsJob.perform_now(assignment, @data)
          expect(Group.find_by(group_name: student1.user_name, repo_name: student1.user_name)).to_not be_nil
        end
      end
    end
    context 'and group limit is set to 2' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { group_min: 1, group_max: 2 } }
      before :each do
        @data = [['group1', student1.user_name, student2.user_name]]
      end

      include_examples 'create objects', 1, 1, 2
    end
  end

  context 'when creating multiple group from scratch' do
    before :each do
      @data = [['group1', student1.user_name],
               ['group2', student2.user_name]]
    end

    include_examples 'create objects', 2, 2, 2
  end

  context 'when creating one good and one bad group' do
    context 'when the bad one is first' do
      before :each do
        @data = [['group2', student1.user_name + 'bad_padding'],
                 ['group1', student2.user_name]]
      end

      include_examples 'create objects', 1, 1, 1
    end
    context 'when the bad one is not first' do
      before :each do
        @data = [['group1', student1.user_name],
                 ['group2', student2.user_name + 'bad_padding']]
      end

      include_examples 'create objects', 1, 1, 1
    end
  end

  context 'where the group already exists' do
    let(:group) { create :group }

    context 'and the grouping already exists for that assignment' do
      it 'should not create a new grouping' do
        create :grouping_with_inviter, group: group, assignment: assignment, inviter: student1
        data = [[group.group_name, student1.user_name]]
        expect { CreateGroupsJob.perform_now(assignment, data) }.not_to(change { Grouping.count })
      end
    end

    context 'and the grouping already exists for another assignment' do
      context 'and the repo name and membership is the same' do
        it 'should create a new grouping' do
          create :grouping_with_inviter, group: group, assignment: assignment, inviter: student1
          data = [[group.group_name, student1.user_name]]
          expect { CreateGroupsJob.perform_now(create(:assignment), data) }.to change { Grouping.count }.by 1
        end
      end

      context 'and the membership is different' do
        it 'should not create a new grouping' do
          create :grouping_with_inviter, group: group, assignment: assignment, inviter: student1
          data = [[group.group_name, student1.user_name, student2.user_name]]
          expect { CreateGroupsJob.perform_now(create(:assignment), data) }.not_to(change { Grouping.count })
        end
      end

      context 'and the assignment does not allow students to work in groups > 1' do
        let(:assignment) { create :assignment, assignment_properties_attributes: { group_min: 1, group_max: 1 } }
        context 'and the repo name is different and the group is named after the inviter' do
          let(:group) { create :group, group_name: group_name, repo_name: 'some_other_repo' }
          before do
            create :grouping_with_inviter, group: group, assignment: assignment, inviter: student1
          end
          context 'and the group name is the same as the inviter user' do
            let(:group_name) { student1.user_name }
            it 'should create a new grouping' do
              data = [[group.group_name, student1.user_name]]
              expect { CreateGroupsJob.perform_now(create(:assignment), data) }.to(change { Grouping.count }.by(1))
            end
            it 'should use the old repo name' do
              data = [[group.group_name, student1.user_name]]
              CreateGroupsJob.perform_now(create(:assignment), data)
              expect(Grouping.joins(:group).pluck(:repo_name)).to contain_exactly('some_other_repo', 'some_other_repo')
            end
          end
        end
      end
    end
  end
end
