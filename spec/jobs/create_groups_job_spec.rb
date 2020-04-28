describe CreateGroupsJob do
  let(:assignment) { create :assignment }
  let(:student1) { create :student }
  let(:student2) { create :student }

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
        Group.find_by_group_name('group1').access_repo do |repo|
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
    before :each do
      @data = [['group1', 'group_0001', student1.user_name, student2.user_name]]
    end

    include_examples 'create objects', 1, 1, 2
  end

  context 'when creating multiple group from scratch' do
    before :each do
      @data = [['group1', 'group_0001', student1.user_name],
               ['group2', 'group_0002', student2.user_name]]
    end

    include_examples 'create objects', 2, 2, 2
  end

  context 'when creating one good and one bad group' do
    context 'when the bad one is first' do
      before :each do
        @data = [['group1', 'group_0001', student1.user_name + 'bad_padding'],
                 ['group2', 'group_0002', student2.user_name]]
      end

      include_examples 'create objects', 0, 0, 0
    end
    context 'when the bad one is not first' do
      before :each do
        @data = [['group1', 'group_0001', student1.user_name],
                 ['group2', 'group_0002', student2.user_name + 'bad_padding']]
      end

      include_examples 'create objects', 0, 0, 0
    end
  end

  context 'where the group already exists' do
    let(:group) { create :group }

    context 'and the grouping already exists for that assignment' do
      it 'should not create a new grouping' do
        create :grouping_with_inviter, group: group, assignment: assignment, inviter: student1
        data = [[group.group_name, group.repo_name, student1.user_name]]
        expect { CreateGroupsJob.perform_now(assignment, data) }.not_to(change { Grouping.count })
      end
    end

    context 'and the grouping already exists for another assignment' do
      context 'and the repo name and membership is the same' do
        it 'should create a new grouping' do
          create :grouping_with_inviter, group: group, assignment: assignment, inviter: student1
          data = [[group.group_name, group.repo_name, student1.user_name]]
          expect { CreateGroupsJob.perform_now(create(:assignment), data) }.to change { Grouping.count }.by 1
        end
      end

      context 'and the membership is different' do
        it 'should not create a new grouping' do
          create :grouping_with_inviter, group: group, assignment: assignment, inviter: student1
          data = [[group.group_name, group.repo_name, student1.user_name, student2.user_name]]
          expect { CreateGroupsJob.perform_now(create(:assignment), data) }.not_to(change { Grouping.count })
        end
      end

      context 'and the repo_name is different and already exists' do
        it 'should not create a new grouping' do
          create :grouping_with_inviter, group: group, assignment: assignment, inviter: student1
          data = [[group.group_name, create(:group).repo_name, student1.user_name]]
          expect { CreateGroupsJob.perform_now(create(:assignment), data) }.not_to(change { Grouping.count })
        end
      end
    end
  end
end
