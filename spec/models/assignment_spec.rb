describe Assignment do
  describe 'ActiveRecord associations' do
    it { is_expected.to have_one(:submission_rule).dependent(:destroy) }
    it { is_expected.to validate_presence_of(:submission_rule) }
    it { is_expected.to have_many(:annotation_categories).dependent(:destroy) }
    it { is_expected.to have_many(:groupings) }
    it { is_expected.to have_many(:ta_memberships).through(:groupings) }
    it { is_expected.to have_many(:student_memberships).through(:groupings) }
    it { is_expected.to have_many(:submissions).through(:groupings) }
    it { is_expected.to have_many(:groups).through(:groupings) }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:section_due_dates) }
    it { is_expected.to accept_nested_attributes_for(:section_due_dates) }
    it { is_expected.to have_one(:assignment_stat).dependent(:destroy) }
    it do
      is_expected.to have_many(:rubric_criteria).dependent(:destroy).order(:position)
    end
    it do
      is_expected.to have_many(:flexible_criteria).dependent(:destroy).order(:position)
    end

    it { is_expected.to have_many(:assignment_files).dependent(:destroy) }
    it { is_expected.to have_many(:test_groups).dependent(:destroy) }
    it do
      is_expected.to accept_nested_attributes_for(:assignment_files).allow_destroy(true)
    end
    it do
      is_expected.to have_many(:criterion_ta_associations).dependent(:destroy)
    end
    it do
      is_expected.to accept_nested_attributes_for(:submission_rule).allow_destroy(true)
    end
    it do
      is_expected.to accept_nested_attributes_for(:assignment_stat).allow_destroy(true)
    end
  end

  describe 'ActiveModel validations' do
    it { is_expected.to validate_presence_of(:short_identifier) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:due_date) }
    it { is_expected.to belong_to(:parent_assignment).class_name('Assignment') }
    it { is_expected.to have_one(:pr_assignment).class_name('Assignment') }

    describe 'Validation of basic infos of an assignment' do
      let(:assignment) { :assignment }

      before :each do
        @assignment = create(:assignment)
      end

      it 'should create a valid assignment' do
        expect(@assignment).to be_valid
      end

      it 'should require case sensitive unique value for short_identifier' do
        expect(@assignment).to validate_uniqueness_of(:short_identifier)
      end
      it 'should have a nil parent_assignment by default' do
        expect(@assignment.parent_assignment).to be_nil
      end
      it 'should have a nil peer_review by default' do
        expect(@assignment.pr_assignment).to be_nil
      end
      it 'should not be a peer review if there is no parent_assessment_id' do
        expect(@assignment.parent_assessment_id).to be_nil
        expect(@assignment.is_peer_review?).to be false
      end
    end

    it 'should catch an invalid date' do
      assignment = create(:assignment, due_date:'2020/02/31')  # 31st day of february
      expect(assignment.due_date).not_to eq '2020/02/31'
    end
    it 'should be a peer review if it has a parent_assessment_id' do
      parent_assignment = create(:assignment)
      assignment = create(:assignment, parent_assignment: parent_assignment)
      expect(assignment.is_peer_review?).to be true
      expect(parent_assignment.is_peer_review?).to be false
    end
    it 'should give a true has_peer_review_assignment result if it does' do
      parent_assignment = create(:assignment)
      assignment = create(:assignment, parent_assignment: parent_assignment)
      expect(parent_assignment.has_peer_review_assignment?).to be true
      expect(assignment.has_peer_review_assignment?).to be false
    end
    it 'should find children assignments when they reference the parent' do
      parent_assignment = create(:assignment)
      assignment = create(:assignment, parent_assignment: parent_assignment)
      expect(parent_assignment.pr_assignment.id).to be assignment.id
      expect(assignment.parent_assignment.id).to be parent_assignment.id
    end
    it 'should not allow the short_identifier to be updated' do
      assignment = create(:assignment)
      assignment.short_identifier = assignment.short_identifier + 'something'
      expect(assignment).not_to be_valid
    end
    it 'should not allow the repository_folder to be updated' do
      assignment = create(:assignment)
      assignment.assignment_properties.repository_folder = assignment.assignment_properties.repository_folder + 'something'
      expect(assignment).not_to be_valid
    end
  end

  describe '#clone_groupings_from' do
    it 'makes an attempt to update repository permissions when cloning groupings' do
      a1 = create(:assignment, assignment_properties_attributes: { vcs_submit: true })
      a2 = create(:assignment, assignment_properties_attributes: { vcs_submit: true })
      create :grouping_with_inviter, assignment: a2
      expect(Repository.get_class).to receive(:update_permissions_after)
      a1.clone_groupings_from(a2.id)
    end
  end

  describe '#tas' do
    before :each do
      @assignment = create(:assignment)
    end

    context 'when no TAs have been assigned' do
      it 'returns an empty array' do
        expect(@assignment.tas).to eq []
      end
    end

    context 'when TA(s) have been assigned to an assignment' do
      before :each do
        @grouping = create(:grouping, assignment: @assignment)
        @ta = create(:ta)
        @ta_membership = create(:ta_membership, user: @ta, grouping: @grouping)
      end

      describe 'one TA' do
        it 'returns the TA' do
          expect(@assignment.tas).to eq [@ta]
        end

        context 'when no criteria are found' do
          it 'returns an empty list of criteria' do
            expect(@assignment.get_criteria).to be_empty
          end

          context 'a submission and result are created' do
            before do
              @submission = create(:submission, grouping: @grouping)
              @result = create(:incomplete_result, submission: @submission)
            end

            it 'has no marks' do
              expect(@result.marks.length).to eq(0)
            end

            it 'gets a subtotal' do
              expect(@result.get_subtotal).to eq(0)
            end
          end
        end

        context 'when rubric criteria are found' do
          before do
            @ta_criteria = Array.new(2) { create(:rubric_criterion, assignment: @assignment) }
            @peer_criteria = Array.new(2) { create(:rubric_criterion,
                                                   assignment: @assignment,
                                                   ta_visible: false,
                                                   peer_visible: true)
            }
            @ta_and_peer_criteria = Array.new(2) { create(:rubric_criterion,
                                                          assignment: @assignment,
                                                          peer_visible: true)
            }
          end

          it 'shows the criteria visible to tas only' do
            expect(@assignment.get_criteria(:ta).select(&:id)).to match_array(@ta_criteria.select(&:id) +
                                                                                @ta_and_peer_criteria.select(&:id))
          end

          context 'a submission and a result are created' do
            before do
              @submission = create(:submission, grouping: @grouping)
              @result = create(:incomplete_result, submission: @submission)
            end

            it 'creates marks for visible criteria only' do
              expect(@result.marks.length).to eq(4)
            end

            context 'when marks are entered' do
              before do
                result_mark = @result.marks.first
                result_mark.mark = 2.0
                result_mark.save
              end

              it 'gets a subtotal' do
                expect(@result.get_subtotal).to eq(2)
              end

              it 'gets a relative max_mark' do
                expect(@assignment.max_mark).to eq(16)
              end
            end
          end
        end
      end

      describe 'more than one TA' do
        before :each do
          @other_ta = create(:ta)
          @ta_membership =
            create(:ta_membership, user: @other_ta, grouping: @grouping)
        end

        it 'returns all TAs' do
          expect(@assignment.tas).to match_array [@ta, @other_ta]
        end
      end
    end
  end

  describe '#group_assignment?' do
    context 'when invalid_override is allowed' do
      let(:assignment) { build(:assignment, assignment_properties_attributes: { invalid_override: true }) }

      it 'returns true' do
        expect(assignment.group_assignment?).to be true
      end
    end

    context 'when invalid_override is not allowed ' do
      context 'and group_max is greater than 1' do
        let(:assignment) do
          build(:assignment, assignment_properties_attributes: { group_max: 2 })
        end

        it 'returns true' do
          expect(assignment.group_assignment?).to be true
        end
      end

      context 'and group_max is 1' do
        let(:assignment) do
          build(:assignment)
        end

        it 'returns false' do
          expect(assignment.group_assignment?).to be false
        end
      end
    end
  end

  describe '#add_group' do
    context 'when the group name is autogenerated' do
      before :each do
        @assignment = create(:assignment) # Default 'group_name_autogenerated' is true
      end

      it 'adds a group and returns the new grouping' do
        expect(@assignment.add_group).to be_a Grouping
        expect(Group.count).to eq 1
      end
    end

    context 'when the the group name is not autogenerated' do
      before :each do
        @assignment = create(:assignment,
                             assignment_properties_attributes: { group_name_autogenerated: false })
        @group_name = 'a_group_name'
      end

      it 'adds a group with the given name and returns the new grouping' do
        grouping = @assignment.add_group(@group_name)
        group = @assignment.groups.where(group_name: @group_name).first

        expect(grouping).to be_a Grouping
        expect(group).to be_a Group
      end

      context 'and a group with the same name exists' do
        before :each do
          @group = create(:group, group_name: @group_name)
        end

        context 'for this assignment' do
          before :each do
            create(:grouping, assignment: @assignment, group: @group)
          end

          it 'raises an exception' do
            expect { @assignment.add_group(@group_name) }.to raise_error
          end
        end

        context 'for another assignment' do
          before :each do
            assignment = create(:assignment)
            create(:grouping, assignment: assignment, group: @group)
          end

          it 'adds the group and returns the new grouping' do
            grouping = @assignment.add_group(@group_name)
            group = @assignment.groups.where(group_name: @group_name).first

            expect(grouping).to be_a Grouping
            expect(group).to be_a Group
          end
        end
      end
    end
  end

  describe '#valid_groupings and #invalid_groupings' do
    before :each do
      @assignment = create(:assignment)
      @groupings = Array.new(2) { create(:grouping, assignment: @assignment) }
    end

    context 'when no groups are valid' do
      it '#valid_groupings returns an empty array' do
        expect(@assignment.valid_groupings).to eq []
      end

      it '#invalid_groupings returns all groupings' do
        expect(@assignment.invalid_groupings).to match_array(@groupings)
      end
    end

    context 'when one group is valid' do
      context 'due to admin_approval' do
        before :each do
          @groupings.first.update_attribute(:admin_approved, true)
        end

        it '#valid_groupings returns the valid group' do
          expect(@assignment.valid_groupings).to eq [@groupings.first]
        end

        it '#invalid_groupings returns other, invalid groups' do
          expect(@assignment.invalid_groupings)
            .to match_array(@groupings.drop(1))
        end
      end

      context 'due to meeting min size requirement' do
        before :each do
          create(:accepted_student_membership, grouping: @groupings.first)
        end

        it '#valid_groupings returns the valid group' do
          expect(@assignment.valid_groupings).to eq [@groupings.first]
        end

        it '#invalid_groupings returns other, invalid groups' do
          expect(@assignment.invalid_groupings)
            .to match_array(@groupings.drop(1))
        end
      end
    end

    context 'when all groups are valid' do
      before :each do
        @groupings.each do |grouping|
          create(:accepted_student_membership, grouping: grouping)
        end
      end

      it '#valid_groupings returns all groupings' do
        expect(@assignment.valid_groupings).to match_array(@groupings)
      end

      it '#invalid_groupings returns an empty array' do
        expect(@assignment.invalid_groupings).to eq []
      end
    end
  end

  describe '#grouped_students' do
    before :each do
      @assignment = create(:assignment)
      @grouping = create(:grouping, assignment: @assignment)
    end

    context 'when no students are grouped' do
      it 'returns an empty array' do
        expect(@assignment.grouped_students).to eq []
      end
    end

    context 'when students are grouped' do
      before :each do
        @student = create(:student)
        @membership = create(:accepted_student_membership,
                             user: @student,
                             grouping: @grouping)
      end

      describe 'one student' do
        it 'returns the student' do
          expect(@assignment.grouped_students).to eq [@student]
        end
      end

      describe 'more than one student' do
        before :each do
          @other_student = create(:student)
          @other_membership = create(:accepted_student_membership, user: @other_student, grouping: @grouping)
        end

        it 'returns the students' do
          expect(@assignment.grouped_students)
            .to match_array [@student, @other_student]
        end
      end
    end
  end

  describe '#ungrouped_students' do
    before :each do
      @assignment = create(:assignment)
      @grouping = create(:grouping, assignment: @assignment)
      @students = Array.new(2) { create(:student) }
    end

    context 'when all students are ungrouped' do
      it 'returns all of the students' do
        expect(@assignment.ungrouped_students).to match_array(@students)
      end
    end

    context 'when no students are ungrouped' do
      before :each do
        @students.each do |student|
          create(:accepted_student_membership, user: student, grouping: @grouping)
        end
      end

      it 'returns an empty array' do
        expect(@assignment.ungrouped_students).to eq []
      end
    end
  end

  describe '#assigned_groupings and #unassigned_groupings' do
    before :each do
      @assignment = create(:assignment)
    end

    context 'when there are no groupings' do
      it '#assigned_groupings and #unassigned_groupings returns no groupings' do
        expect(@assignment.assigned_groupings).to eq []
        expect(@assignment.unassigned_groupings).to eq []
      end
    end

    context 'when there are multiple groupings' do
      before :each do
        @groupings = Array.new(2) { create(:grouping, assignment: @assignment) }
      end

      context 'and no TAs have been assigned' do
        it '#assigned_groupings returns no groupings' do
          expect(@assignment.assigned_groupings).to eq []
        end

        it '#unassigned_groupings returns all groupings' do
          expect(@assignment.unassigned_groupings).to match_array(@groupings)
        end
      end

      context 'and multiple TAs are assigned to one grouping' do
        before :each do
          2.times do
            create(:ta_membership, grouping: @groupings[0], user: create(:ta))
          end
        end

        it '#assigned_groupings returns that grouping' do
          expect(@assignment.assigned_groupings).to eq [@groupings.first]
        end

        it '#unassigned_groupings returns the other groupings' do
          expect(@assignment.unassigned_groupings)
            .to match_array(@groupings.drop(1))
        end
      end

      context 'and all groupings have a TA assigned' do
        before :each do
          @groupings.each do |grouping|
            create(:ta_membership, grouping: grouping, user: create(:ta))
          end
        end

        it '#assigned_groupings returns all groupings' do
          expect(@assignment.assigned_groupings).to match_array(@groupings)
        end

        it '#unassigned_groupings returns no groupings' do
          expect(@assignment.unassigned_groupings).to eq []
        end
      end
    end
  end

  context 'A past due assignment with No Late submission rule' do
    context 'without sections' do
      before(:each) do
        @assignment = create(:assignment, due_date: 2.days.ago)
      end

      it 'return the last due date' do
        expect(@assignment.latest_due_date.day).to eq(2.days.ago.day)
      end

      it 'return true on past_collection_date? call' do
        expect(@assignment.past_collection_date?).to be_truthy
      end
    end

    context 'with a section' do
      before(:each) do
        @assignment = create(:assignment,
                             due_date: 2.days.ago,
                             assignment_properties_attributes: { section_due_dates_type: true })
        @section = create(:section, name: 'section_name')
        create(:section_due_date, section: @section, assignment: @assignment, due_date: 1.day.ago)
        student = create(:student, section: @section)
        @grouping = create(:grouping, assignment: @assignment)
        create(:student_membership,
               grouping: @grouping,
               user: student,
               membership_status: StudentMembership::STATUSES[:inviter])
      end

      it 'return the normal due date for section due date' do
        expect @assignment.section_due_date(@section)
      end

      context 'another' do
        before(:each) do
          @section = create(:section, name: 'section_name2')
          create(:section_due_date, section: @section, assignment: @assignment, due_date: 1.day.ago)
          student = create(:Student, section: @section)
          @grouping = create(:grouping, assignment: @assignment)
          create(:StudentMembership,
                 grouping: @grouping,
                 user: student,
                 membership_status: StudentMembership::STATUSES[:inviter])
        end
      end
    end
  end

  context 'A before due assignment with No Late submission rule' do
    before(:each) do
      @assignment = create(:assignment, due_date: 2.days.from_now)
    end

    it 'return false on past_collection_date? call' do
      expect !@assignment.past_collection_date?
    end
  end

  describe '#past_remark_due_date?' do
    context 'before the remark due date' do
      let(:assignment) { build(:assignment, assignment_properties_attributes: { remark_due_date: 1.days.from_now }) }

      it 'returns false' do
        expect(assignment.past_remark_due_date?).to be false
      end
    end

    context 'after the remark due date' do
      let(:assignment) { build(:assignment, assignment_properties_attributes: { remark_due_date: 1.days.ago }) }

      it 'returns true' do
        expect(assignment.past_remark_due_date?).to be true
      end
    end
  end

  context 'An Assignment' do
    let(:assignment) { create :assignment }
    before :each do
      @assignment = create(:assignment,
                           assignment_properties_attributes: {
                             group_name_autogenerated: false,
                             group_max: 2
                           })
    end

    context 'as a noteable' do
      it 'display for note without seeing an exception' do
        assignment = create(:assignment)
        assignment.display_for_note
      end
    end

    context 'with a student in a group with a marked submission' do
      before :each do
        @membership = create(:student_membership,
                             grouping: create(:grouping, assignment: @assignment),
                             membership_status: StudentMembership::STATUSES[:accepted])
        sub = create(:submission, grouping: @membership.grouping)
        @result = sub.get_latest_result

        @sum = 0
        [2, 2.7, 2.2, 2].each do |weight|
          create(:mark,
                 mark: 4,
                 result: @result,
                 markable: create(:rubric_criterion, assignment: @assignment, max_mark: weight * 4))
          @sum += weight
        end
        @total = @sum * 4
      end

      it 'return the correct maximum mark for rubric criteria' do
        expect(@total).to eq @assignment.max_mark
      end

      it 'return the correct group for a given student' do
        expect(@membership.grouping.group).to eq(@assignment.group_by(@membership.user).group)
      end
    end

    context 'with some groupings with students and TAs assigned' do
      before :each do
        5.times do
          grouping = create(:grouping, assignment: @assignment)
          3.times do
            create(:student_membership,
                   grouping: grouping,
                   membership_status: StudentMembership::STATUSES[:accepted])
          end
          create(:ta_membership,
                 grouping: grouping,
                 membership_status: StudentMembership::STATUSES[:accepted])
        end
      end

      it "be able to have it's groupings cloned correctly" do
        clone = create(:assignment)
        number = StudentMembership.all.size + TaMembership.all.size
        clone.clone_groupings_from(@assignment.id)
        clone.groupings.reload  # clone.groupings needs to be "reloaded" to obtain the updated value (5 groups created)
        expect(@assignment.assignment_properties.group_min).to eql(clone.assignment_properties.group_min)
        expect(@assignment.assignment_properties.group_max).to eql(clone.assignment_properties.group_max)
        expect(@assignment.groupings.size).to eql(clone.groupings.size)
        # Since we clear between each test, there should be twice as much as previously
        expect(2 * number).to eql(StudentMembership.all.size + TaMembership.all.size)
      end
    end
    context 'with a group with 3 accepted students' do
      before :each do
        @grouping = create(:grouping, assignment: @assignment)
        @members = []
        3.times do
          @members.push create(:student_membership,
                               membership_status: StudentMembership::STATUSES[:accepted],
                               grouping: @grouping)
        end
        @source = @assignment
        @group =  @grouping.group
      end
      context 'with another fresh assignment' do
        before :each do
          @target = create(:assignment)
        end

        it 'clone all three members if none are hidden' do
          @target.clone_groupings_from(@source.id)
          3.times do |index|
            expect @members[index].user.has_accepted_grouping_for?(@target.id)
          end
          @group.groupings.reload
          expect(@group.groupings.find_by_assessment_id(@target.id)).not_to be_nil
        end

        it 'ignore a blocked student during cloning' do
          student = @members[0].user
          # hide the student
          student.hidden = true
          student.save
          # clone the groupings
          @target.clone_groupings_from(@source.id)
          # make sure the membership wasn't created for the hidden
          # student
          expect(student.has_accepted_grouping_for?(@target.id)).to be_falsey
          # and let's make sure that the other memberships were cloned
          expect(@members[1].user.has_accepted_grouping_for?(@target.id)).to be_truthy
          expect(@members[2].user.has_accepted_grouping_for?(@target.id)).to be_truthy
          expect(@group.groupings.find_by_assessment_id(@target.id)).not_to be_nil
        end

        it 'ignore two blocked students during cloning' do
          # hide the students
          @members[0].user.hidden = true
          @members[0].user.save
          @members[1].user.hidden = true
          @members[1].user.save
          # clone the groupings
          @target.clone_groupings_from(@source.id)
          # make sure the membership wasn't created for the hidden student
          expect(@members[0].user.has_accepted_grouping_for?(@target.id)).not_to be_truthy
          expect(@members[1].user.has_accepted_grouping_for?(@target.id)).not_to be_truthy
          # and let's make sure that the other membership was cloned
          expect @members[2].user.has_accepted_grouping_for?(@target.id)
          # and that the proper grouping was created
          expect(@group.groupings.find_by_assessment_id(@target.id)).not_to be_nil
        end

        it 'ignore grouping if all students hidden' do
          # hide all students
          3.times do |index|
            @members[index].user.hidden = true
            @members[index].user.save
          end

          # Get the Group that these students belong to for assignment_1
          expect @members[0].user.has_accepted_grouping_for?(@source.id)
          # clone the groupings
          @target.clone_groupings_from(@source.id)
          # make sure the membership wasn't created for hidden students
          3.times do |index|
            expect(@members[index].user.has_accepted_grouping_for?(@target.id)).to be_falsey
          end
          # and let's make sure that the grouping wasn't cloned
          expect(@group.groupings.find_by_assessment_id(@target.id)).to be_nil
        end
      end

      context 'with an assignment with other groupings' do
        before :each do
          @target = create(:assignment)
          3.times do
            target_grouping = create(:grouping, assignment: @target)
            create(:student_membership,
                   membership_status: StudentMembership::STATUSES[:accepted],
                   grouping: target_grouping)
          end
        end
        it 'destroy all previous groupings if cloning was successful' do
          old_groupings = @target.groupings
          @target.clone_groupings_from(@source.id)
          old_groupings.each do |old_grouping|
            expect(@target.groupings.include?(old_grouping)).to be_falsey
          end
        end
      end
    end

    context 'tests on methods returning groups repos' do
      before :each do
        @assignment = create(:assignment,
                             due_date: 2.days.ago,
                             created_at: 42.days.ago,
                             assignment_properties_attributes: { invalid_override: true })
      end

      def grouping_count(groupings)
        submissions = 0
        groupings.each do |grouping|
          if grouping.current_submission_used
            submissions += 1
          end
        end
        submissions
      end

      context 'with a grouping that has a submission and a TA assigned ' do
        before :each do
          @grouping = create(:grouping, assignment: @assignment)
          @tamembership = create(:ta_membership, grouping: @grouping)
          @studentmembership = create(:student_membership,
                                      grouping: @grouping,
                                      membership_status: StudentMembership::STATUSES[:inviter])
          @submission = create(:submission, grouping: @grouping)
        end

        it 'be able to get a list of repository access URLs for each group' do
          expected_string = ''
          @assignment.groupings.each do |grouping|
            group = grouping.group
            expected_string += [group.group_name, group.repository_external_access_url].to_csv
          end
          expect(expected_string).to eql(@assignment.get_repo_list), 'Repo access url list string is wrong!'
        end

        context 'with two groups of a single student each' do
          before :each do
            2.times do
              g = create(:grouping, assignment: @assignment)
              # StudentMembership.make({grouping: g,membership_status: StudentMembership::STATUSES[:inviter] } )
              s = create(:submission, grouping: g)
              r = s.get_latest_result
              2.times do
                create(:rubric_mark, result: r)  # this is create marks under rubric criterion
                # if we create(:flexible_mark, groping: g)
                # or create(:checkbox_mark, grouping: g)
                # they should work as well
              end
              r.reload
              r.marking_state = Result::MARKING_STATES[:complete]
              r.save
            end
          end

          it 'be able to get_repo_checkout_commands' do
            submissions = grouping_count(@assignment.groupings) # filter out without submission
            expect(submissions).to eql @assignment.get_repo_checkout_commands.size
          end

          it 'be able to get_repo_checkout_commands with spaces in group name ' do
            Group.all.each do |group|
              group.group_name = group.group_name + ' Test'
              group.save
            end
            submissions = grouping_count(@assignment.groupings) # filter out without submission
            expect(submissions).to eql @assignment.get_repo_checkout_commands.size
          end
        end

        context 'with two groups of a single student each with multiple submission' do
          before :each do
            2.times do
              g = create(:grouping, assignment: @assignment)
              # create 2 submission for each group
              2.times do
                s = create(:submission, grouping: g)
                r = s.get_latest_result
                2.times do
                  create(:rubric_mark, result: r)
                end
                r.reload
                r.marking_state = Result::MARKING_STATES[:complete]
                r.save
              end
              g.save
            end
          end

          it 'be able to get_repo_checkout_commands' do
            submissions = grouping_count(@assignment.groupings) # filter out without submission
            expect(submissions).to eql @assignment.get_repo_checkout_commands.size
          end
        end
      end
    end
  end

  describe '#current_submissions_used' do
    before :each do
      @assignment = create(:assignment)
    end

    context 'when no groups have made a submission' do
      it 'returns an empty array' do
        expect(@assignment.current_submissions_used).to eq []
      end
    end

    context 'when one group has submitted' do
      before :each do
        @grouping = create(:grouping, assignment: @assignment)
      end

      describe 'once' do
        before :each do
          create(:version_used_submission, grouping: @grouping)
          @grouping.reload
        end

        it 'returns the group\'s submission' do
          expect(@assignment.current_submissions_used).to eq [@grouping.current_submission_used]
        end
      end

      describe 'more than once' do
        before :each do
          create(:submission, grouping: @grouping)
          create(:version_used_submission, grouping: @grouping)
          @grouping.reload
        end

        it 'returns the group\'s collected submission' do
          expect(@assignment.current_submissions_used).to eq [@grouping.current_submission_used]
        end
      end
    end

    context 'when multiple groups have submitted' do
      before :each do
        @groupings = Array.new(2) { create(:grouping, assignment: @assignment) }
        @groupings.each do |group|
          create(:version_used_submission, grouping: group)
          group.reload
        end
      end

      it 'returns those groups' do
        expect(@assignment.current_submissions_used)
          .to match_array(@groupings.map(&:current_submission_used))
      end
    end
  end

  describe '#ungraded_submission_results' do
    before :each do
      @assignment = create(:assignment)
      @student = create(:student)
      @grouping = create(:grouping, assignment: @assignment, inviter: @student)
      @submission = create(:version_used_submission, grouping: @grouping)
      @other_student = create(:student)
      @other_grouping = create(:grouping, assignment: @assignment, inviter: @other_student)
      @other_submission =
        create(:version_used_submission, grouping: @other_grouping)
    end

    context 'when no submissions have been graded' do
      it 'returns the submissions' do
        expect(@assignment.ungraded_submission_results.size).to eq 2
      end
    end

    context 'when submission(s) have been graded' do
      before :each do
        @result = @submission.current_result
        @result.marking_state = Result::MARKING_STATES[:complete]
        @result.save
      end

      describe 'one submission' do
        it 'does not return the graded submission' do
          expect(@assignment.ungraded_submission_results.size).to eq 1
        end
      end

      describe 'all submissions' do
        before :each do
          @other_result = @other_submission.current_result
          @other_result.marking_state = Result::MARKING_STATES[:complete]
          @other_result.save
        end

        it 'returns all of the results' do
          expect(@assignment.ungraded_submission_results.size).to eq 0
        end
      end
    end
  end

  describe '#display_for_note' do
    it 'display for note without seeing an exception' do
      @assignment = create(:assignment)
      expect { @assignment.display_for_note }.not_to raise_error
    end
  end

  describe '#section_due_date' do
    context 'with SectionDueDates disabled' do
      before :each do
        @assignment = create(:assignment, due_date: Time.now) # Default 'section_due_dates_type' is false
      end

      context 'when no section is specified' do
        it 'returns the due date of the assignment' do
          expect(@assignment.section_due_date(nil)).to eq @assignment.due_date
        end
      end

      context 'when a section is specified' do
        it 'returns the due date of the assignment' do
          section = create(:section)
          expect(@assignment.section_due_date(section)).to eq @assignment.due_date
        end
      end
    end

    context 'with SectionDueDates enabled' do
      before :each do
        @assignment = create(:assignment,
                             due_date: 1.days.ago,
                             assignment_properties_attributes: { section_due_dates_type: true })
      end

      context 'when no section is specified' do
        it 'returns the due date of the assignment' do
          expect(@assignment.section_due_date(nil).day).to eq 1.days.ago.day
        end
      end

      context 'when a section is specified' do
        before :each do
          @section = create(:section)
        end

        context 'that does not have a SectionDueDate' do
          it 'returns the due date of the assignment' do
            section_due_date = @assignment.section_due_date(@section)
            expect(section_due_date.day).to eq 1.days.ago.day
          end
        end

        context 'that has a SectionDueDate for another assignment' do
          before :each do
            SectionDueDate.create(section: @section, assignment: create(:assignment), due_date: 2.days.ago)
          end

          it 'returns the due date of the assignment' do
            section_due_date = @assignment.section_due_date(@section)
            expect(section_due_date.day).to eq 1.days.ago.day
          end
        end

        context 'that has a SectionDueDate for this assignment' do
          before :each do
            SectionDueDate.create(section: @section, assignment: @assignment, due_date: 2.days.ago)
          end

          it 'returns the due date of the section' do
            section_due_date = @assignment.section_due_date(@section)
            expect(section_due_date.day).to eq 2.days.ago.day
          end
        end
      end
    end
  end

  describe '#latest_due_date' do
    context 'when SectionDueDates are disabled' do
      before :each do
        @assignment = create(:assignment, due_date: Time.now) # Default 'section_due_dates_type' is false
      end

      it 'returns the due date of the assignment' do
        expect(@assignment.latest_due_date).to eq @assignment.due_date
      end
    end

    context 'when SectionDueDates are enabled' do
      before :each do
        @assignment = create(:assignment,
                             due_date: Time.now,
                             assignment_properties_attributes: { section_due_dates_type: true })
      end

      context 'and there are no SectionDueDates' do
        it 'returns the due date of the assignment' do
          expect(@assignment.latest_due_date).to eq @assignment.due_date
        end
      end

      context 'and a SectionDueDate has the latest due date' do
        before :each do
          @section_due_date = SectionDueDate.create(section: create(:section),
                                                    assignment: @assignment,
                                                    due_date: 1.days.from_now)
        end

        it 'returns the due date of that SectionDueDate' do
          due_date1 = @assignment.latest_due_date
          due_date2 = @section_due_date.due_date
          expect(due_date1).to same_time_within_ms due_date2
        end
      end

      context 'and the assignment has the latest due date' do
        before :each do
          @section_due_date = SectionDueDate.create(section: create(:section),
                                                    assignment: @assignment,
                                                    due_date: 1.days.ago)
        end

        it 'returns the due date of the assignment' do
          expect(@assignment.latest_due_date).to eq @assignment.due_date
        end
      end
    end
  end

  describe '#past_all_due_dates?' do
    context 'when the assignment is not past due' do
      before :each do
        @assignment = create(:assignment, due_date: 1.days.from_now)
      end

      context 'and SectionDueDates are disabled' do
        before :each do
          @assignment.assignment_properties.update(section_due_dates_type: false)
        end

        it 'returns false' do
          expect(@assignment.past_all_due_dates?).to be false
        end
      end

      context 'and there are SectionDueDates past due' do
        before :each do
          @assignment.assignment_properties.update(section_due_dates_type: true)
          @section_due_date = SectionDueDate.create(section: create(:section),
                                                    assignment: @assignment,
                                                    due_date: 1.days.ago)
          puts @section_due_date.inspect
        end

        it 'returns false' do
          expect(@assignment.past_all_due_dates?).to be false
        end
      end
    end

    context 'when the assignment is past due' do
      before :each do
        @assignment = create(:assignment, due_date: 1.days.ago)
      end

      context 'and SectionDueDates are disabled' do
        before :each do
          @assignment.assignment_properties.update(section_due_dates_type: false)
        end

        it 'returns true' do
          expect(@assignment.past_all_due_dates?).to be true
        end
      end

      context 'and there is a SectionDueDate not past due' do
        before :each do
          @assignment.assignment_properties.update(section_due_dates_type: true)
          SectionDueDate.create(section: create(:section), assignment: @assignment, due_date: 1.days.from_now)
        end

        it 'returns false' do
          expect(@assignment.past_all_due_dates?).to be false
        end
      end
    end
  end

  describe '#grouping_past_due_date?' do
    context 'with SectionDueDates disabled' do
      before :each do
        @due_assignment = create(:assignment, due_date: 1.days.ago)
        @not_due_assignment = create(:assignment, due_date: 1.days.from_now)
      end

      context 'when no grouping is specified' do
        it 'returns based on due date of the assignment' do
          expect(@due_assignment.grouping_past_due_date?(nil)).to be true
          expect(@not_due_assignment.grouping_past_due_date?(nil)).to be false
        end
      end

      context 'when a grouping is specified' do
        it 'returns based on due date of the assignment' do
          due_grouping = create(:grouping, assignment: @due_assignment)
          not_due_grouping = create(:grouping, assignment: @not_due_assignment)
          expect(@due_assignment.grouping_past_due_date?(due_grouping)).to be true
          expect(@not_due_assignment.grouping_past_due_date?(not_due_grouping))
            .to be false
        end
      end
    end

    context 'with SectionDueDates enabled' do
      before :each do
        @assignment = create(:assignment, assignment_properties_attributes: { section_due_dates_type: true })
      end

      context 'when no grouping is specified' do
        it 'returns based on due date of the assignment' do
          @assignment.update(due_date: 1.days.ago)
          expect(@assignment.grouping_past_due_date?(nil)).to be true
          @assignment.update(due_date: 1.days.from_now)
          expect(@assignment.grouping_past_due_date?(nil)).to be false
        end
      end

      context 'when a grouping is specified' do
        before :each do
          @grouping = create(:grouping, assignment: @assignment)
          @section = create(:section)
          student = create(:student, section: @section)
          create(:inviter_student_membership, user: student, grouping: @grouping)
        end

        context 'that does not have an associated SectionDueDate' do
          it 'returns based on due date of the assignment' do
            @assignment.update(due_date: 1.days.ago)
            expect(@assignment.grouping_past_due_date?(@grouping)).to be true
            @assignment.update(due_date: 1.days.from_now)
            expect(@assignment.grouping_past_due_date?(@grouping)).to be false
          end
        end

        context 'that has an associated SectionDueDate' do
          before :each do
            @section_due_date = SectionDueDate.create(section: @section,
                                                      assignment: @assignment)
          end
          it 'returns based on the SectionDueDate of the grouping' do
            @section_due_date.update(due_date: 1.days.from_now)
            @assignment.update(due_date: 1.days.ago)
            expect(@assignment.grouping_past_due_date?(@grouping)).to be false

            @section_due_date.update(due_date: 1.days.ago)
            @assignment.update(due_date: 1.days.from_now)
            expect(@assignment.grouping_past_due_date?(@grouping)).to be true
          end
        end
      end
    end
  end

  describe '#section_names_past_due_date' do
    context 'with SectionDueDates disabled' do
      before :each do
        @assignment = create(:assignment) # Default 'section_due_dates_type' is false
      end

      context 'when the assignment is past due' do
        it 'returns one name for the assignment' do
          @assignment.update(due_date: 1.days.ago)

          expect(@assignment.section_names_past_due_date).to eq []
        end
      end

      context 'when the assignment is not past due' do
        it 'returns an empty array' do
          @assignment.update(due_date: 1.days.from_now)

          expect(@assignment.section_names_past_due_date).to eq []
        end
      end
    end

    context 'with SectionDueDates enabled' do
      before :each do
        @assignment = create(:assignment, assignment_properties_attributes: { section_due_dates_type: true })
      end

      describe 'one SectionDueDate' do
        before :each do
          @section = create(:section)
          @section_due_date =
            SectionDueDate.create(section: @section, assignment: @assignment)
        end

        context 'that is past due' do
          it 'returns an array with the name of the section' do
            @section_due_date.update(due_date: 1.days.ago)

            expect(@assignment.section_names_past_due_date)
              .to eq [@section.name]
          end
        end

        context 'that is not past due' do
          it 'returns an empty array' do
            @section_due_date.update(due_date: 1.days.from_now)

            expect(@assignment.section_names_past_due_date).to eq []
          end
        end
      end

      describe 'two SectionDueDates' do
        before :each do
          @sections = Array.new(2) { create(:section) }
          @section_due_dates = @sections.map do |section|
            SectionDueDate.create(section: section, assignment: @assignment)
          end
          @section_names = @sections.map { |section| section.name }
        end

        context 'where both are past due' do
          it 'returns an array with both section names' do
            @section_due_dates.each do |section_due_date|
              section_due_date.update(due_date: 1.days.ago)
            end

            expect(@assignment.section_names_past_due_date)
              .to match_array @section_names
          end
        end

        context 'where one is past due' do
          it 'returns an array with the name of that section' do
            @section_due_dates.first.update(due_date: 1.days.ago)
            @section_due_dates.last.update(due_date: 1.days.from_now)

            expect(@assignment.section_names_past_due_date)
              .to eq [@section_names.first]
          end
        end

        context 'where neither is past due' do
          it 'returns an empty array' do
            @section_due_dates.each do |section_due_date|
              section_due_date.update(due_date: 1.days.from_now)
            end

            expect(@assignment.section_names_past_due_date).to eq []
          end
        end
      end
    end
  end

  describe '#grade_distribution_array' do
    before :each do
      @assignment = create(:assignment)
      5.times { create(:rubric_criterion, assignment: @assignment) }
    end

    context 'when there are no submitted marks' do
      it 'returns the correct distribution' do
        expect(@assignment.grade_distribution_array)
          .to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        expect(@assignment.grade_distribution_array(10))
          .to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      end
    end

    context 'when there are submitted marks' do
      before :each do
        total_marks = [1, 9.6, 10, 9, 18.1, 21] # Max mark is 20.

        total_marks.each do |total_mark|
          g = create(:grouping, assignment: @assignment)
          s = create(:version_used_submission, grouping: g)

          result = s.get_latest_result
          result.total_mark = total_mark
          result.marking_state = Result::MARKING_STATES[:complete]
          result.marks.each do |m|
            m.update!(mark: (total_mark * 4.0 / 20).round)
          end
          result.save!
        end
      end

      context 'without an interval provided' do
        it 'returns distribution with default 20 intervals' do
          expect(@assignment.grade_distribution_array.size).to eq 20
        end

        it 'returns the correct distribution' do
          expect(@assignment.grade_distribution_array)
            .to eq [1, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2]
        end
      end

      context 'with an interval provided' do
        it 'returns distribution in the provided interval' do
          expect(@assignment.grade_distribution_array(10).size).to eq 10
        end

        it 'returns the correct distribution' do
          expect(@assignment.grade_distribution_array(10)).to eq [1, 0, 0, 0, 3, 0, 0, 0, 0, 2]
        end
      end
    end
  end

  describe '#pass_collection_date?' do
    context 'when before due with no submission rule' do
      before :each do
        @assignment = create(:assignment, due_date: 2.days.from_now)
      end

      it 'returns false' do
        expect(@assignment.past_collection_date?).not_to be
      end
    end

    context 'when past due with no late submission rule' do
      context 'without sections' do
        before :each do
          @assignment = create(:assignment, due_date: 2.days.ago)
        end

        it 'returns true' do
          expect(@assignment.past_collection_date?).to be
        end
      end

      context 'with a section' do
        before :each do
          @assignment = create(:assignment,
                               due_date: 2.days.ago,
                               assignment_properties_attributes: { section_due_dates_type: true })
          @section = create(:section, name: 'section_name')
          SectionDueDate.create(section: @section, assignment: @assignment, due_date: 1.day.ago)
          student = create(:student, section: @section)
          @grouping = create(:grouping, assignment: @assignment)
          create(:accepted_student_membership,
                 grouping: @grouping,
                 user: student,
                 membership_status: StudentMembership::STATUSES[:inviter])
        end

        it 'returns true' do
          expect(@assignment.past_collection_date?).to be
        end
      end
    end
  end

  describe '#update_results_stats' do
    let(:assignment) { create :assignment }

    before :each do
      allow(assignment).to receive(:max_mark).and_return(10)
    end

    context 'when no marks are found' do
      before :each do
        allow(Result).to receive(:student_marks_by_assignment).and_return([])
      end

      it 'returns false immediately' do
        expect(assignment.update_results_stats).to be_falsy
      end
    end

    context 'when even number of marks are found' do
      before :each do
        allow(Result).to receive(:student_marks_by_assignment).and_return([0, 1, 4, 7])
        assignment.update_results_stats
      end

      it 'updates results_zeros' do
        expect(assignment.assignment_properties.results_zeros).to eq 1
      end

      it 'updates results_fails' do
        expect(assignment.assignment_properties.results_fails).to eq 3
      end

      it 'updates results_average' do
        expect(assignment.assignment_properties.results_average).to eq 30
      end

      it 'updates results_median to the average of the two middle marks' do
        expect(assignment.assignment_properties.results_median).to eq 25
      end

      context 'when max_mark is 0' do
        before :each do
          allow(assignment).to receive(:max_mark).and_return(0)
          assignment.update_results_stats
        end

        it 'updates results_average to 0' do
          expect(assignment.assignment_properties.results_average).to eq 0
        end

        it 'updates results_median to 0' do
          expect(assignment.assignment_properties.results_median).to eq 0
        end
      end
    end

    context 'when odd number of marks are found' do
      before :each do
        allow(Result).to receive(:student_marks_by_assignment).and_return([0, 1, 4, 7, 9])
        assignment.update_results_stats
      end

      it 'updates results_median to the middle mark' do
        expect(assignment.assignment_properties.results_median).to eq 40
      end
    end
  end

  describe '.get_current_assignment' do
    before :each do
      Assignment.destroy_all
    end

    context 'when no assignments are found' do
      it 'returns nil' do
        result = Assignment.get_current_assignment
        expect(result).to be_nil
      end
    end

    context 'when one assignment is found' do
      before :each do
        @assignment1 = create(:assignment, due_date: Date.today - 5)
      end

      it 'returns the only assignment' do
        result = Assignment.get_current_assignment
        expect(result).to eq(@assignment1)
      end
    end

    context 'when more than one assignment is found' do
      context 'when there is an assignment due in 3 days' do
        before :each do
          @a1 = create(:assignment, due_date: Date.today - 5)
          @a2 = create(:assignment, due_date: Date.today + 3)
        end

        it 'returns the assignment due in 3 days' do
          result = Assignment.get_current_assignment
          # should return assignment 2
          expect(result).to eq(@a2)
        end
      end

      context 'when the next assignment is due in more than 3 days' do
        before :each do
          @a1 = create(:assignment, due_date: Date.today - 5)
          @a2 = create(:assignment, due_date: Date.today - 1)
          @a3 = create(:assignment, due_date: Date.today + 8)
        end

        it 'returns the assignment that was most recently due' do
          result = Assignment.get_current_assignment
          # should return assignment 2
          expect(result).to eq(@a2)
        end
      end

      context 'when all assignments are due in more than 3 days' do
        before :each do
          @a1 = create(:assignment, due_date: Date.today + 5)
          @a2 = create(:assignment, due_date: Date.today + 12)
          @a3 = create(:assignment, due_date: Date.today + 19)
        end

        it 'returns the assignment that is due first' do
          result = Assignment.get_current_assignment
          # should return assignment 1
          expect(result).to eq(@a1)
        end
      end

      context 'when all assignments are past the due date' do
        before :each do
          @a1 = create(:assignment, due_date: Date.today - 5)
          @a2 = create(:assignment, due_date: Date.today - 12)
          @a3 = create(:assignment, due_date: Date.today - 19)
        end

        it 'returns the assignment that was due most recently' do
          result = Assignment.get_current_assignment
          # should return assignment 1
          expect(result).to eq(@a1)
        end
      end
    end
  end
end

