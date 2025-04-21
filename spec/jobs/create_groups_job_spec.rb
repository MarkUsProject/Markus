describe CreateGroupsJob do
  let(:assignment) { create(:assignment) }
  let(:student1) { create(:student) }
  let(:student2) { create(:student) }
  let(:group_name) { 'group1' }

  after do
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
        Group.find_by(group_name: group_name).access_repo do |repo|
          expect(repo).to be_an_instance_of(MemoryRepository)
        end
      end

      it 'should create new groups associated to the same course as the assignment' do
        CreateGroupsJob.perform_now(assignment, @data)
        expect(Group.find_by(group_name: group_name).course_id).to eq assignment.course_id
      end
    end
  end

  context 'when running as a background job' do
    let(:job_args) { [assignment, [['group1', 'group_0001', student1.user_name, student2.user_name]]] }

    it_behaves_like 'background job'
  end

  context 'when creating one group from scratch' do
    context 'and group limit is set to 1' do
      context 'and there are two students specified for the group' do
        before do
          @data = [['group1', student1.user_name, student2.user_name]]
        end

        it_behaves_like 'create objects', 0, 0, 0
      end

      context 'and there is one student specified for the group' do
        let(:group_name) { student1.user_name }

        before do
          @data = [[student1.user_name, student1.user_name]]
        end

        it_behaves_like 'create objects', 1, 1, 1

        it 'creates an individual repository for the student' do
          CreateGroupsJob.perform_now(assignment, @data)
          expect(Group.find_by(group_name: student1.user_name, repo_name: student1.user_name)).not_to be_nil
        end
      end
    end

    context 'and group limit is set to 2' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { group_min: 1, group_max: 2 }) }

      before do
        @data = [['group1', student1.user_name, student2.user_name]]
      end

      it_behaves_like 'create objects', 1, 1, 2
    end
  end

  context 'when creating multiple group from scratch' do
    before do
      @data = [['group1', student1.user_name],
               ['group2', student2.user_name]]
    end

    it_behaves_like 'create objects', 2, 2, 2
  end

  context 'when creating one good and one bad group' do
    context 'when the bad one is first' do
      before do
        @data = [['group2', student1.user_name + 'bad_padding'],
                 ['group1', student2.user_name]]
      end

      it_behaves_like 'create objects', 1, 1, 1
    end

    context 'when the bad one is not first' do
      before do
        @data = [['group1', student1.user_name],
                 ['group2', student2.user_name + 'bad_padding']]
      end

      it_behaves_like 'create objects', 1, 1, 1
    end
  end

  context 'where the group already exists' do
    let(:group) { create(:group, course: assignment.course) }

    context 'and the grouping already exists for that assignment' do
      it 'should not create a new grouping' do
        create(:grouping_with_inviter, group: group, assignment: assignment, inviter: student1)
        data = [[group.group_name, student1.user_name]]
        expect { CreateGroupsJob.perform_now(assignment, data) }.not_to(change { Grouping.count })
      end
    end

    context 'and the grouping already exists for another assignment' do
      context 'and the repo name and membership is the same' do
        before { create(:grouping_with_inviter, group: group, assignment: assignment, inviter: student1) }

        context 'and the assignment is in the same course' do
          let(:assignment2) { create(:assignment, course: assignment.course) }

          it 'should create a new grouping' do
            data = [[group.group_name, student1.user_name]]
            expect { CreateGroupsJob.perform_now(assignment2, data) }.to change { Grouping.count }.by 1
          end
        end

        context 'and the assignment is in a different course' do
          skip 'enable this when there is a validation checking if students are in the same course' do
            let(:assignment2) { create(:assignment) }
            it 'should raise a validation error' do
              data = [[group.group_name, student1.user_name]]
              expect { CreateGroupsJob.perform_now(assignment2, data) }.to raise_exception(ActiveRecord::RecordInvalid)
            end
          end
        end
      end

      context 'and the membership is different' do
        before { create(:grouping_with_inviter, group: group, assignment: assignment, inviter: student1) }

        context 'and the assignment is in the same course' do
          let(:assignment2) { create(:assignment, course: assignment.course) }

          it 'should not create a new grouping' do
            data = [[group.group_name, student1.user_name, student2.user_name]]
            expect { CreateGroupsJob.perform_now(assignment2, data) }.not_to(change { Grouping.count })
          end
        end

        context 'and the assignment is in a different course' do
          skip 'enable this when there is a validation checking if students are in the same course' do
            let(:assignment2) { create(:assignment) }
            it 'should raise a validation error' do
              data = [[group.group_name, student1.user_name, student2.user_name]]
              expect { CreateGroupsJob.perform_now(assignment2, data) }.to raise_exception(ActiveRecord::RecordInvalid)
            end
          end
        end
      end

      context 'and the assignment does not allow students to work in groups > 1' do
        let(:assignment) { create(:assignment, assignment_properties_attributes: { group_min: 1, group_max: 1 }) }

        context 'and the repo name is different and the group is named after the inviter' do
          let(:group) do
            create(:group, group_name: group_name, repo_name: 'some_other_repo', course: assignment.course)
          end

          before do
            create(:grouping_with_inviter, group: group, assignment: assignment, inviter: student1)
          end

          context 'and the group name is the same as the inviter user' do
            let(:group_name) { student1.user_name }
            let(:assignment2) { create(:assignment, course: assignment.course) }

            it 'should create a new grouping' do
              data = [[group.group_name, student1.user_name]]
              expect { CreateGroupsJob.perform_now(assignment2, data) }.to(change { Grouping.count }.by(1))
            end

            it 'should use the old repo name' do
              data = [[group.group_name, student1.user_name]]
              CreateGroupsJob.perform_now(assignment2, data)
              expect(Grouping.joins(:group).pluck(:repo_name)).to contain_exactly('some_other_repo', 'some_other_repo')
            end
          end
        end
      end
    end
  end
end
