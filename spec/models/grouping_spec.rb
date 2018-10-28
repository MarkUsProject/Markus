describe Grouping do
  describe 'associations' do
    it { is_expected.to belong_to(:grouping_queue) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to have_many(:memberships) }
    it { is_expected.to have_many(:submissions) }
    it { is_expected.to have_many(:notes) }
  end

  describe 'a default grouping' do
    before :each do
      @grouping = create(:grouping)
    end

    it 'does not have any ta for marking' do
      expect(@grouping.has_ta_for_marking?).to be false
    end

    it 'does not have submissions' do
      expect(@grouping.has_submission?).to be false
    end

    context 'hidden students' do
      before :each do
        @hidden = create(:student, hidden: true)
      end

      it 'cannot be invited' do
        @grouping.invite(@hidden.user_name)
        expect(@grouping.memberships.count).to eq(0)
      end

      it 'cannot be added' do
        @grouping.add_member(@hidden)
        expect(@grouping.memberships.count).to eq(0)
      end
    end

    it 'displays Empty Group since no students in the group' do
      expect(@grouping.get_all_students_in_group).to eq('Empty Group')
    end
  end

  describe 'assigning and unassigning TAs' do
    let(:assignment) { create(:assignment) }
    let(:grouping) { create(:grouping) }
    let(:groupings) do
      Array.new(2) { create(:grouping, assignment: assignment) }
    end
    let(:tas) { Array.new(2) { create(:ta) } }
    let(:grouping_ids) { groupings.map(&:id) }
    let(:ta_ids) { tas.map(&:id) }

    describe '.randomly_assign_tas' do
      it 'can randomly bulk assign no TAs to no groupings' do
        Grouping.randomly_assign_tas([], [], assignment)
      end

      it 'can randomly bulk assign TAs to no groupings' do
        Grouping.randomly_assign_tas([], ta_ids, assignment)
      end

      it 'can randomly bulk assign no TAs to all groupings' do
        Grouping.randomly_assign_tas(grouping_ids, [], assignment)
      end

      it 'can randomly bulk assign TAs to all groupings' do
        Grouping.randomly_assign_tas(grouping_ids, ta_ids, assignment)

        groupings.each do |grouping|
          grouping.reload
          expect(grouping.tas.size).to eq 1
          expect(tas).to include grouping.tas.first
        end
      end

      it 'can randomly bulk assign duplicated TAs to groupings' do
        # The probability of assigning no duplicated TAs after (tas.size + 1)
        # trials is 0.
        (tas.size + 1).times do
          Grouping.randomly_assign_tas(grouping_ids, ta_ids, assignment)
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
        Grouping.randomly_assign_tas(grouping_ids, ta_ids, assignment)
      end

      it 'updates assigned groups counts after randomly bulk assign TAs' do
        expect(Criterion).to receive(:update_assigned_groups_counts)
          .with(assignment)
        Grouping.randomly_assign_tas(grouping_ids, ta_ids, assignment)
      end
    end

    describe '.assign_all_tas' do
      it 'can bulk assign no TAs to no groupings' do
        Grouping.assign_all_tas([], [], assignment)
      end

      it 'can bulk assign all TAs to no groupings' do
        Grouping.assign_all_tas([], ta_ids, assignment)
      end

      it 'can bulk assign no TAs to all groupings' do
        Grouping.assign_all_tas(grouping_ids, [], assignment)
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
        groupings.each do |grouping|
          grouping.reload
          expect(grouping.tas).to eq [tas.first]
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
        expect(Repository.get_class).to receive(:__update_permissions).once
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
        expect(Repository.get_class).to receive(:__update_permissions).once
        Grouping.assign_tas(grouping_ids, ta_ids, assignment) do |grouping_ids, ta_ids|
          grouping_ids.zip(ta_ids.cycle)
        end
      end
    end

    describe '.unassign_tas' do
      it 'can bulk unassign no TAs' do
        Grouping.unassign_tas([], [], assignment)
      end

      it 'can bulk unassign TAs' do
        Grouping.assign_all_tas(grouping_ids, ta_ids, assignment)
        ta_membership_ids = groupings
          .map { |grouping| grouping.memberships.pluck(:id) }
          .reduce(:+)
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
        expect(Repository.get_class).to receive(:__update_permissions).once
        Grouping.unassign_tas([], grouping_ids, assignment)
      end
    end

    describe '#add_tas' do
      it 'is able to assign tas' do
        grouping.add_tas(tas)
        expect(grouping.ta_memberships.count).to eq(2)
      end

      it 'is not able to assign same TAs twice' do
        grouping.add_tas(tas)
        expect(grouping.ta_memberships.count).to eq(2)
        grouping.add_tas(tas)
        expect(grouping.ta_memberships.count).to eq(2)
      end
    end

    describe '#has_ta_for_marking?' do
      it 'has a ta for marking' do
        grouping.add_tas(tas)
        expect(grouping.has_ta_for_marking?).to be true
      end
    end

    describe '#get_ta_names' do
      it 'gets ta names' do
        grouping.add_tas(tas)
        expect(grouping.get_ta_names).to match_array(tas.map(&:user_name))
      end
    end

    describe '#remove_tas' do
      it 'is able to remove tas' do
        grouping.remove_tas(tas)
        expect(grouping.ta_memberships.count).to eq(0)
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

      context 'with no assigned TAs' do
        it 'updates criteria coverage count to 0' do
          expect_updated_criteria_coverage_count_eq 0
        end
      end

      context 'with assigned TAs' do
        let!(:tas) { Array.new(2) { create(:ta) } }

        before :each do
          create_ta_memberships(grouping, tas)
        end

        context 'with no assigned criteria' do
          it 'updates criteria coverage count to 0' do
            expect_updated_criteria_coverage_count_eq 0
          end
        end

        context 'with assigned criteria' do
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
            before(:each) { criteria[0].add_tas(tas[0]) }

            it 'updates criteria coverage count to 1' do
              expect_updated_criteria_coverage_count_eq 1
            end
          end

          context 'when only one is assigned multiple TAs' do
            before(:each) { criteria[0].add_tas(tas) }

            it 'updates criteria coverage count to 1' do
              expect_updated_criteria_coverage_count_eq 1
            end
          end

          context 'when `tas.size` are assigned unique TAs' do
            before :each do
              tas.size.times { |i| criteria[i].add_tas(tas[i]) }
            end

            it 'updates criteria coverage count to `tas.size`' do
              expect_updated_criteria_coverage_count_eq tas.size
            end
          end

          context 'when `tas.size` are assigned non-unique TAs' do
            before(:each) { tas.size.times { |i| criteria[i].add_tas(tas) } }

            it 'updates criteria coverage count to `tas.size`' do
              expect_updated_criteria_coverage_count_eq tas.size
            end

            context 'when TAs are also assigned to groups of another assignment' do
              before :each do
                # Creating a new grouping also creates a new assignment.
                grouping = create(:grouping)
                criterion = create(:rubric_criterion,
                                   assignment: grouping.assignment)
                criterion.add_tas(tas)
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
      let(:another_criterion) do
        create(:rubric_criterion, assignment: assignment)
      end

      before :each do
        create_ta_memberships([grouping, another_grouping], ta)
        criterion.add_tas(ta)
        another_criterion.add_tas(ta)
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
    it { is_expected.to validate_presence_of(:test_tokens) }
    let(:grouping) { create(:grouping) }

    context 'set to 5' do
      it 'is valid' do
        grouping.test_tokens = 5
        expect(grouping).to be_valid
      end
    end

    context 'set to 0' do
      it 'is valid' do
        grouping.test_tokens = 0
        expect(grouping).to be_valid
      end
    end

    describe '.decrease_test_tokens!' do
      context 'when number of tokens is greater than 0' do
        it 'decreases number of tokens' do
          grouping.test_tokens = 5
          grouping.decrease_test_tokens!
          expect(grouping.test_tokens).to eq(4)
        end
      end

      context 'when number of tokens is equal to 0' do
        it 'raise san error' do
          grouping.test_tokens = 0
          expect { grouping.decrease_test_tokens! }.to raise_error(RuntimeError)
        end
      end
    end

    describe '#refresh_test_tokens!' do
      context 'if assignment.tokens is not nil' do
        before do
          @assignment = FactoryBot.create(:assignment, token_start_date: 1.day.ago, tokens_per_period: 10)
          @group = FactoryBot.create(:group)
          @grouping = Grouping.create(group: @group, assignment: @assignment)
          @student1 = FactoryBot.create(:student)
          @student2 = FactoryBot.create(:student)
          @grouping.test_tokens = 0
          create(:inviter_student_membership,
                 user: @student1,
                 grouping: @grouping,
                 membership_status: StudentMembership::STATUSES[:inviter])
          create(:accepted_student_membership,
                 user: @student2,
                 grouping: @grouping,
                 membership_status: StudentMembership::STATUSES[:accepted])
        end
        it 'refreshes assignment tokens' do
          @grouping.refresh_test_tokens!
          expect(@grouping.test_tokens).to eq(10)
        end
      end
    end

    describe '#update_assigned_tokens' do
      before :each do
        @assignment = FactoryBot.create(:assignment, token_start_date: 1.day.ago, tokens_per_period: 6)
        @group = FactoryBot.create(:group)
        @grouping = Grouping.create(group: @group, assignment: @assignment, test_tokens: 5)
        @assignment.groupings << @grouping # TODO: why the bidirectional association is not automatically created?
      end

      it 'updates token count properly when it is being increased' do
        @assignment.tokens_per_period = 9
        @assignment.save
        expect(@grouping.test_tokens).to eq(8)
      end

      it 'updates token count properly when it is being decreased' do
        @assignment.tokens_per_period = 3
        @assignment.save
        expect(@grouping.test_tokens).to eq(2)
      end

      it 'does not allow token count to go below 0' do
        @assignment.tokens_per_period = 0
        @assignment.save
        expect(@grouping.test_tokens).to eq(0)
      end
    end
  end

  describe 'Student memberships' do
    before :each do
      @grouping = create(:grouping)
    end

    context 'of four members' do
      let(:membership) { create(:accepted_student_membership, grouping: @grouping) }
      let(:inviter_membership) { create(:inviter_student_membership, grouping: @grouping) }
      let(:pending_membership) do
        create(:student_membership, grouping: @grouping, membership_status: StudentMembership::STATUSES[:pending])
      end
      let(:reject_membership) do
        create(:student_membership, grouping: @grouping, membership_status: StudentMembership::STATUSES[:rejected])
      end
      let(:inviter) { inviter_membership.user }

      describe '#membership_status' do
        let(:student) { create(:student) }
        it 'detects student not part of membership' do
          expect(@grouping.membership_status(student)).to be_nil
        end

        it 'shows correct status for student who accepted membership' do
          expect(@grouping.membership_status(membership.user)).to eq('accepted')
        end

        it 'shows correct status for student who has a pending membership' do
          expect(@grouping.membership_status(pending_membership.user)).to eq('pending')
        end

        it 'shows correct status for student who has rejected the membership' do
          expect(@grouping.membership_status(reject_membership.user)).to eq('rejected')
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
          expect(@grouping.pending?(pending_membership.user)).to be true
        end
      end

      describe '#is_inviter?' do
        it 'detects a non-inviter' do
          expect(@grouping.is_inviter?(membership.user)).to be false
        end
        it 'detects the inviter' do
          expect(@grouping.is_inviter?(inviter)).to be true
        end
      end

      describe '#remove_member' do
        it 'is able to remove a member' do
          @grouping.remove_member(membership.id)
          expect(@grouping.membership_status(membership.user)).to be_nil
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
          expect(@grouping.deletable_by?(membership.user)).to be false
        end
      end

      describe '#decline_invitation' do
        it 'is able to decline invitation' do
          @grouping.decline_invitation(pending_membership.user)
          expect(@grouping.pending?(pending_membership.user)).to be false
        end
      end

      describe '#remove_rejected' do
        it 'is able to delete rejected memberships' do
          @grouping.remove_rejected(reject_membership.id)
          expect(@grouping.membership_status(reject_membership.user)).to be_nil
        end
      end
    end
  end

  describe 'A group' do
    before :each do
      @grouping = create(:grouping)
    end
    context 'with some submitted files' do
      # submit files
      before :each do
        @assignment = create(:assignment)
        @file = create(:assignment_file, assignment: @assignment)
        @grouping = create(:grouping, assignment: @assignment)
        @grouping.group.access_repo do |repo|
          txn = repo.get_transaction('markus')
          assignment_folder = File.join(@assignment.repository_folder, File::SEPARATOR)
          begin
            txn.add(File.join(assignment_folder, 'Shapes.java'), 'shapes content', 'text/plain')
            unless repo.commit(txn)
              raise 'Unable to setup test!'
            end
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
          begin
            txn.add(File.join(@assignment.repository_folder, @file.filename), 'ShapesTest content', 'text/plain')
            unless repo.commit(txn)
              raise 'Commit failed!'
            end
          rescue Exception => e
            raise 'Submitting file failed: ' + e.message
          end
          # check again; there shouldn't be any missing files anymore
          missing_files = @grouping.missing_assignment_files
          expect(missing_files.length).to eq(0)
        end
      end
    end

    describe '#has_submission?' do
      context 'all with submission_version_used == false' do
        before :each do
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

      context 'with the last submission added to the grouping having submission_version_used == false' do
        before :each do
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

      context 'with the last submission added to the grouping having submission_version_used == true' do
        before :each do
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

      context 'with multiple submissions with submission_version_used == true' do
        before :each do
          # Dont use machinist in order to bypass validation
          @submission1 = @grouping.submissions.build(submission_version_used: false,
                                                     revision_identifier: 1, revision_timestamp: 1.days.ago,
                                                     submission_version: 1)
          @submission1.save(validate: false)
          @submission2 = @grouping.submissions.build(submission_version_used: true,
                                                     revision_identifier: 1, revision_timestamp: 1.days.ago,
                                                     submission_version: 2)
          @submission2.save(validate: false)
          @submission3 = @grouping.submissions.build(submission_version_used: true,
                                                     revision_identifier: 1, revision_timestamp: 1.days.ago,
                                                     submission_version: 3)
          @submission3.save(validate: false)
          @grouping.reload
        end

        it 'returns true' do
          expect(@grouping.has_submission?).to be true
        end

        context 'with a new unused submission creation' do
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

    context 'without students (ie created by an admin)' do
      before :each do
        @student01 = create(:student)
        @student02 = create(:student)
      end

      describe '#invite' do
        it 'adds students in any scenario possible when invoked by admin' do
          members = [@student01.user_name, @student02.user_name]
          @grouping.invite(members, StudentMembership::STATUSES[:accepted], true)
          expect(@grouping.accepted_student_memberships.count).to eq(2)
        end
      end
    end

    context 'without students (ie created by an admin) for a assignment with section restriction' do
      before :each do
        @assignment = create(:assignment, section_due_dates_type: true)
        @grouping = create(:grouping, assignment: @assignment)
        section01 = create(:section)
        section02 = create(:section)
        @student01 = create(:student, section: section01)
        @student02 = create(:student, section: section02)
      end

      describe '#invite' do
        it 'adds students to groups without checking their sections' do
          members = [@student01.user_name, @student02.user_name]
          @grouping.invite(members, StudentMembership::STATUSES[:accepted], true)
          expect(@grouping.accepted_student_memberships.count).to eq(2)
        end
      end
    end

    context 'with students in sections' do
      before :each do
        @section = create(:section)
        student  = create(:student, section: @section)
        @student_can_invite = create(:student, section: @section)
        @student_cannot_invite = create(:student)

        assignment = create(:assignment, group_max: 2, section_groups_only: true, due_date: Time.now + 2.days)
        @grouping = create(:grouping, assignment: assignment)
        create(:inviter_student_membership,
               user: student,
               grouping: @grouping,
               membership_status: StudentMembership::STATUSES[:inviter])
      end

      describe '#can_invite?' do
        it 'returns true for students of same section' do
          expect(@grouping.can_invite?(@student_can_invite)).to be true
        end

        it 'returns false for students of different section' do
          expect(@grouping.can_invite?(@student_cannot_invite)).to be false
        end
      end
    end

    context 'with an assignment that has a grace period of 24 hours after due date' do
      before :each do
        @assignment = create(:assignment)
        @group = create(:group)
        grace_period_submission_rule = GracePeriodSubmissionRule.new
        @assignment.replace_submission_rule(grace_period_submission_rule)
        GracePeriodDeduction.destroy_all
        grace_period_submission_rule.save

        # On July 1 at 1PM, the instructor sets up the course...
        pretend_now_is(Time.parse('July 1 2009 1:00PM')) do
          # Due date is July 23 @ 5PM
          @assignment.due_date = Time.parse('July 23 2009 5:00PM')
          # Overtime begins at July 23 @ 5PM
          # Add a 24 hour grace period
          period = Period.new
          period.submission_rule = @assignment.submission_rule
          period.hours = 24
          period.save
          # Collect date is now after July 24 @ 5PM
          @assignment.save
        end
      end

      teardown do
        destroy_repos
      end

      context 'with one student submitting an assignment' do
        before :each do
          # grouping of only one student
          @grouping = create(:grouping, assignment: @assignment, group: @group)
          @inviter_membership = create(:inviter_student_membership,
                                       user: create(:student, user_name: 'student1'),
                                       grouping: @grouping,
                                       membership_status: StudentMembership::STATUSES[:inviter])
          @inviter = @inviter_membership.user

          # On July 15, the Student logs in, triggering repository folder creation
          pretend_now_is(Time.parse('July 15 2009 6:00PM')) do
            @grouping.create_grouping_repository_folder
          end
        end

        describe '#student_membership_number' do
          it 'returns 1' do
            expect(@grouping.student_membership_number).to eq(1)
          end
        end

        describe '#available_grace_credits' do
          it 'returns more than 1 grace credit remaining' do
            expect(@grouping.available_grace_credits).to be >= 1
          end
        end

        describe '#grace_period_deduction_single' do
          it 'shows no grace credit deduction because submission is on time' do
            submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'TestFile.java',
                                'Some contents for TestFile.java')
            submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'Test.java',
                                'Some contents for Test.java')
            submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'Driver.java',
                                'Some contents for Driver.java')

            # An Instructor or Grader decides to begin grading
            pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
              submission = Submission.create_by_timestamp(@grouping,
                                                          @assignment.submission_rule.calculate_collection_time)
              @assignment.submission_rule.apply_submission_rule(submission)

              @grouping.reload
              # Should be no deduction because submitting on time
              expect(@grouping.grace_period_deduction_single).to eq(0)
            end
          end

          it 'shows one grace credition deduction because submission was late' do
            submit_file_at_time(@assignment, @group, 'test', 'July 24 2009 9:00AM', 'LateSubmission.java',
                                'Some overtime contents')

            # An Instructor or Grader decides to begin grading
            pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
              submission = Submission.create_by_timestamp(@grouping,
                                                          @assignment.submission_rule.calculate_collection_time)
              @assignment.submission_rule.apply_submission_rule(submission)

              @grouping.reload
              # Should display 1 credit deduction because of one-day late submission
              expect(@grouping.grace_period_deduction_single).to eq(1)
            end
          end
        end
      end

      context 'with two students submitting an assignment' do
        before :each do
          # grouping of two students
          @grouping = create(:grouping, assignment: @assignment, group: @group)
          # should consist of inviter and another student
          @membership = create(:accepted_student_membership,
                               user: create(:student, user_name: 'student1'),
                               grouping: @grouping,
                               membership_status: StudentMembership::STATUSES[:accepted])

          @inviter_membership = create(:inviter_student_membership,
                                       user: create(:student, user_name: 'student2'),
                                       grouping: @grouping,
                                       membership_status: StudentMembership::STATUSES[:inviter])
          @inviter = @inviter_membership.user

          # On July 15, the Student logs in, triggering repository folder creation
          pretend_now_is(Time.parse('July 15 2009 6:00PM')) do
            @grouping.create_grouping_repository_folder
          end
        end

        describe '#student_membership_number' do
          it 'returns 2' do
            expect(@grouping.student_membership_number).to eq(2)
          end
        end

        describe '#available_grace_credits' do
          it 'returns more than 1 grace credit remaining' do
            expect(@grouping.available_grace_credits).to be >= 1
          end
        end

        describe '#grace_period_deduction_single' do
          it 'shows no grace credit deductions because submission is on time' do
            submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'TestFile.java',
                                'Some contents for TestFile.java')
            submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'Test.java',
                                'Some contents for Test.java')
            submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'Driver.java',
                                'Some contents for Driver.java')

            # An Instructor or Grader decides to begin grading
            pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
              submission = Submission.create_by_timestamp(@grouping,
                                                          @assignment.submission_rule.calculate_collection_time)
              @assignment.submission_rule.apply_submission_rule(submission)

              @grouping.reload
              # Should be no deduction because submitting on time
              expect(@grouping.grace_period_deduction_single).to eq(0)
            end
          end

          it 'shows one grace credit deduction because submission is late' do
            submit_file_at_time(@assignment, @group, 'test', 'July 24 2009 9:00AM', 'LateSubmission.java',
                                'Some overtime contents')

            # An Instructor or Grader decides to begin grading
            pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
              submission = Submission.create_by_timestamp(@grouping,
                                                          @assignment.submission_rule.calculate_collection_time)
              @assignment.submission_rule.apply_submission_rule(submission)

              @grouping.reload
              # Should display 1 credit deduction because of one-day late submission
              expect(@grouping.grace_period_deduction_single).to eq(1)
            end
          end
        end
      end
    end
  end

  describe '#past_due_date?' do
    context 'with an assignment' do
      before :each do
        @assignment = create(:assignment, due_date: Time.parse('July 22 2009 5:00PM'))
        @group = create(:group)
        pretend_now_is(Time.parse('July 21 2009 5:00PM')) do
          @grouping = create(:grouping, assignment: @assignment, group: @group)
        end
      end

      teardown do
        destroy_repos
      end

      context 'without sections before due date' do
        it 'returns false' do
          submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'my_file', 'Hello, World!')
          expect(@grouping.past_due_date?).to be false
        end
      end

      context 'with sections before due date' do
        before :each do
          @assignment.section_due_dates_type = true
          @assignment.save
          @section = create(:section)
          create(:inviter_student_membership,
                 user: create(:student, section: @section),
                 grouping: @grouping,
                 membership_status: StudentMembership::STATUSES[:inviter])
        end

        it 'returns false when before section due date' do
          SectionDueDate.create(section: @section, assignment: @assignment, due_date: Time.parse('July 24 2009 5:00PM'))
          submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'my_file', 'Hello, World!')
          expect(@grouping.past_due_date?).to be false
        end

        it 'returns false when after section duedate' do
          SectionDueDate.create(section: @section, assignment: @assignment, due_date: Time.parse('July 18 2009 5:00PM'))
          submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'my_file', 'Hello, World!')
          expect(@grouping.past_due_date?).to be true
        end
      end

      context 'without sections after due date' do
        before :each do
          @assignment = create(:assignment, due_date: Time.parse('July 22 2009 5:00PM'))
          @group = create(:group)
          pretend_now_is(Time.parse('July 28 2009 5:00PM')) do
            @grouping = create(:grouping, assignment: @assignment, group: @group)
          end
        end

        it 'returns true after due date' do
          submit_file_at_time(@assignment, @group, 'test', 'July 28 2009 5:00PM', 'my_file', 'Hello, World!')
          expect(@grouping.past_due_date?).to be true
        end
      end

      context 'with sections after due date' do
        before :each do
          @assignment.section_due_dates_type = true
          @assignment.save
          @section = create(:section)
          create(:inviter_student_membership,
                 user: create(:student, section: @section),
                 grouping: @grouping,
                 membership_status: StudentMembership::STATUSES[:inviter])
        end

        it 'returns false when before section due_date' do
          SectionDueDate.create(section: @section, assignment: @assignment, due_date: Time.parse('July 30 2009 5:00PM'))
          submit_file_at_time(@assignment, @group, 'test', 'July 28 2009 1:00PM', 'my_file', 'Hello, World!')
          expect(@grouping.past_due_date?).to be false
        end

        it 'returns true when after section due_date' do
          SectionDueDate.create(section: @section, assignment: @assignment, due_date: Time.parse('July 20 2009 5:00PM'))
          submit_file_at_time(@assignment, @group, 'test', 'July 28 2009 1:00PM', 'my_file', 'Hello, World!')
          expect(@grouping.past_due_date?).to be true
        end
      end
    end
  end
end
