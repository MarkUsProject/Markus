require 'spec_helper'

describe Grouping do
  describe 'associations' do
    it { is_expected.to belong_to(:grouping_queue) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to have_many(:memberships) }
    it { is_expected.to have_many(:submissions) }
    it { is_expected.to have_many(:notes) }
  end

  describe 'validations' do
    before :each do
      @grouping = create(:grouping)
    end

    it 'does not have any ta for marking' do
      expect(@grouping.has_ta_for_marking?).to be false
    end

    it 'does not have submissions' do
      expect(@grouping.has_submission?).to be false
    end

    it "can't invite nor add hidden students" do
      hidden = Student.create(hidden: true)
      @grouping.invite(hidden.user_name)
      expect(@grouping.memberships.count).to eq(0)

      @grouping.add_member(hidden)
      expect(@grouping.memberships.count).to eq(0)
    end

    it 'displays Empty Group since no students in the group' do
      expect(@grouping.get_all_students_in_group).to eq('Empty Group')
    end
  end

  describe 'assigning and unassigning TAs' do
    let(:assignment) { create(:assignment) }
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

            context 'when TAs are also assigned to groups of another ' +
                    'assignment' do
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
      it 'be valid' do
        grouping.test_tokens = 5
        expect(grouping).to be_valid
      end
    end

    context 'set to 0' do
      it 'be valid' do
        grouping.test_tokens = 0
        expect(grouping).to be_valid
      end
    end

    context 'methods' do
      describe '.decrease_test_tokens!' do
        context 'when number of tokens is greater than 0' do
          it 'decrease number of tokens' do
            grouping.test_tokens = 5
            grouping.decrease_test_tokens!
            expect(grouping.test_tokens).to eq(4)
          end
        end

        context 'when number of tokens is equal to 0' do
          it 'raise an error' do
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
            StudentMembership.create(
              user: @student1,
              grouping: @grouping,
              membership_status: StudentMembership::STATUSES[:inviter]
            )
            StudentMembership.create(
              user: @student2,
              grouping: @grouping,
              membership_status: StudentMembership::STATUSES[:accepted]
            )
            @grouping.refresh_test_tokens!
          end
          it 'refreshes assignment tokens' do
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

        it 'update token count properly when it is being increased' do
          @assignment.tokens_per_period = 9
          @assignment.save
          expect(@grouping.test_tokens).to eq(8)
        end

        it 'update token count properly when it is being decreased' do
          @assignment.tokens_per_period = 3
          @assignment.save
          expect(@grouping.test_tokens).to eq(2)
        end

        it 'not allow token count to go below 0' do
          @assignment.tokens_per_period = 0
          @assignment.save
          expect(@grouping.test_tokens).to eq(0)
        end
      end
    end
  end
  describe 'A group' do
    before :each do
      @grouping = create(:grouping)
    end
    context 'with two student members' do
      before :each do
        # should consist of inviter and another student
        @membership = create(:accepted_student_membership, user: create(:student, user_name: 'student1'),
                                             grouping: @grouping,
                                             membership_status: StudentMembership::STATUSES[:accepted])

        @inviter_membership = create(:inviter_student_membership, user: create(:student, user_name: 'student2'),
                                                     grouping: @grouping,
                                                     membership_status: StudentMembership::STATUSES[:inviter])
        @inviter = @inviter_membership.user
      end

      it 'displays for note without seeing an exception' do
        expect { @grouping.display_for_note }.not_to raise_error
      end

      it "displays group name and students' usernames" do
        expect { @grouping.group_name_with_student_user_names }.not_to raise_error
      end

      it "displays comma separated list of students' usernames" do
        expect(@grouping.get_all_students_in_group).to eq('student1, student2')
      end

      it 'is valid' do
        expect(@grouping.student_membership_number).to eq(2)
        expect(@grouping.valid?).to be true
      end

      it 'returns membership status are part of the group' do
        student = create(:student)
        expect(@grouping.membership_status(student)).to be_nil
        expect(@grouping.membership_status(@membership.user)).to eq('accepted')
        expect(@grouping.membership_status(@inviter)).to eq('inviter')
      end

      it 'detects pending members' do
        expect(@grouping.pending?(@inviter)).to be false
      end

      it 'detects the inviter' do
        expect(@grouping.is_inviter?(@membership.user)).to be false
        expect(@grouping.is_inviter?(@inviter)).to be true
      end

      it 'is able to remove a member' do
        @grouping.remove_member(@membership.id)
        expect(@grouping.membership_status(@membership.user)).to be_nil
      end

      it 'is able to remove the inviter' do
        @grouping.remove_member(@inviter_membership.id)
        expect(@grouping.membership_status(@inviter)).to be_nil
        expect(@grouping.inviter).not_to be_nil
      end

      it 'is able to report if the grouping is deletable' do
        non_inviter = @membership.user
        # delete member to have it deletable
        @grouping.remove_member(@membership.id)
        @grouping.reload
        expect(@grouping.accepted_students.size).to eq(1)
        # inviter should not be able to delete grouping
        expect(@grouping.deletable_by?(@inviter)).to be false
        # non-inviter shouldn't be able to delete grouping
        if non_inviter.nil?
          raise 'No members in this grouping other than the inviter!'
        end
        expect(@grouping.deletable_by?(non_inviter)).to be false
      end
    end

    context 'with a pending membership' do
      before :each do
        @student = create(:student_membership,
          grouping: @grouping,
          membership_status: StudentMembership::STATUSES[:pending]).user
      end

      it 'detect pending members' do
        expect(@grouping.pending?(@student)).to be true
      end

      it 'return correct membership status' do
        expect(@grouping.membership_status(@student)).to eq('pending')
      end

      it 'be able to decline invitation' do
        @grouping.decline_invitation(@student)
        expect(@grouping.pending?(@student)).to be false
      end
    end

    context 'with a rejected membership' do
      before :each do
        @membership = create(:student_membership,
          grouping: @grouping,
          membership_status: StudentMembership::STATUSES[:rejected])
        @student = @membership.user
      end

      it 'returns correct membership status' do
        expect(@grouping.membership_status(@student)).to eq('rejected')
      end

      it 'is able to delete rejected memberships' do
        @grouping.remove_rejected(@membership.id)
        expect(@grouping.membership_status(@student)).to be_nil
      end
    end

    context 'with TAs assigned' do
      ta_count = 3
      before :each do
        @tas = Array.new(ta_count) { create(:ta) }
        @grouping.add_tas(@tas)
      end

      it 'has a ta for marking' do
        expect(@grouping.has_ta_for_marking?).to be true
      end

      it 'gets ta names' do
        expect(@grouping.get_ta_names).to match_array(@tas.map(&:user_name))
      end

      it 'is not be able to assign same TAs twice' do
        @grouping.reload
        expect(@grouping.ta_memberships.count).to eq(3)
        @grouping.add_tas(@tas)
        expect(@grouping.ta_memberships.count).to eq(3)
      end

      it 'is able to remove ta' do
        @grouping.remove_tas(@tas)
        expect(@grouping.ta_memberships.count).to eq(0)
      end
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
            txn.add(File.join(assignment_folder,
                              'Shapes.java'),
                    'shapes content',
                    'text/plain')
            unless repo.commit(txn)
              raise 'Unable to setup test!'
            end
          rescue Exception => e
            raise 'Test setup failed: ' + e.message
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
        missing_files = @grouping.missing_assignment_files
        expect(missing_files.length).to eq(1)
        expect(missing_files).to eq([@file])
        # submit another file so that we have all required files submitted
        @grouping.group.access_repo do |repo|
          txn = repo.get_transaction('markus')
          begin
            txn.add(File.join(@assignment.repository_folder,
                              @file.filename),
                    'ShapesTest content',
                    'text/plain')
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

    context 'calling has_submission? with many submissions, all with submission_version_used == false' do
      before :each do
        @submission1 = create(:submission, submission_version_used: false,
                                       grouping: @grouping)
        @submission2 = create(:submission, submission_version_used: false,
                                       grouping: @grouping)
        @submission3 = create(:submission, submission_version_used: false,
                                       grouping: @grouping)
        @grouping.reload
      end

      it 'behaves like theres no submission and return false' do
        #sort only to ensure same order of arrays
        expect(@grouping.submissions.sort{|a,b| a.id <=> b.id}).to match([@submission1, @submission2, @submission3]
                                                                           .sort{|a,b| a.id <=> b.id})
        expect(@grouping.current_submission_used).to be_nil
        expect(@grouping.has_submission?).to be false
      end
    end

    #The order in which submissions are added to the grouping matters because
    #after a submission is created, it ensures that all other submissions have
    #submission_version_used set to false.
    context 'calling has_submission? with many submissions, with the last submission added to the grouping having submission_version_used == false' do
      before :each do
        @submission1 = create(:submission, submission_version_used: true, grouping: @grouping)
        @submission2 = create(:submission, submission_version_used: false, grouping: @grouping)
        @submission3 = create(:submission, submission_version_used: true, grouping: @grouping)
        @submission4 = create(:submission, submission_version_used: false, grouping: @grouping)
        @grouping.reload
      end
      it 'behaves like there is no submission' do
        #sort only to ensure same order of arrays
        expect(@grouping.submissions.sort{|a,b| a.id <=> b.id})
          .to match_array([@submission1, @submission2, @submission3, @submission4].sort{|a,b| a.id <=> b.id})
        expect(@grouping.current_submission_used).to be_nil
        expect(@grouping.has_submission?).to be false
      end
    end

    context 'calling has_submission? with many submissions, with the last submission added to the grouping having submission_version_used == true' do
      before :each do
        @submission1 = create(:submission, submission_version_used: false, grouping: @grouping)
        @submission2 = create(:submission, submission_version_used: true, grouping: @grouping)
        @submission3 = create(:submission, submission_version_used: true, grouping: @grouping)
        @grouping.reload
      end

      it 'behaves like there is a submission' do
        #sort only to ensure same order of arrays
        expect(@grouping.submissions.sort{|a,b| a.id <=> b.id}).
          to match_array([@submission1, @submission2, @submission3].sort{|a,b| a.id <=> b.id})
        expect(@submission2.reload.submission_version_used).to be false
        expect(@grouping.current_submission_used).to eq(@submission3)
        expect(@grouping.has_submission?).to be true
      end
    end

    context 'containing multiple submissions with submission_version_used == true' do
      before :each do
        #Dont use machinist in order to bypass validation
        @submission1 = @grouping.submissions.build(submission_version_used: false,
                                                   revision_identifier: 1, revision_timestamp: 1.days.ago, submission_version: 1)
        @submission1.save(validate: false)
        @submission2 = @grouping.submissions.build(submission_version_used: true,
                                                   revision_identifier: 1, revision_timestamp: 1.days.ago, submission_version: 2)
        @submission2.save(validate: false)
        @submission3 = @grouping.submissions.build(submission_version_used: true,
                                                   revision_identifier: 1, revision_timestamp: 1.days.ago, submission_version: 3)
        @submission3.save(validate: false)
        @grouping.reload
      end

      it "sets all the submissions' submission_version_used columns to false upon creation of a new submission" do
        #sort only to ensure same order of arrays
        expect(@grouping.submissions.sort{|a,b| a.id <=> b.id}).
          to eq([@submission1, @submission2, @submission3].sort{|a,b| a.id <=> b.id})

        expect(@grouping.has_submission?).to be true
        #Make sure current_submission_used returns a single Submission, not an array
        expect(@grouping.current_submission_used.is_a?(Submission)).to be true
        @submission4 = create(:submission, submission_version_used: false, grouping: @grouping)
        @grouping.reload
        expect(@grouping.has_submission?).to be false
        expect(@submission4.submission_version).to eq(4)
        @submission5 = create(:submission, submission_version_used: true, grouping: @grouping)
        @grouping.reload
        expect(@grouping.has_submission?).to be true
        expect(@grouping.current_submission_used).to eq(@submission5)
      end
    end

    context 'A grouping without students (ie created by an admin)' do
      before :each do
        @student_01 = create(:student)
        @student_02 = create(:student)
      end

      it 'accepts to add students in any scenario possible when invoked by admin' do
        members = [@student_01.user_name, @student_02.user_name]
        @grouping.invite(members,
                         StudentMembership::STATUSES[:accepted],
                         true)
        expect(@grouping.accepted_student_memberships.count).to eq(2)
      end
    end

    context 'A grouping without students (ie created by an admin) for a assignment with section restriction' do
      before :each do
        @assignment = create(:assignment, section_due_dates_type: true)
        @grouping = create(:grouping, assignment: @assignment)
        section_01 = create(:section)
        section_02 = create(:section)
        @student_01 = create(:student, section: section_01)
        @student_02 = create(:student, section: section_02)
      end

      it 'accepts to add students to groups without checking their sections' do
        members = [@student_01.user_name, @student_02.user_name]
        @grouping.invite(members,
                         StudentMembership::STATUSES[:accepted],
                         true)
        expect(@grouping.accepted_student_memberships.count).to eq(2)
      end
    end

    context 'A grouping with students in section' do
      before :each do
        @section = create(:section)
        student  = create(:student, section: @section)
        @student_can_invite = create(:student, section: @section)
        @student_cannot_invite = create(:student)

        assignment = create(:assignment, section_groups_only: true)
        @grouping = create(:grouping, assignment: assignment)
        create(:inviter_student_membership, user: student, grouping: @grouping,
               membership_status: StudentMembership::STATUSES[:inviter])
      end

      # FAILING: @grouping.can_invite?(@student_can_invite) returns false
      it 'returns true to can invite for students of same section' do
        expect(@grouping.can_invite?(@student_can_invite)).to be true
      end

      it 'returns false to can invite for students of different section' do
        expect(@grouping.can_invite?(@student_cannot_invite)).to be false
      end
    end

    context 'Assignment has a grace period of 24 hours after due date' do
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

      context 'A grouping of one student submitting an assignment' do
        before :each do
          # grouping of only one student
          @grouping = create(:grouping, assignment: @assignment, group: @group)
          @inviter_membership = create(:inviter_student_membership, user: create(:student, user_name: 'student1'),
                                                       grouping: @grouping,
                                                       membership_status: StudentMembership::STATUSES[:inviter])
          @inviter = @inviter_membership.user

          # On July 15, the Student logs in, triggering repository folder creation
          pretend_now_is(Time.parse('July 15 2009 6:00PM')) do
            @grouping.create_grouping_repository_folder
          end
        end

        it 'does not deduct grace credits because submission is on time' do

          # Check the number of member in this grouping
          expect(@grouping.student_membership_number).to eq(1)

          submit_files_before_due_date

          # An Instructor or Grader decides to begin grading
          pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
            submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
            submission = @assignment.submission_rule.apply_submission_rule(submission)

            @grouping.reload
            # Should be no deduction because submitting on time
            expect(@grouping.grace_period_deduction_single).to eq(0)
          end
        end

        it 'deducts one grace credit' do

          # Check the number of member in this grouping
          expect(@grouping.student_membership_number).to eq(1)
          # Make sure the available grace credits are enough
          expect(@grouping.available_grace_credits).to be >= 1

          submit_files_after_due_date('July 24 2009 9:00AM', 'LateSubmission.java', 'Some overtime contents')

          # An Instructor or Grader decides to begin grading
          pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
            submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
            submission = @assignment.submission_rule.apply_submission_rule(submission)

            @grouping.reload
            # Should display 1 credit deduction because of one-day late submission
            expect(@grouping.grace_period_deduction_single).to eq(1)
          end
        end
      end # end of context "A grouping of one student submitting an assignment"

      context 'A grouping of two students submitting an assignment' do
        before :each do
          # grouping of two students
          @grouping = create(:grouping, assignment: @assignment, group: @group)
          # should consist of inviter and another student
          @membership = create(:accepted_student_membership, user: create(:student, user_name: 'student1'),
                                               grouping: @grouping,
                                               membership_status: StudentMembership::STATUSES[:accepted])

          @inviter_membership = create(:inviter_student_membership, user: create(:student, user_name: 'student2'),
                                                       grouping: @grouping,
                                                       membership_status: StudentMembership::STATUSES[:inviter])
          @inviter = @inviter_membership.user

          # On July 15, the Student logs in, triggering repository folder creation
          pretend_now_is(Time.parse('July 15 2009 6:00PM')) do
            @grouping.create_grouping_repository_folder
          end
        end

        it 'does not deduct grace credits because submission is on time' do

          # Check the number of member in this grouping
          expect(@grouping.student_membership_number).to eq(2)

          submit_files_before_due_date

          # An Instructor or Grader decides to begin grading
          pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
            submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
            submission = @assignment.submission_rule.apply_submission_rule(submission)

            @grouping.reload
            # Should be no deduction because submitting on time
            expect(@grouping.grace_period_deduction_single).to eq(0)
          end
        end

        it 'deducts one grace credit' do

          # Check the number of member in this grouping
          expect(@grouping.student_membership_number).to eq(2)
          # Make sure the available grace credits are enough
          expect(@grouping.available_grace_credits).to be >= 1

          submit_files_after_due_date('July 24 2009 9:00AM', 'LateSubmission.java', 'Some overtime contents')

          # An Instructor or Grader decides to begin grading
          pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
            submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
            submission = @assignment.submission_rule.apply_submission_rule(submission)

            @grouping.reload
            # Should display 1 credit deduction because of one-day late submission
            expect(@grouping.grace_period_deduction_single).to eq(1)
          end
        end
      end
    end
  end

  context 'submit file with testing past_due_date?' do
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
      it 'detects before due_date' do
        submit_file_at_time('July 20 2009 5:00PM', 'my_file', 'Hello, world!')
        expect(@grouping.past_due_date?).to be false
      end
    end

    context 'with sections before due date' do
      before :each do
        @assignment.section_due_dates_type = true
        @assignment.save
        @section = create(:section)
        create(:inviter_student_membership, user: create(:student, section: @section), grouping: @grouping,
               membership_status: StudentMembership::STATUSES[:inviter])
      end

      it 'detects before due_date and before section due_date' do
        SectionDueDate.create(section: @section, assignment: @assignment,
                            due_date: Time.parse('July 24 2009 5:00PM'))
        submit_file_at_time('July 20 2009 5:00PM', 'my_file', 'Hello, World!')
        expect(@grouping.past_due_date?).to be false
      end

      it 'detects before due_date and after section due_date' do
        SectionDueDate.create(section: @section, assignment: @assignment,
                            due_date: Time.parse('July 18 2009 5:00PM'))
        submit_file_at_time('July 20 2009 5:00PM', 'my_file', 'Hello, World!')
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

      it 'detects after due_date' do
        submit_file_at_time('July 28 2009 5:00PM', 'my_file', 'Hello, World!')
        expect(@grouping.past_due_date?).to be true
      end
    end

    context 'with sections after due date' do
      before :each do
        @assignment.section_due_dates_type = true
        @assignment.save
        @section = create(:section)
        create(:inviter_student_membership, user: create(:student, section: @section), grouping: @grouping,
               membership_status: StudentMembership::STATUSES[:inviter])
      end

      it 'detects after due_date and before section due_date' do
        SectionDueDate.create(section: @section, assignment: @assignment,
                            due_date: Time.parse('July 30 2009 5:00PM'))
        submit_file_at_time('July 28 2009 1:00PM', 'my_file', 'Hello, World!')
        expect(@grouping.past_due_date?).to be false
      end

      it 'detects after due_date and after section due_date' do
        SectionDueDate.create(section: @section, assignment: @assignment,
                            due_date: Time.parse('July 20 2009 5:00PM'))
        submit_file_at_time('July 28 2009 1:00PM', 'my_file', 'Hello, World!')
        expect(@grouping.past_due_date?).to be true
      end
    end
  end

  def submit_file_at_time(time, filename, text)
    pretend_now_is(Time.parse(time)) do
      @group.access_repo do |repo|
        txn = repo.get_transaction('test')
        txn = add_file_helper(txn, filename, text)
        repo.commit(txn)
      end
    end
  end

  def submit_files_before_due_date
    pretend_now_is(Time.parse('July 20 2009 5:00PM')) do
      assert Time.now < @assignment.due_date
      assert Time.now < @assignment.submission_rule.calculate_collection_time
      @group.access_repo do |repo|
        txn = repo.get_transaction('test')
        txn = add_file_helper(txn, 'TestFile.java', 'Some contents for TestFile.java')
        repo.commit(txn)
      end
    end
  end

  def submit_files_after_due_date(time, filename, text)
    pretend_now_is(Time.parse(time)) do
      assert Time.now > @assignment.due_date
      assert Time.now < @assignment.submission_rule.calculate_collection_time
      @group.access_repo do |repo|
        txn = repo.get_transaction('test')
        txn = add_file_helper(txn, filename, text)
        repo.commit(txn)
      end
    end
  end

  def add_file_helper(txn, file_name, file_contents)
    path = File.join(@assignment.repository_folder, file_name)
    txn.add(path, file_contents, '')
    txn
  end
end


