describe Grouping do
  describe 'associations' do
    subject { create(:grouping) }

    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to have_many(:memberships) }
    it { is_expected.to have_many(:submissions) }
    it { is_expected.to have_many(:notes) }
    it { is_expected.to have_one(:extension).dependent(:destroy) }
    it { is_expected.to have_one(:course) }

    it_behaves_like 'course associations'
    it 'should ensure that tags belong to the same course' do
      subject.tags << create(:tag, assessment: create(:assignment))
      expect(subject).not_to be_valid
    end

    it 'should allow tags that do belong to the same course' do
      subject.tags << create(:tag, assessment: subject.assignment)
      expect(subject).to be_valid
    end

    it 'should allow tags that do not belong to any course' do
      subject.tags << create(:tag)
      expect(subject).to be_valid
    end
  end

  describe 'a default grouping' do
    let(:grouping) { create(:grouping) }

    it 'does not have any ta for marking' do
      expect(grouping.has_ta_for_marking?).to be false
    end

    it 'does not have submissions' do
      expect(grouping.has_submission?).to be false
    end

    it 'does not have submitted files' do
      expect(grouping.has_submitted_files?).to be false
    end

    context 'hidden students' do
      let(:hidden) { create(:student, hidden: true) }

      it 'cannot be invited' do
        grouping.invite(hidden.user.user_name)
        expect(grouping.memberships.count).to eq(0)
      end

      it 'cannot be added' do
        grouping.add_member(hidden)
        expect(grouping.memberships.count).to eq(0)
      end
    end

    it 'displays Empty Group since no students in the group' do
      expect(grouping.get_all_students_in_group).to eq(I18n.t('groups.empty'))
    end

    it 'creates a subdirectory in the repo for the grouping\'s assignment' do
      grouping.group.access_repo do |repo|
        a_dir = grouping.assignment.repository_folder
        expect(repo.get_latest_revision.directories_at_path('/').values.map(&:name)).to include a_dir
      end
    end

    it 'fails to create the grouping if it cannot create the repository folder' do
      mock_repo = instance_double(MemoryRepository)
      allow(MemoryRepository).to receive(:new).and_return(mock_repo)
      allow(mock_repo).to receive(:commit).and_return(false)

      expect { grouping }.to raise_error RuntimeError
    end
  end

  describe 'assigning and unassigning TAs' do
    let!(:assignment) { create(:assignment) }
    let(:grouping) { create(:grouping) }
    let(:groupings) do
      Array.new(4) { create(:grouping, assignment: assignment) }
    end
    let(:tas) { create_list(:ta, 2) }
    let(:grouping_ids) { groupings.map(&:id) }
    let(:ta_ids) { tas.map(&:id) }
    let(:weightings) { Array.new(tas.size) { 1 } }

    describe '.randomly_assign_tas' do
      it 'can randomly bulk assign no TAs to no groupings' do
        expect { Grouping.randomly_assign_tas([], [], [], assignment) }.not_to raise_error
      end

      it 'can randomly bulk assign TAs to no groupings' do
        expect { Grouping.randomly_assign_tas([], ta_ids, [1], assignment) }.not_to raise_error
      end

      it 'can randomly bulk assign no TAs to all groupings' do
        expect { Grouping.randomly_assign_tas(grouping_ids, [], [], assignment) }.not_to raise_error
      end

      it 'can randomly bulk assign TAs to all groupings' do
        Grouping.randomly_assign_tas(grouping_ids, ta_ids, weightings, assignment)

        groupings.each do |grouping|
          grouping.reload
          expect(grouping.tas.size).to eq 1
          expect(tas).to include grouping.tas.first
        end
      end

      it 'can randomly bulk assign TAs with weighting' do
        weightings = [3, 1]
        Grouping.randomly_assign_tas(grouping_ids, ta_ids, weightings, assignment)

        groupings.each do |grouping|
          grouping.reload
          expect(grouping.tas.size).to eq 1
          expect(tas).to include grouping.tas.first
        end
        grouping1 = groupings.select { |grouping| grouping.tas.first == tas.first }
        grouping2 = groupings.select { |grouping| grouping.tas.first == tas.last }
        print(grouping2.length, grouping1.length)
        expect(grouping1.length > grouping2.length).to be(true)
      end

      it 'can randomly bulk assign duplicated TAs to groupings' do
        # The probability of assigning no duplicated TAs after (tas.size + 1)
        # trials is 0.
        (tas.size + 1).times do
          Grouping.randomly_assign_tas(grouping_ids, ta_ids, weightings, assignment)
        end

        ta_set = tas.to_set
        groupings.each do |grouping|
          grouping.reload
          expect(grouping.tas.size).to be_between(1, 2).inclusive
          expect(grouping.tas.to_set).to be_subset(ta_set)
        end
      end

      it 'updates criteria coverage counts after randomly bulk assign TAs' do
        expect(Grouping).to receive(:update_criteria_coverage_counts)
          .with(assignment, match_array(grouping_ids))
        Grouping.randomly_assign_tas(grouping_ids, ta_ids, weightings, assignment)
      end

      it 'updates assigned groups counts after randomly bulk assign TAs' do
        expect(Criterion).to receive(:update_assigned_groups_counts)
          .with(assignment)
        Grouping.randomly_assign_tas(grouping_ids, ta_ids, weightings, assignment)
      end
    end

    describe '.assign_all_tas' do
      it 'can bulk assign no TAs to no groupings' do
        expect { Grouping.assign_all_tas([], [], assignment) }.not_to raise_error
      end

      it 'can bulk assign all TAs to no groupings' do
        expect { Grouping.assign_all_tas([], ta_ids, assignment) }.not_to raise_error
      end

      it 'can bulk assign no TAs to all groupings' do
        expect { Grouping.assign_all_tas(grouping_ids, [], assignment) }.not_to raise_error
      end

      it 'can bulk assign all TAs to all groupings' do
        Grouping.assign_all_tas(grouping_ids, ta_ids, assignment)

        groupings.each do |grouping|
          grouping.reload
          expect(grouping.tas).to match_array(tas)
        end
      end

      it 'can bulk assign duplicated TAs to groupings' do
        Grouping.assign_all_tas(grouping_ids.first, ta_ids, assignment)
        Grouping.assign_all_tas(grouping_ids, ta_ids.first, assignment)

        # First grouping gets all the TAs.
        grouping = groupings.shift
        grouping.reload
        expect(grouping.tas).to match_array(tas)

        # The rest of the groupings gets only the first TA.
        groupings.each do |other_grouping|
          other_grouping.reload
          expect(other_grouping.tas).to eq [tas.first]
        end
      end

      it 'updates criteria coverage counts after bulk assign all TAs' do
        expect(Grouping).to receive(:update_criteria_coverage_counts)
          .with(assignment, match_array(grouping_ids))
        Grouping.assign_all_tas(grouping_ids, ta_ids, assignment)
      end

      it 'updates assigned groups counts after bulk assign all TAs' do
        expect(Criterion).to receive(:update_assigned_groups_counts)
          .with(assignment)
        Grouping.assign_all_tas(grouping_ids, ta_ids, assignment)
      end

      it 'updates repository permissions exactly once after bulk assign TAs' do
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
        Grouping.assign_all_tas([], grouping_ids, assignment)
      end
    end

    describe '.delete_grouping' do
      it 'makes an attempt to update repository permissions when deleting a group' do
        g = groupings
        expect(Repository.get_class).to receive(:update_permissions_after)
        g[0].delete_grouping
      end
    end

    describe '.assign_tas' do
      it 'updates repository permissions exactly once after assigning all TAs' do
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
        Grouping.assign_tas(grouping_ids, ta_ids, assignment) do |grouping_ids, ta_ids|
          grouping_ids.zip(ta_ids.cycle)
        end
      end
    end

    describe '.unassign_tas' do
      it 'can bulk unassign no TAs' do
        expect { Grouping.unassign_tas([], [], assignment) }.not_to raise_error
      end

      it 'can bulk unassign TAs' do
        Grouping.assign_all_tas(grouping_ids, ta_ids, assignment)
        ta_membership_ids = groupings
                            .flat_map { |grouping| grouping.memberships.ids }
        Grouping.unassign_tas(ta_membership_ids, grouping_ids, assignment)

        groupings.each do |grouping|
          grouping.reload
          expect(grouping.tas).to be_empty
        end
      end

      it 'updates criteria coverage counts after bulk unassign TAs' do
        expect(Grouping).to receive(:update_criteria_coverage_counts)
          .with(assignment, match_array(grouping_ids))
        Grouping.unassign_tas([], grouping_ids, assignment)
      end

      it 'updates assigned groups counts after bulk unassign TAs' do
        expect(Criterion).to receive(:update_assigned_groups_counts)
          .with(assignment)
        Grouping.unassign_tas([], grouping_ids, assignment)
      end

      it 'updates repository permissions exactly once after bulk unassign TAs' do
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
        Grouping.unassign_tas([], grouping_ids, assignment)
      end
    end

    describe '#has_ta_for_marking?' do
      it 'returns false when there are no assigned tas' do
        expect(grouping.has_ta_for_marking?).to be false
      end

      it 'returns true when there is an assigned ta' do
        create(:ta_membership, role: tas[0], grouping: grouping)
        expect(grouping.has_ta_for_marking?).to be true
      end
    end
  end

  describe '.update_criteria_coverage_counts' do
    let(:grouping) { create(:grouping) }
    let(:assignment) { grouping.assignment }

    context 'when no grouping IDs are specified' do
      # Verifies the criteria coverage count of +grouping+ is equal to
      # +expected_count+ after updating all the counts.
      def expect_updated_criteria_coverage_count_eq(expected_count)
        Grouping.update_criteria_coverage_counts(assignment)
        grouping.reload
        expect(grouping.criteria_coverage_count).to eq expected_count
      end

      context 'when there are no assigned TAs' do
        it 'updates criteria coverage count to 0' do
          expect_updated_criteria_coverage_count_eq 0
        end
      end

      context 'when there are assigned TAs' do
        let!(:tas) { create_list(:ta, 2) }

        before do
          create_ta_memberships(grouping, tas)
        end

        context 'when there are no assigned criteria' do
          it 'updates criteria coverage count to 0' do
            expect_updated_criteria_coverage_count_eq 0
          end
        end

        context 'when there are assigned criteria' do
          let!(:criteria) do
            # Create more criteria than TAs to verify that irrelevant criteria
            # are not counted. Only `tas.size` number of criteria are assigned
            # TAs.
            Array.new(tas.size + 1) do
              create(:rubric_criterion, assignment: assignment)
            end
          end

          it 'updates criteria coverage count to 0' do
            expect_updated_criteria_coverage_count_eq 0
          end

          context 'when only one is assigned a TA' do
            before do
              create(:criterion_ta_association, criterion: criteria[0], ta: tas[0])
            end

            it 'updates criteria coverage count to 1' do
              expect_updated_criteria_coverage_count_eq 1
            end
          end

          context 'when only one is assigned multiple TAs' do
            before do
              tas.each do |ta|
                create(:criterion_ta_association, criterion: criteria[0], ta: ta)
              end
            end

            it 'updates criteria coverage count to 1' do
              expect_updated_criteria_coverage_count_eq 1
            end
          end

          context 'when `tas.size` are assigned unique TAs' do
            before do
              tas.size.times do |i|
                create(:criterion_ta_association, criterion: criteria[i], ta: tas[i])
              end
            end

            it 'updates criteria coverage count to `tas.size`' do
              expect_updated_criteria_coverage_count_eq tas.size
            end
          end

          context 'when `tas.size` are assigned non-unique TAs' do
            before do
              criteria.take(tas.size).each do |criterion|
                tas.each do |ta|
                  create(:criterion_ta_association, criterion: criterion, ta: ta)
                end
              end
            end

            it 'updates criteria coverage count to `tas.size`' do
              expect_updated_criteria_coverage_count_eq tas.size
            end

            context 'when TAs are also assigned to groups of another assignment' do
              before do
                # Creating a new grouping also creates a new assignment.
                grouping = create(:grouping)
                criterion = create(:rubric_criterion,
                                   assignment: grouping.assignment)
                tas.each do |ta|
                  create(:criterion_ta_association, criterion: criterion, ta: ta)
                end
                create_ta_memberships(grouping, tas)
              end

              it 'updates criteria coverage count to `tas.size`' do
                expect_updated_criteria_coverage_count_eq tas.size
              end
            end
          end
        end
      end
    end

    context 'when grouping IDs are specified' do
      let(:another_grouping) { create(:grouping, assignment: assignment) }
      let(:ta) { create(:ta) }
      let(:criterion) { create(:rubric_criterion, assignment: assignment) }
      let(:criterion2) { create(:rubric_criterion, assignment: assignment) }

      before do
        create_ta_memberships([grouping, another_grouping], ta)
        create(:criterion_ta_association, criterion: criterion, ta: ta)
        create(:criterion_ta_association, criterion: criterion2, ta: ta)

        # Update only `grouping` not `another_grouping`.
        Grouping.update_criteria_coverage_counts(assignment, [grouping.id])
      end

      it 'updates the count for the specified grouping' do
        grouping.reload
        expect(grouping.criteria_coverage_count).to eq 2
      end

      it 'does not update the count for the unspecified grouping' do
        another_grouping.reload
        expect(another_grouping.criteria_coverage_count).to eq 0
      end
    end
  end

  describe 'test tokens' do
    let(:grouping) { create(:grouping) }

    it { is_expected.to validate_presence_of(:test_tokens) }

    context 'when the grouping has 5 test tokens' do
      it 'is valid' do
        grouping.test_tokens = 5
        expect(grouping).to be_valid
      end
    end

    context 'when the grouping has 0 test tokens' do
      it 'is valid' do
        grouping.test_tokens = 0
        expect(grouping).to be_valid
      end
    end

    describe '.decrease_test_tokens' do
      context 'when number of tokens is greater than 0' do
        it 'decreases number of tokens' do
          grouping.test_tokens = 5
          grouping.decrease_test_tokens
          expect(grouping.test_tokens).to eq(4)
        end
      end

      context 'when number of tokens is equal to 0' do
        it 'does not decrease number of tokens' do
          grouping.test_tokens = 0
          grouping.decrease_test_tokens
          expect(grouping.test_tokens).to eq(0)
        end
      end
    end

    describe '#refresh_test_tokens' do
      context 'when assignment.tokens is not nil' do
        before do
          @assignment = create(:assignment, assignment_properties_attributes:
            { token_start_date: 1.day.ago, tokens_per_period: 10 })
          @grouping = create(:grouping, assignment: @assignment)
          @student1 = create(:student)
          @student2 = create(:student)
          @grouping.test_tokens = 0
          create(:inviter_student_membership,
                 role: @student1,
                 grouping: @grouping,
                 membership_status: StudentMembership::STATUSES[:inviter])
          create(:accepted_student_membership,
                 role: @student2,
                 grouping: @grouping,
                 membership_status: StudentMembership::STATUSES[:accepted])
        end

        it 'refreshes assignment tokens' do
          @grouping.refresh_test_tokens
          expect(@grouping.test_tokens).to eq(10)
        end
      end
    end

    describe '#update_assigned_tokens' do
      let(:assignment) do
        create(:assignment, assignment_properties_attributes: { token_start_date: 1.day.ago, tokens_per_period: 6 })
      end
      let!(:grouping) { create(:grouping, assignment: assignment, test_tokens: 5) }

      before { assignment.reload }

      it 'updates token count properly when it is being increased' do
        assignment.update!(tokens_per_period: 9)
        expect(grouping.reload.test_tokens).to eq(8)
      end

      it 'updates token count properly when it is being decreased' do
        assignment.update!(tokens_per_period: 3)
        expect(grouping.reload.test_tokens).to eq(2)
      end

      it 'does not allow token count to go below 0' do
        assignment.update!(tokens_per_period: 0)
        expect(grouping.reload.test_tokens).to eq(0)
      end

      it 'does not update tokens when there is no change' do
        assignment.update!(tokens_per_period: 6)
        expect(grouping.reload.test_tokens).to eq(5)
      end
    end
  end

  describe 'Student memberships' do
    before do
      @grouping = create(:grouping)
    end

    context 'when there are four members' do
      let(:membership) { create(:accepted_student_membership, grouping: @grouping) }
      let(:inviter_membership) { create(:inviter_student_membership, grouping: @grouping) }
      let(:pending_membership) do
        create(:student_membership, grouping: @grouping, membership_status: StudentMembership::STATUSES[:pending])
      end
      let(:reject_membership) do
        create(:student_membership, grouping: @grouping, membership_status: StudentMembership::STATUSES[:rejected])
      end
      let(:inviter) { inviter_membership.role }

      describe '#membership_status' do
        let(:student) { create(:student) }

        it 'detects student not part of membership' do
          expect(@grouping.membership_status(student)).to be_nil
        end

        it 'shows correct status for student who accepted membership' do
          expect(@grouping.membership_status(membership.role)).to eq('accepted')
        end

        it 'shows correct status for student who has a pending membership' do
          expect(@grouping.membership_status(pending_membership.role)).to eq('pending')
        end

        it 'shows correct status for student who has rejected the membership' do
          expect(@grouping.membership_status(reject_membership.role)).to eq('rejected')
        end

        it 'shows correct status for the inviter' do
          expect(@grouping.membership_status(inviter)).to eq('inviter')
        end
      end

      describe '#display_for_note' do
        it 'displays for note without seeing an exception' do
          expect { @grouping.display_for_note }.not_to raise_error
        end
      end

      describe '#group_name_with_student_user_names' do
        it "displays group name and students' usernames" do
          expect { @grouping.group_name_with_student_user_names }.not_to raise_error
        end
      end

      describe '#pending?' do
        it 'detects non-pending members' do
          expect(@grouping.pending?(inviter)).to be false
        end

        it 'detects pending members' do
          expect(@grouping.pending?(pending_membership.role)).to be true
        end
      end

      describe '#is_inviter?' do
        it 'detects a non-inviter' do
          expect(@grouping.is_inviter?(membership.role)).to be false
        end

        it 'detects the inviter' do
          expect(@grouping.is_inviter?(inviter)).to be true
        end
      end

      describe '#remove_member' do
        it 'is able to remove a member' do
          @grouping.remove_member(membership.id)
          expect(@grouping.membership_status(membership.role)).to be_nil
        end

        it 'is able to remove the inviter' do
          @grouping.remove_member(inviter_membership.id)
          expect(@grouping.membership_status(inviter)).to be_nil
        end
      end

      describe '#deletable_by?' do
        it 'does not allow inviter to delete grouping' do
          expect(@grouping.deletable_by?(inviter)).to be false
        end

        it 'does not allow allow non-inviter to delete grouping' do
          expect(@grouping.deletable_by?(membership.role)).to be false
        end
      end

      describe '#decline_invitation' do
        it 'is able to decline invitation' do
          @grouping.decline_invitation(pending_membership.role)
          expect(@grouping.pending?(pending_membership.role)).to be false
        end
      end

      describe '#remove_rejected' do
        it 'is able to delete rejected memberships' do
          @grouping.remove_rejected(reject_membership.id)
          expect(@grouping.membership_status(reject_membership.role)).to be_nil
        end
      end
    end
  end

  describe 'A group' do
    before do
      @grouping = create(:grouping)
    end

    context 'when there are some submitted files' do
      # submit files
      before do
        @assignment = create(:assignment)
        @file = create(:assignment_file, assignment: @assignment)
        @grouping = create(:grouping, assignment: @assignment)
        @grouping.group.access_repo do |repo|
          txn = repo.get_transaction('markus')
          assignment_folder = File.join(@assignment.repository_folder, File::SEPARATOR)
          begin
            txn.add(File.join(assignment_folder, 'Shapes.java'), 'shapes content', 'text/plain')
            repo.commit(txn)
          end
        end
      end

      teardown do
        destroy_repos
      end

      it 'reports that grouping is not deleteable' do
        create(:inviter_student_membership,
               grouping: @grouping,
               membership_status: StudentMembership::STATUSES[:inviter])
        create(:accepted_student_membership,
               grouping: @grouping,
               membership_status: StudentMembership::STATUSES[:accepted])

        expect(@grouping.deletable_by?(@grouping.inviter)).to be false
      end

      # FAILING: missing_file.length = 0
      it 'is able to report the still missing required assignment_files' do
        @assignment.assignment_files.reload
        missing_files = @grouping.missing_assignment_files
        expect(missing_files.length).to eq(1)
        expect(missing_files).to eq([@file])
      end

      it 'can submit missing file' do
        # submit another file so that we have all required files submitted
        @grouping.group.access_repo do |repo|
          txn = repo.get_transaction('markus')
          txn.add(File.join(@assignment.repository_folder, @file.filename), 'ShapesTest content', 'text/plain')
          repo.commit(txn)

          # check again; there shouldn't be any missing files anymore
          missing_files = @grouping.missing_assignment_files
          expect(missing_files.length).to eq(0)
        end
      end

      it 'has submitted files' do
        expect(@grouping.has_submitted_files?).to be true
      end
    end

    describe '#has_submission?' do
      context 'when all submission_version_used == false' do
        before do
          @submission1 = create(:submission, submission_version_used: false, grouping: @grouping)
          @submission2 = create(:submission, submission_version_used: false, grouping: @grouping)
          @submission3 = create(:submission, submission_version_used: false, grouping: @grouping)
          @grouping.reload
        end

        it 'returns false' do
          expect(@grouping.current_submission_used).to be_nil
          expect(@grouping.has_submission?).to be false
        end
      end

      context 'when the last submission added to the grouping has submission_version_used == false' do
        before do
          @submission1 = create(:submission, submission_version_used: true, grouping: @grouping)
          @submission2 = create(:submission, submission_version_used: false, grouping: @grouping)
          @submission3 = create(:submission, submission_version_used: true, grouping: @grouping)
          @submission4 = create(:submission, submission_version_used: false, grouping: @grouping)
          @grouping.reload
        end

        it 'returns false' do
          expect(@grouping.current_submission_used).to be_nil
          expect(@grouping.has_submission?).to be false
        end
      end

      context 'when the last submission added to the grouping has submission_version_used == true' do
        before do
          @submission1 = create(:submission, submission_version_used: false, grouping: @grouping)
          @submission2 = create(:submission, submission_version_used: true, grouping: @grouping)
          @submission3 = create(:submission, submission_version_used: true, grouping: @grouping)
          @grouping.reload
        end

        it 'returns true' do
          expect(@grouping.current_submission_used).to eq(@submission3)
          expect(@grouping.has_submission?).to be true
        end
      end

      context 'when multiple submissions have submission_version_used == true' do
        before do
          # Dont use machinist in order to bypass validation
          @submission1 = @grouping.submissions.build(submission_version_used: false,
                                                     revision_identifier: 1, revision_timestamp: 1.day.ago,
                                                     submission_version: 1)
          @submission1.save(validate: false)
          @submission2 = @grouping.submissions.build(submission_version_used: true,
                                                     revision_identifier: 1, revision_timestamp: 1.day.ago,
                                                     submission_version: 2)
          @submission2.save(validate: false)
          @submission3 = @grouping.submissions.build(submission_version_used: true,
                                                     revision_identifier: 1, revision_timestamp: 1.day.ago,
                                                     submission_version: 3)
          @submission3.save(validate: false)
          @grouping.reload
        end

        it 'returns true' do
          expect(@grouping.has_submission?).to be true
        end

        context 'when creating a new unused submission' do
          it 'returns false' do
            @submission4 = create(:submission, submission_version_used: false, grouping: @grouping)
            @grouping.reload
            expect(@grouping.has_submission?).to be false
            expect(@submission4.submission_version).to eq(4)
          end
        end

        context 'with a new used submission creation' do
          it 'returns true' do
            @submission5 = create(:submission, submission_version_used: true, grouping: @grouping)
            @grouping.reload
            expect(@grouping.has_submission?).to be true
            expect(@grouping.current_submission_used).to eq(@submission5)
          end
        end
      end
    end

    context 'when the group has no students' do
      before do
        @student01 = create(:student)
        @student02 = create(:student)
      end

      describe '#invite' do
        it 'adds students in any scenario possible when invoked by instructor' do
          members = [@student01.user_name, @student02.user_name]
          @grouping.invite(members, StudentMembership::STATUSES[:accepted], invoked_by_instructor: true)
          expect(@grouping.accepted_student_memberships.count).to eq(2)
        end
      end
    end

    context 'when the group has no students for a assignment with section restriction' do
      before do
        @assignment = create(:assignment, assignment_properties_attributes: { section_groups_only: true })
        @grouping = create(:grouping, assignment: @assignment)
        section01 = create(:section)
        section02 = create(:section)
        @student01 = create(:student, section: section01)
        @student02 = create(:student, section: section02)
      end

      describe '#invite' do
        it 'adds students to groups without checking their sections' do
          members = [@student01.user_name, @student02.user_name]
          @grouping.invite(members, StudentMembership::STATUSES[:accepted], invoked_by_instructor: true)
          expect(@grouping.accepted_student_memberships.count).to eq(2)
        end
      end
    end

    context 'when students are in sections' do
      before do
        @section = create(:section)
        student = create(:student, section: @section)
        @student_can_invite = create(:student, section: @section)
        @student_cannot_invite = create(:student)

        assignment = create(:assignment,
                            due_date: 2.days.from_now,
                            assignment_properties_attributes: { group_max: 2, section_groups_only: true })
        @grouping = create(:grouping, assignment: assignment)
        create(:inviter_student_membership,
               role: student,
               grouping: @grouping,
               membership_status: StudentMembership::STATUSES[:inviter])
      end

      describe '#can_invite?' do
        it 'returns true for students of same section' do
          expect(@grouping.can_invite?(@student_can_invite)).to be true
        end

        it 'raises an error for students of different section' do
          expect { @grouping.can_invite?(@student_cannot_invite) }.to raise_error(RuntimeError)
        end
      end
    end

    context 'when using grace credits' do
      let(:rule_type) { :grace_period_submission_rule }

      context 'when the group submitted on time' do
        include_context 'submission_rule_on_time'
        describe '#student_membership_number' do
          it 'returns 1' do
            expect(grouping.student_membership_number).to eq(1)
          end
        end

        describe '#available_grace_credits' do
          it 'returns more than 1 grace credit remaining' do
            apply_rule
            expect(grouping.available_grace_credits).to be >= 1
          end
        end

        describe '#grace_period_deduction_single' do
          it 'shows no grace credit deduction because submission is on time' do
            apply_rule
            expect(grouping.grace_period_deduction_single).to eq(0)
          end
        end

        context 'when two students submit an assignment' do
          before { create(:accepted_student_membership, grouping: grouping) }

          describe '#student_membership_number' do
            it 'returns 2' do
              expect(grouping.student_membership_number).to eq(2)
            end
          end

          describe '#available_grace_credits' do
            it 'returns more than 1 grace credit remaining' do
              apply_rule
              expect(grouping.available_grace_credits).to be >= 1
            end
          end

          describe '#grace_period_deduction_single' do
            it 'shows no grace credit deduction because submission is on time' do
              apply_rule
              expect(grouping.grace_period_deduction_single).to eq(0)
            end
          end
        end
      end

      context 'when the group submitted during the first penalty period' do
        include_context 'submission_rule_during_first'
        describe '#grace_period_deduction_single' do
          it 'shows one grace credit deduction because submission is late' do
            apply_rule
            expect(grouping.grace_period_deduction_single).to eq(1)
          end
        end

        context 'when two students submit an assignment' do
          before { create(:accepted_student_membership, grouping: grouping) }

          describe '#grace_period_deduction_single' do
            it 'shows one grace credit deduction because submission is late' do
              apply_rule
              expect(grouping.grace_period_deduction_single).to eq(1)
            end
          end
        end
      end

      describe 'when the group submitted during the second penalty period' do
        include_context 'submission_rule_during_second'
        describe '#grace_period_deduction_single' do
          it 'shows two grace credit deduction because submission was submitted in second grace period' do
            apply_rule
            expect(grouping.grace_period_deduction_single).to eq(2)
          end
        end

        context 'when two students submit an assignment' do
          before { create(:accepted_student_membership, grouping: grouping) }

          describe '#grace_period_deduction_single' do
            it 'shows two grace credit deduction because submission was submitted in second grace period' do
              apply_rule
              expect(grouping.grace_period_deduction_single).to eq(2)
            end
          end
        end
      end
    end
  end

  describe '#due_date' do
    shared_examples 'timed assignment due date' do
      let(:assignment) { create(:timed_assignment) }
      let(:due_date) { due_date_obj.due_date || assignment.due_date }
      let(:start_time) { due_date_obj.start_time || assignment.start_time }
      context 'before the grouping has started' do
        it 'should return the due date' do
          expect(grouping.due_date).to be_within(1.second).of(due_date)
        end
      end

      context 'after the grouping has started' do
        before do
          grouping.update!(start_time: start_time + 30.minutes)
        end

        it 'should return the start_time + duration if the assignment due date has not passed' do
          due_date = grouping.reload.start_time + assignment.duration + addition
          expect(grouping.due_date).to be_within(1.second).of(due_date)
        end
      end
    end

    let(:assignment) { create(:assignment) }
    let(:grouping) { create(:grouping_with_inviter, assignment: assignment) }

    context 'with an assignment due date' do
      it 'should return the assigment due date' do
        expect(grouping.due_date).to be_within(1.second).of(assignment.due_date)
      end

      context 'with a timed assignment' do
        let(:addition) { 0.seconds }
        let(:due_date_obj) { assignment }

        it_behaves_like 'timed assignment due date'
      end

      context 'and a grouping extension' do
        let(:extension) { create(:extension, grouping: grouping) }

        it 'should return the assignment due date plus the extension' do
          expected_due_date = assignment.due_date + extension.time_delta
          expect(grouping.due_date).to be_within(1.second).of(expected_due_date)
        end

        context 'with a timed assignment' do
          let(:extension) { create(:extension, grouping: grouping, time_delta: 1.hour) }
          let(:due_date_obj) { assignment }
          let(:addition) { extension.time_delta }

          it_behaves_like 'timed assignment due date'
        end
      end

      context 'and a section due date' do
        let(:section) { create(:section) }
        let!(:assessment_section_properties) do
          create(:assessment_section_properties, assessment: assignment, section: section, due_date: 2.minutes.ago)
        end

        before do
          grouping.inviter.update!(section: section)
        end

        context 'and section_due_dates_type is false' do
          before do
            assignment.assignment_properties.update!(section_due_dates_type: false)
          end

          it 'should return the assignment due date' do
            expect(grouping.due_date).to be_within(1.second).of(assignment.due_date)
          end

          context 'with a timed assignment' do
            let(:addition) { 0.seconds }
            let(:due_date_obj) { assignment }

            it_behaves_like 'timed assignment due date'
          end

          context 'and a grouping extension' do
            let(:extension) { create(:extension, grouping: grouping) }

            it 'should return the assignment due date plus the extension' do
              expected_due_date = assignment.due_date + extension.time_delta
              expect(grouping.due_date).to be_within(1.second).of(expected_due_date)
            end
          end
        end

        context 'and section_due_dates_type is true' do
          before do
            assignment.assignment_properties.update!(section_due_dates_type: true)
          end

          context 'with a timed assignment' do
            let(:addition) { 0.seconds }
            let(:due_date_obj) { assessment_section_properties }

            it_behaves_like 'timed assignment due date'
          end

          it 'should return the section due date' do
            expected_due_date = assessment_section_properties.due_date
            expect(grouping.due_date).to be_within(1.second).of(expected_due_date)
          end

          context 'and a grouping extension' do
            let(:extension) { create(:extension, grouping: grouping) }

            context 'with a timed assignment' do
              let(:extension) { create(:extension, grouping: grouping, time_delta: 1.hour) }
              let(:addition) { extension.time_delta }
              let(:due_date_obj) { assessment_section_properties }

              it_behaves_like 'timed assignment due date'
            end

            it 'should return the section due date plus the extension' do
              expected_due_date = assessment_section_properties.due_date + extension.time_delta
              expect(grouping.due_date).to be_within(1.second).of(expected_due_date)
            end
          end
        end
      end
    end
  end

  describe '#past_assessment_start_time?' do
    let(:assignment) { create(:timed_assignment) }
    let(:grouping) { create(:grouping_with_inviter, assignment: assignment) }

    context 'when assignment start time has passed' do
      it 'should return true' do
        expect(grouping.past_assessment_start_time?).to be true
      end
    end

    context 'when assignment start time has not passed' do
      before { assignment.update! due_date: 1.day.from_now, start_time: 10.minutes.from_now }

      it 'should return false' do
        expect(grouping.past_assessment_start_time?).to be false
      end
    end

    context 'when a section exists' do
      let(:section) { create(:section) }
      let(:assessment_section_properties) do
        create(:assessment_section_properties, assessment: assignment, section: section)
      end
      let(:grouping) { create(:grouping_with_inviter, assignment: assignment) }

      before do
        grouping.inviter.update!(section_id: section.id)
        assignment.update!(section_due_dates_type: true)
      end

      context 'when section start time has passed' do
        before { assessment_section_properties.update! start_time: 1.minute.ago }

        it 'should return true' do
          expect(grouping.past_assessment_start_time?).to be true
        end
      end

      context 'when section start time has not passed' do
        before { assessment_section_properties.update! start_time: 1.minute.from_now }

        it 'should return false' do
          expect(grouping.past_assessment_start_time?).to be false
        end

        context 'when section_due_dates_type is false' do
          before { assignment.update!(section_due_dates_type: false) }

          it 'should return true' do
            expect(grouping.past_assessment_start_time?).to be true
          end
        end
      end
    end
  end

  describe '#submitted_after_collection_date?' do
    let(:due_date) { 3.days.ago }
    let(:assignment) { create(:assignment, due_date: due_date) }
    let(:group) { create(:group, course: assignment.course) }
    let!(:grouping) do
      g = nil
      Timecop.freeze(due_date - 3.days) do
        g = create(:grouping, assignment: assignment, group: group)
      end
      g
    end

    teardown do
      destroy_repos
    end

    context 'without sections before due date' do
      it 'returns false' do
        submit_file_at_time(assignment, group, 'test', (due_date - 2.days).to_s, 'my_file', 'Hello, World!')
        expect(grouping.submitted_after_collection_date?).to be false
      end
    end

    context 'with sections before due date' do
      before do
        assignment.update(section_due_dates_type: true)
        @section = create(:section, course: assignment.course)
        create(:inviter_student_membership,
               role: create(:student, section: @section),
               grouping: grouping,
               membership_status: StudentMembership::STATUSES[:inviter])
      end

      it 'returns false when before section due date' do
        AssessmentSectionProperties.create(
          section: @section,
          assessment: assignment,
          due_date: due_date + 2.days
        )
        submit_file_at_time(assignment, group, 'test', (due_date - 2.days).to_s, 'my_file', 'Hello, World!')
        expect(grouping.submitted_after_collection_date?).to be false
      end

      it 'returns false when after section due date' do
        AssessmentSectionProperties.create(
          section: @section,
          assessment: assignment,
          due_date: due_date - 2.days
        )
        submit_file_at_time(assignment, group, 'test', (due_date - 1.day).to_s, 'my_file', 'Hello, World!')
        expect(grouping.reload.submitted_after_collection_date?).to be true
      end
    end

    context 'without sections after due date' do
      it 'returns true after due date' do
        submit_file_at_time(assignment, group, 'test', (due_date + 1.day).to_s, 'my_file', 'Hello, World!')
        expect(grouping.submitted_after_collection_date?).to be true
      end
    end

    context 'with sections after due date' do
      before do
        assignment.update(section_due_dates_type: true)
        @section = create(:section)
        create(:inviter_student_membership,
               role: create(:student, section: @section),
               grouping: grouping,
               membership_status: StudentMembership::STATUSES[:inviter])
      end

      it 'returns false when before section due_date' do
        AssessmentSectionProperties.create(
          section: @section,
          assessment: assignment,
          due_date: due_date + 1.day
        )
        submit_file_at_time(assignment, group, 'test', (due_date + 5.hours).to_s, 'my_file', 'Hello, World!')
        expect(grouping.reload.submitted_after_collection_date?).to be false
      end

      it 'returns true when after section due_date' do
        AssessmentSectionProperties.create(
          section: @section,
          assessment: assignment,
          due_date: due_date + 1.day
        )
        submit_file_at_time(assignment, group, 'test', (due_date + 2.days).to_s, 'my_file', 'Hello, World!')
        expect(grouping.submitted_after_collection_date?).to be true
      end
    end

    context 'with late penalty' do
      before do
        assignment.update(submission_rule: PenaltyPeriodSubmissionRule.create(
          periods_attributes: [{
            hours: 1,
            deduction: 10,
            interval: 1
          }]
        ))
      end

      it 'returns false when before due date' do
        submit_file_at_time(assignment, group, 'test', (due_date - 30.minutes).to_s, 'my_file', 'Hello, World!')
        expect(grouping.submitted_after_collection_date?).to be false
      end

      it 'returns false when after due date but before penalty period' do
        submit_file_at_time(assignment, group, 'test', (due_date + 30.minutes).to_s, 'my_file', 'Hello, World!')
        expect(grouping.submitted_after_collection_date?).to be false
      end

      it 'returns true when after penalty period' do
        submit_file_at_time(assignment, group, 'test', (due_date + 90.minutes).to_s, 'my_file', 'Hello, World!')
        expect(grouping.submitted_after_collection_date?).to be true
      end
    end
  end

  shared_examples 'test run data' do |return_data, show_output, show_extra|
    if return_data
      it 'should return data for the test run' do
        expect(data.length).to eq 1
        expect(data[0]['test_runs.id']).to eq test_run.id
      end

      it 'should return data for the test result' do
        test_result_data = data[0]['test_results']
        expect(test_result_data.length).to eq 1
        expect(data[0]['test_runs.id']).to eq test_run.id
      end

      if show_extra
        it 'should show extra info' do
          expect(data[0]['test_results'][0]['test_group_results.extra_info']).not_to be_nil
        end
      else
        it 'should not show extra info' do
          expect(data[0]['test_results'][0]['test_group_results.extra_info']).to be_nil
        end
      end

      if show_output
        it 'should show output data' do
          expect(data[0]['test_results'][0]['test_results.output']).not_to be_nil
        end
      else
        it 'should not show output data' do
          expect(data[0]['test_results'][0]['test_results.output']).to be_nil
        end
      end

      it 'should include feedback files associated with the test run' do
        feedback_file = create(:feedback_file_with_test_run, test_group_result: test_run.test_group_results.first)

        expected = [
          {
            'id' => feedback_file.id,
            'filename' => feedback_file.filename,
            'test_runs.id' => test_run.id,
            'test_groups.name' => test_run.test_group_results.first.test_group.name,
            'type' => FileHelper.get_file_type(feedback_file.filename)
          }
        ]

        expect(data[0]['test_results'][0]['feedback_files']).to eq expected
      end
    else
      it 'should not return data' do
        expect(data).to be_empty
      end
    end
  end

  context 'getting test run data' do
    let(:grouping) { create(:grouping_with_inviter) }
    let(:test_run) { create(:test_run, grouping: grouping, role: test_runner, submission: submission) }
    let(:display_output) { 'instructors' }
    let(:test_group) { create(:test_group, assignment: grouping.assignment, display_output: display_output) }
    let(:test_group_result) do
      create(:test_group_result, test_run: test_run, test_group: test_group, extra_info: 'AAA')
    end

    before { create(:test_result, test_group_result: test_group_result) }

    context 'tests run by instructors' do
      let(:test_runner) { create(:instructor) }
      let(:submission) { create(:version_used_submission) }

      describe '#test_runs_instructors' do
        let(:data) { grouping.test_runs_instructors(submission) }

        it_behaves_like 'test run data', true, true, true
      end

      describe '#test_runs_instructors_released' do
        let(:data) { grouping.test_runs_instructors_released(submission) }

        context 'when display_output is instructors' do
          it_behaves_like 'test run data', true, false
          context 'when there are multiple test group_results' do
            let(:test_run2) { create(:test_run, grouping: grouping, role: test_runner, submission: submission) }
            let(:test_group_result2) do
              create(:test_group_result, test_run: test_run2, test_group: test_group, extra_info: 'AAA')
            end

            before { create(:test_result, test_group_result: test_group_result2) }

            it 'should only return data from one test run' do
              expect(data.count).to eq 1
            end

            it 'should only return data from the latest test run' do
              test_group_result2.update(created_at: 1.hour.ago)
              expect(Time.zone.parse(data.first['test_runs.created_at'])).to be_within(1).of(test_run.created_at)
            end
          end
        end

        context 'when display_output is instructors_and_student_tests' do
          let(:display_output) { 'instructors_and_student_tests' }

          it_behaves_like 'test run data', true, false
        end

        context 'when display_output is instructors_and_students' do
          let(:display_output) { 'instructors_and_students' }

          it_behaves_like 'test run data', true, true
        end
      end

      describe '#test_runs_students' do
        let(:data) { grouping.test_runs_students }

        it_behaves_like 'test run data', false
      end
    end

    context 'tests run by students' do
      let(:submission) { nil }
      let(:test_runner) { grouping.inviter }

      describe '#test_runs_instructors' do
        let(:data) { grouping.test_runs_instructors(submission) }

        it_behaves_like 'test run data', false
      end

      describe '#test_runs_instructors_released' do
        let(:data) { grouping.test_runs_instructors_released(submission) }

        it_behaves_like 'test run data', false
      end

      describe '#test_runs_students' do
        let(:data) { grouping.test_runs_students }

        context 'when display_output is instructors' do
          it_behaves_like 'test run data', true, false
        end

        context 'when display_output is instructors_and_student_tests' do
          let(:display_output) { 'instructors_and_student_tests' }

          it_behaves_like 'test run data', true, true
        end

        context 'when display_output is instructors_and_students' do
          let(:display_output) { 'instructors_and_students' }

          it_behaves_like 'test run data', true, true
        end
      end
    end
  end

  describe '#has_non_empty_submission?' do
    context 'with a submission' do
      let(:grouping) { create(:grouping_with_inviter_and_submission) }

      context 'and it is empty' do
        it 'returns false' do
          grouping.current_submission_used.update!(is_empty: true)
          expect(grouping.has_non_empty_submission?).to be false
        end
      end

      context 'and it is not empty' do
        it 'returns true' do
          grouping.current_submission_used.update!(is_empty: false)
          expect(grouping.has_non_empty_submission?).to be true
        end
      end
    end

    context 'with no submission' do
      let(:grouping) { create(:grouping) }

      it 'returns false' do
        expect(grouping.has_non_empty_submission?).to be false
      end
    end
  end

  describe '#select_starter_file_entries' do
    let(:assignment) { create(:assignment, assignment_properties_attributes: { starter_file_type: starter_file_type }) }
    let(:section) { create(:section) }
    let(:student) { create(:student, section: section) }
    let(:grouping) { create(:grouping_with_inviter, inviter: student, assignment: assignment) }
    let!(:starter_file_groups) do
      create_list(:starter_file_group_with_entries, 3, assignment: assignment, use_rename: true)
    end
    let(:ssfg) { create(:section_starter_file_group, starter_file_group: starter_file_groups.last, section: section) }

    context 'when starter_file_type is simple' do
      let(:starter_file_type) { 'simple' }

      it 'should return the entries from the default starter file group' do
        entries = assignment.default_starter_file_group.starter_file_entries
        expect(grouping.select_starter_file_entries).to match_array(entries)
      end
    end

    context 'when starter_file_type is sections' do
      let(:starter_file_type) { 'sections' }

      it 'should return the entries from the section starter file group' do
        entries = ssfg.starter_file_group.starter_file_entries
        expect(grouping.select_starter_file_entries).to match_array(entries)
      end

      context 'when the grouping\'s inviter does not belong to a section' do
        it 'should return the entries from the default starter file group' do
          entries = assignment.default_starter_file_group.starter_file_entries
          student2 = create(:student)
          grouping_without_section = create(:grouping_with_inviter, inviter: student2, assignment: assignment)
          expect(grouping_without_section.select_starter_file_entries).to match_array(entries)
        end
      end

      context 'when the grouping does not have an inviter' do
        it 'should return the entries from the default starter file group' do
          entries = assignment.default_starter_file_group.starter_file_entries
          grouping_without_inviter = create(:grouping, assignment: assignment)
          expect(grouping_without_inviter.select_starter_file_entries).to match_array(entries)
        end
      end
    end

    context 'when starter_file_type is shuffle' do
      let(:starter_file_type) { 'shuffle' }

      it 'should return one entry from each starter file group' do
        entries = grouping.select_starter_file_entries
        starter_file_groups.each do |grp|
          expect(entries).to satisfy('contain one of') { |e| (e & grp.starter_file_entries).count == 1 }
        end
      end
    end

    context 'when starter_file_type is group' do
      let(:starter_file_type) { 'group' }

      it 'should return all entries from one group' do
        expect(grouping.select_starter_file_entries).to satisfy do |e|
          starter_file_groups.any? { |grp| grp.starter_file_entries == e }
        end
      end
    end
  end

  describe '#reset_starter_file_entries' do
    let(:assignment) { create(:assignment) }
    let(:student) { create(:student) }
    let!(:starter_file_groups) { create_list(:starter_file_group_with_entries, 2, assignment: assignment) }
    let!(:grouping) { create(:grouping_with_inviter, inviter: student, assignment: assignment) }

    before { assignment.assignment_properties.update! default_starter_file_group_id: starter_file_groups.first.id }

    it 'is called when creating a grouping' do
      grouping = build(:grouping, inviter: student, assignment: assignment)
      expect(grouping).to receive(:reset_starter_file_entries)
      grouping.save
    end

    it 'does not add starter files to the repo' do
      grouping.group.access_repo do |repo|
        files = repo.get_latest_revision.tree_at_path(assignment.repository_folder)
        expect(files.keys).to be_empty
      end
    end

    it 'creates grouping starter file entries' do
      expect(grouping.reload.starter_file_entries.pluck(:path)).to contain_exactly('q2.txt', 'q1')
    end

    context 'when the starter_file_changed is true' do
      before { grouping.update! starter_file_changed: true }

      it 'should set starter_file_changed to false' do
        expect { grouping.reset_starter_file_entries }.to change { grouping.reload.starter_file_changed }.to(false)
      end
    end

    describe 'when a new starter file entry has been added' do
      before do
        FileUtils.mkdir_p(starter_file_group.path + 'something_new')
        starter_file_group.update_entries
      end

      describe 'and it is relevant to the grouping' do
        let(:starter_file_group) { starter_file_groups.first }

        it 'should add the new starter file entry to the grouping' do
          expect { grouping.reset_starter_file_entries }.to(
            change { grouping.reload.starter_file_entries.pluck(:path).include?('something_new') }
          )
        end
      end

      describe 'and it is not relevant to the grouping' do
        let(:starter_file_group) { starter_file_groups.second }

        it 'should not add the new starter file entry to the grouping' do
          expect { grouping.reset_starter_file_entries }.not_to(
            change { grouping.reload.starter_file_entries.pluck(:path).include?('something_new') }
          )
        end
      end
    end

    describe 'when a starter file entry has been deleted' do
      before do
        FileUtils.rm(starter_file_group.path + 'q2.txt')
        starter_file_group.update_entries
        grouping.reset_starter_file_entries
      end

      describe 'and it is relevant to the grouping' do
        let(:starter_file_group) { starter_file_groups.first }

        it 'should remove the starter file entry from the grouping' do
          expect(grouping.reload.starter_file_entries.pluck(:path)).not_to include('q2.txt')
        end
      end

      describe 'and it is not relevant to the grouping' do
        let(:starter_file_group) { starter_file_groups.second }

        it 'should not remove the starter file entry from the grouping' do
          expect(grouping.reload.starter_file_entries.pluck(:path)).to include('q2.txt')
        end
      end
    end

    context 'when a grouping is created' do
      let(:grouping_without_inviter) { build(:grouping, assignment: assignment) }
      let(:inviter) { create(:inviter_student_membership, grouping: grouping_without_inviter) }

      it 'is called' do
        expect(grouping_without_inviter).to receive(:reset_starter_file_entries)

        grouping_without_inviter.save!
      end

      context 'when the grouping gets an inviter' do
        before do
          assignment.assignment_properties.update!(starter_file_type: starter_file_type)
          grouping_without_inviter.save!
        end

        context 'when starter files are always assigned from the same single group' do
          let(:starter_file_type) { 'simple' }

          it 'is not called' do
            expect(grouping_without_inviter).not_to receive(:reset_starter_file_entries)
            inviter
          end
        end

        context 'when starter files are assigned by section' do
          let(:starter_file_type) { 'sections' }

          it 'is called' do
            expect(grouping_without_inviter).to receive(:reset_starter_file_entries)
            inviter
          end
        end

        context 'when starter files are assigned a random file from each group' do
          let(:starter_file_type) { 'shuffle' }

          it 'is not called' do
            expect(grouping_without_inviter).not_to receive(:reset_starter_file_entries)
            inviter
          end
        end

        context 'when starter files are assigned from a random group' do
          let(:starter_file_type) { 'group' }

          it 'is not called' do
            expect(grouping_without_inviter).not_to receive(:reset_starter_file_entries)
            inviter
          end
        end
      end
    end
  end

  describe '#access_repo' do
    let(:grouping) { create(:grouping) }

    it 'should make sure the assignment folder exists' do
      grouping.group.access_repo { |repo| repo.get_latest_revision.files.clear }
      grouping.access_repo do |repo|
        expect(repo.get_latest_revision.files[0].name).to eq grouping.assignment.repository_folder
      end
    end
  end

  describe '#get_next_group as instructor' do
    let(:role) { create(:instructor) }
    let(:assignment) { create(:assignment) }
    let(:groupings_collected) { [true, true] }

    before do
      groupings_collected.each do |collected|
        create(:grouping_with_inviter_and_submission, assignment: assignment, is_collected: collected)
      end
    end

    it 'should let one navigate right if there is a result directly to the right' do
      groupings = assignment.groupings.joins(:group).order('group_name')
      new_grouping = groupings.first.get_next_grouping(role, false)
      expect(new_grouping.group_id).to eq(groupings.last.group_id)
    end

    it 'should let one navigate left if there is a result directly to the left' do
      groupings = assignment.groupings.joins(:group).order('group_name')
      new_grouping = groupings.last.get_next_grouping(role, true)
      expect(new_grouping.group_id).to eq(groupings.first.group_id)
    end

    it 'should not one navigate right if there is no result directly to the right' do
      groupings = assignment.groupings.joins(:group).order('group_name')
      new_grouping = groupings.last.get_next_grouping(role, false)
      expect(new_grouping).to be_nil
    end

    it 'should not let one navigate left if there is no result directly to the left' do
      groupings = assignment.groupings.joins(:group).order('group_name')
      new_grouping = groupings.first.get_next_grouping(role, true)
      expect(new_grouping).to be_nil
    end

    describe 'with collected results separated by an uncollected results' do
      let(:groupings_collected) { [false, true] }

      it 'should let me navigate to the right if any result exists towards the right' do
        groupings = assignment.groupings.joins(:group).order('group_name')
        new_grouping = groupings.first.get_next_grouping(role, false)
        expect(new_grouping.group_id).to eq(groupings.last.group_id)
      end

      it 'should let one navigate left if there is a result directly to the left' do
        groupings = assignment.groupings.joins(:group).order('group_name')
        new_grouping = groupings.last.get_next_grouping(role, true)
        expect(new_grouping.group_id).to eq(groupings.first.group_id)
      end
    end
  end

  describe '#get_next_group as ta' do
    let(:assignment) { create(:assignment) }
    let(:role) { create(:ta) }
    let!(:grouping1) { create(:grouping_with_inviter_and_submission, assignment: assignment) }
    let!(:grouping2) { create(:grouping_with_inviter_and_submission, assignment: assignment) }
    let(:groupings) { [grouping1, grouping2] }

    before do
      2.times do |i|
        create(:ta_membership, role: role, grouping: groupings[i])
      end
    end

    it 'should let one navigate right if there is a result directly to the right' do
      groupings = assignment.groupings.joins(:group).order('group_name')
      new_grouping = groupings.first.get_next_grouping(role, false)
      expect(new_grouping.group_id).to be(groupings.last.group_id)
    end

    it 'should let one navigate left if there is a result directly to the left' do
      groupings = assignment.groupings.joins(:group).order('group_name')
      new_grouping = groupings.last.get_next_grouping(role, true)
      expect(new_grouping.group_id).to be(groupings.first.group_id)
    end

    it 'should not one navigate right if there is no result directly to the right' do
      groupings = assignment.groupings.joins(:group).order('group_name')
      new_grouping = groupings.last.get_next_grouping(role, false)
      expect(new_grouping).to be_nil
    end

    it 'should not let one navigate left if there is no result directly to the left' do
      groupings = assignment.groupings.joins(:group).order('group_name')
      new_grouping = groupings.first.get_next_grouping(role, true)
      expect(new_grouping).to be_nil
    end

    context 'when collected results are separated by an uncollected results' do
      let(:grouping2) { create(:grouping, assignment: assignment, is_collected: false) }

      before do
        grouping3 = create(:grouping_with_inviter_and_submission, assignment: assignment)
        create(:ta_membership, role: role, grouping: grouping3)
      end

      it 'should let me navigate to the right if any result exists towards the right' do
        groupings = assignment.groupings.joins(:group).order('group_name')
        new_grouping = groupings.first.get_next_grouping(role, false)
        expect(new_grouping.group_id).to eq(groupings.last.group_id)
      end

      it 'should let one navigate left if there is a result directly to the left' do
        groupings = assignment.groupings.joins(:group).order('group_name')
        new_grouping = groupings.last.get_next_grouping(role, true)
        expect(new_grouping.group_id).to eq(groupings.first.group_id)
      end
    end
  end

  describe '#get_random_incomplete' do
    let!(:grouping1) { create(:grouping_with_inviter_and_submission) }
    let!(:grouping2) { create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment) }
    let!(:grouping3) { create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment) }
    let!(:grouping4) { create(:grouping, assignment: grouping1.assignment) }

    shared_examples 'role is an instructor or ta' do
      context 'when there are no more incomplete submissions accessible to role' do
        it 'returns nil' do
          grouping1.current_result.update(marking_state: Result::MARKING_STATES[:complete])
          grouping2.current_result.update(marking_state: Result::MARKING_STATES[:complete])
          expect(grouping3.get_random_incomplete(role)).to be_nil
        end
      end

      it 'does not return this grouping' do
        expect(grouping2.get_random_incomplete(role).id).not_to eq(grouping2.id)
      end

      it 'does not return groupings without submissions' do
        expect(grouping2.get_random_incomplete(role).id).not_to eq(grouping4.id)
      end
    end

    context 'when role is a ta' do
      let!(:role) { create(:ta) }

      before do
        create(:ta_membership, grouping: grouping2, role: role)
        create(:ta_membership, grouping: grouping3, role: role)
      end

      it 'only picks a random group from the groupings role to grade' do
        expect(grouping2.get_random_incomplete(role).id).to eq(grouping3.id)
      end

      it 'only picks a random group from the groupings whose current result is incomplete' do
        create(:ta_membership, grouping: grouping1, role: role)
        grouping3.current_result.update(marking_state: Result::MARKING_STATES[:complete])
        expect(grouping2.get_random_incomplete(role).id).to eq(grouping1.id)
      end

      it_behaves_like 'role is an instructor or ta'
    end

    context 'when role is an instructor' do
      let!(:role) { create(:instructor) }

      it 'only picks from all groupings with an incomplete marking_state (that isn\'t the current grouping)' do
        grouping1.current_result.update(marking_state: Result::MARKING_STATES[:complete])
        expect(grouping2.get_random_incomplete(role).id).to eq(grouping3.id)
      end

      it_behaves_like 'role is an instructor or ta'
    end
  end
end
