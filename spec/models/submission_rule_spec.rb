describe SubmissionRule do
  # FAILING, SubmissionRule factory not properly initialized
  context 'A newly initialized submission rule' do
    before :each do
      @rule = create(:SubmissionRule)
      @rule.assignment = create(:assignment)
    end

    it 'is a child of class Assignment' do
      is_expected.to belong_to(:assignment)
    end

    it 'will raise NotImplemented error' do
      expect(@rule.commit_after_collection_message).to raise_error(NotImplementedError)
    end

    it 'will raise NotImplemented error' do
      expect(@rule.overtime_message).to raise_error(NotImplementedError)
    end

    it 'will raise NotImplemented error' do
      expect(@rule.assignment_valid?).to raise_error(NotImplementedError)
    end

    it 'will raise NotImplemented error' do
      expect(@rule.apply_submission_rule(nil)).to raise_error(NotImplementedError)
    end

    it 'will raise NotImplemented error' do
      expect(@rule.description_of_rule).to raise_error(NotImplementedError)
    end
  end

  context '#calculate_collection_time' do
    let(:assignment) { create(:assignment) }

    it 'should return something other than nil at the end' do
      expect(assignment.submission_rule.calculate_collection_time).to_not be_nil
    end

    it 'should return some date value at the end' do
      expect(assignment.submission_rule.calculate_collection_time.to_date).to be_kind_of(Date)
    end
  end

  context '#calculate_grouping_collection_time' do
    let(:assignment)            { create(:assignment) }
    let(:grouping_with_inviter) { create(:grouping_with_inviter) }

    it 'should return something other than nil at the end' do
      expect(assignment.submission_rule.calculate_grouping_collection_time(grouping_with_inviter)).to_not be_nil
    end

    it 'should return some date value at the end' do
      expect(assignment.submission_rule.calculate_grouping_collection_time(grouping_with_inviter)
               .to_date).to be_kind_of(Date)
    end

    # test that is triggered when grouping.inviter.section exists
    it 'should return date value if grouping.inviter.section is not nil' do
      expect(assignment.submission_rule
        .calculate_grouping_collection_time(grouping_with_inviter).to_date)
        .to be_kind_of(Date)
    end
  end

  context 'when Section Due Dates are enabled' do
    before :each do
      @assignment = create(:assignment, section_due_dates_type: true)
    end

    context 'and Assignment Due Date is in the past' do
      before :each do
        @assignment.update_attributes(due_date: 1.days.ago)
        @section = create(:section)
      end

      context 'and Section Due Date is in the past' do
        before :each do
          @section_due_date = create(:SectionDueDate, section: @section,
                                                    assignment: @assignment,
                                                    due_date: 2.days.ago)
          @inviter_with_section = create(:student, section: @section)
          @inviter_without_section = create(:student)
          @grouping_with_section = create(:grouping, inviter: @inviter_with_section)
          @grouping_without_section = create(:grouping, inviter: @inviter_without_section)
        end

        context '#can_collect_now?(section)' do
          it 'should return true' do
            expect(@assignment.submission_rule
              .can_collect_now?(@section))
              .to eq true
          end
        end

        context '#can_collect_all_now?' do
          it 'should return true' do
            expect(@assignment.submission_rule
              .can_collect_all_now?)
              .to eq true
          end
        end

        context '#can_collect_grouping_now?(grouping) with section' do
          it 'should return true' do
            expect(@assignment.submission_rule
              .can_collect_grouping_now?(@grouping_with_section))
              .to eq true
          end
        end

        context '#can_collect_grouping_now?(grouping) without section' do
          it 'should return true' do
            expect(@assignment.submission_rule
              .can_collect_grouping_now?(@grouping_without_section))
              .to eq true
          end
        end

        # in accuracy range of 10 minutes
        context '#get_collection_time(section)' do
          it 'should return correct date value' do
            time_returned = @assignment.submission_rule
                                       .get_collection_time(@section)
            time_difference = (2.days.ago - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#get_collection_time(nil) (i.e. global due date)' do
          it 'should return correct date value' do
            time_returned = @assignment.submission_rule
                                       .get_collection_time
            time_difference = (1.days.ago - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#calculate_grouping_collection_time(grouping) with section' do
          it 'should return correct date value' do
            time_returned = @assignment
                            .submission_rule
                            .calculate_grouping_collection_time(
                              @grouping_with_section)
            time_difference = (2.days.ago - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#calculate_grouping_collection_time(grouping) w/o section' do
          it 'should return correct date value' do
            time_returned = @assignment
                            .submission_rule
                            .calculate_grouping_collection_time(
                              @grouping_without_section)
            time_difference = (1.days.ago - time_returned).abs
            expect(time_difference).to be < 600
          end
        end
      end

      context 'and Section Due Date is in the future' do
        before :each do
          @section_due_date = SectionDueDate.create(section: @section,
                                                    assignment: @assignment,
                                                    due_date: 2.days.from_now)
          @inviter_with_section = Student.create(section: @section)
          @inviter_without_section = Student.create
          @grouping_with_section = Grouping.create(
            inviter: @inviter_with_section)
          @grouping_without_section = Grouping.create(
            inviter: @inviter_without_section)
        end

        context '#can_collect_now?(section)' do
          it 'should return false' do
            expect(@assignment.submission_rule
              .can_collect_now?(@section))
              .to eq false
          end
        end

        context '#can_collect_all_now?' do
          it 'should return false' do
            expect(@assignment.submission_rule
              .can_collect_all_now?)
              .to eq false
          end
        end

        context '#can_collect_grouping_now?(grouping) with section' do
          it 'should return false' do
            expect(@assignment.submission_rule
              .can_collect_grouping_now?(@grouping_with_section))
              .to eq false
          end
        end

        context '#can_collect_grouping_now?(grouping) without section' do
          it 'should return true' do
            expect(@assignment.submission_rule
              .can_collect_grouping_now?(@grouping_without_section))
              .to eq true
          end
        end

        # in accuracy range of 10 minutes
        context '#get_collection_time(section)' do
          it 'should return correct date value' do
            time_returned = @assignment.submission_rule
                                       .get_collection_time(@section)
            time_difference = (2.days.from_now - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#get_collection_time(nil) (i.e. global due date)' do
          it 'should return correct date value' do
            time_returned = @assignment.submission_rule
                                       .get_collection_time
            time_difference = (1.days.ago - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#calculate_grouping_collection_time(grouping) with section' do
          it 'should return correct date value' do
            time_returned = @assignment
                            .submission_rule
                            .calculate_grouping_collection_time(
                              @grouping_with_section)
            time_difference = (2.days.from_now - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#calculate_grouping_collection_time(grouping) w/o section' do
          it 'should return correct date value' do
            time_returned = @assignment
                            .submission_rule
                            .calculate_grouping_collection_time(
                              @grouping_without_section)
            time_difference = (1.days.ago - time_returned).abs
            expect(time_difference).to be < 600
          end
        end
      end
    end

    context 'and Assignment Due Date is in the future' do
      before :each do
        @assignment.update_attributes(due_date: 1.days.from_now)
        @section = create(:section)
      end

      context 'and Section Due Date is in the past' do
        before :each do
          @section_due_date = create(:SectionDueDate, section: @section,
                                                    assignment: @assignment,
                                                    due_date: 2.days.ago)
          @inviter_with_section = create(:student, section: @section)
          @inviter_without_section = create(:student)
          @grouping_with_section = create(:grouping, inviter: @inviter_with_section)
          @grouping_without_section = create(:grouping, inviter: @inviter_without_section)
        end

        context '#can_collect_now?(section)' do
          it 'should return true' do
            expect(@assignment.submission_rule
              .can_collect_now?(@section))
              .to eq true
          end
        end

        context '#can_collect_all_now?' do
          it 'should return false' do
            expect(@assignment.submission_rule
              .can_collect_all_now?)
              .to eq false
          end
        end

        context '#can_collect_grouping_now?(grouping) with section' do
          it 'should return true' do
            expect(@assignment.submission_rule
              .can_collect_grouping_now?(@grouping_with_section))
              .to eq true
          end
        end

        context '#can_collect_grouping_now?(grouping) without section' do
          it 'should return false' do
            expect(@assignment.submission_rule
              .can_collect_grouping_now?(@grouping_without_section))
              .to eq false
          end
        end

        # in accuracy range of 10 minutes
        context '#get_collection_time(section)' do
          it 'should return correct date value' do
            time_returned = @assignment.submission_rule
                                       .get_collection_time(@section)
            time_difference = (2.days.ago - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#get_collection_time(nil) (i.e. global due date)' do
          it 'should return correct date value' do
            time_returned = @assignment.submission_rule
                                       .get_collection_time
            time_difference = (1.days.from_now - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#calculate_grouping_collection_time(grouping) with section' do
          it 'should return correct date value' do
            time_returned = @assignment
                            .submission_rule
                            .calculate_grouping_collection_time(
                              @grouping_with_section)
            time_difference = (2.days.ago - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#calculate_grouping_collection_time(grouping) w/o section' do
          it 'should return correct date value' do
            time_returned = @assignment
                            .submission_rule
                            .calculate_grouping_collection_time(
                              @grouping_without_section)
            time_difference = (1.days.from_now - time_returned).abs
            expect(time_difference).to be < 600
          end
        end
      end

      context 'and Section Due Date is in the future' do
        before :each do
          @section_due_date = create(:SectionDueDate, section: @section,
                                     assignment: @assignment,
                                     due_date: 2.days.from_now)
          @inviter_with_section = create(:student, section: @section)
          @inviter_without_section = create(:student)
          @grouping_with_section = create(:grouping, inviter: @inviter_with_section)
          @grouping_without_section = create(:grouping, inviter: @inviter_without_section)
        end

        context '#can_collect_now?(section)' do
          it 'should return false' do
            expect(@assignment.submission_rule
              .can_collect_now?(@section))
              .to eq false
          end
        end

        context '#can_collect_all_now?' do
          it 'should return false' do
            expect(@assignment.submission_rule
              .can_collect_all_now?)
              .to eq false
          end
        end

        context '#can_collect_grouping_now?(grouping) with section' do
          it 'should return false' do
            expect(@assignment.submission_rule
              .can_collect_grouping_now?(@grouping_with_section))
              .to eq false
          end
        end

        context '#can_collect_grouping_now?(grouping) without section' do
          it 'should return false' do
            expect(@assignment.submission_rule
              .can_collect_grouping_now?(@grouping_without_section))
              .to eq false
          end
        end

        # in accuracy range of 10 minutes
        context '#get_collection_time(section)' do
          it 'should return correct date value' do
            time_returned = @assignment.submission_rule
                                       .get_collection_time(@section)
            time_difference = (2.days.from_now - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#get_collection_time(nil) (i.e. global due date)' do
          it 'should return correct date value' do
            time_returned = @assignment.submission_rule
                                       .get_collection_time
            time_difference = (1.days.from_now - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#calculate_grouping_collection_time(grouping) with section' do
          it 'should return correct date value' do
            time_returned = @assignment
                            .submission_rule
                            .calculate_grouping_collection_time(
                              @grouping_with_section)
            time_difference = (2.days.from_now - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#calculate_grouping_collection_time(grouping) w/o section' do
          it 'should return correct date value' do
            time_returned = @assignment
                            .submission_rule
                            .calculate_grouping_collection_time(
                              @grouping_without_section)
            time_difference = (1.days.from_now - time_returned).abs
            expect(time_difference).to be < 600
          end
        end
      end
    end
  end

  context 'when Section Due Dates are disabled' do
    before :each do
      @assignment = create(:assignment, section_due_dates_type: false)
    end

    context 'and Assignment Due Date is in the past' do
      before :each do
        @assignment.update_attributes(due_date: 1.days.ago)
        @section = create(:section)
        @inviter_with_section = create(:student, section: @section)
        @inviter_without_section = create(:student)
        @grouping_with_section = create(:grouping, inviter: @inviter_with_section)
        @grouping_without_section = create(:grouping, inviter: @inviter_without_section)
      end

      context '#can_collect_now?(section)' do
        it 'should return true' do
          expect(@assignment.submission_rule
            .can_collect_now?(@section))
            .to eq true
        end
      end

      context '#can_collect_all_now?' do
        it 'should return true' do
          expect(@assignment.submission_rule
            .can_collect_all_now?)
            .to eq true
        end
      end

      context '#can_collect_grouping_now?(grouping) with section' do
        it 'should return true' do
          expect(@assignment.submission_rule
            .can_collect_grouping_now?(@grouping_with_section))
            .to eq true
        end
      end

      context '#can_collect_grouping_now?(grouping) without section' do
        it 'should return true' do
          expect(@assignment.submission_rule
            .can_collect_grouping_now?(@grouping_without_section))
            .to eq true
        end
      end

      # in accuracy range of 10 minutes
      context '#get_collection_time(section)' do
        it 'should return correct date value' do
          time_returned = @assignment.submission_rule
                                     .get_collection_time(@section)
          time_difference = (1.days.ago - time_returned).abs
          expect(time_difference).to be < 600
        end
      end

      # in accuracy range of 10 minutes
      context '#get_collection_time(nil) (i.e. global due date)' do
        it 'should return correct date value' do
          time_returned = @assignment.submission_rule
                                     .get_collection_time
          time_difference = (1.days.ago - time_returned).abs
          expect(time_difference).to be < 600
        end
      end

      # in accuracy range of 10 minutes
      context '#calculate_grouping_collection_time(grouping) with section' do
        it 'should return correct date value' do
          time_returned = @assignment
                          .submission_rule
                          .calculate_grouping_collection_time(
                            @grouping_with_section)
          time_difference = (1.days.ago - time_returned).abs
          expect(time_difference).to be < 600
        end
      end

      # in accuracy range of 10 minutes
      context '#calculate_grouping_collection_time(grouping) without section' do
        it 'should return correct date value' do
          time_returned = @assignment
                          .submission_rule
                          .calculate_grouping_collection_time(
                            @grouping_without_section)
          time_difference = (1.days.ago - time_returned).abs
          expect(time_difference).to be < 600
        end
      end
    end

    context 'and Assignment Due Date is in the future' do
      before :each do
        @assignment.update_attributes(due_date: 1.days.from_now)
        @section = create(:section)
        @inviter_with_section = Student.create(section: @section)
        @inviter_without_section = Student.create
        @grouping_with_section = Grouping.create(inviter: @inviter_with_section)
        @grouping_without_section = Grouping.create(
          inviter: @inviter_without_section)
      end

      context '#can_collect_now?(section)' do
        it 'should return false' do
          expect(@assignment.submission_rule
            .can_collect_now?(@section))
            .to eq false
        end
      end

      context '#can_collect_all_now?' do
        it 'should return false' do
          expect(@assignment.submission_rule
            .can_collect_all_now?)
            .to eq false
        end
      end

      context '#can_collect_grouping_now?(grouping) with section' do
        it 'should return false' do
          expect(@assignment.submission_rule
            .can_collect_grouping_now?(@grouping_with_section))
            .to eq false
        end
      end

      context '#can_collect_grouping_now?(grouping) without section' do
        it 'should return false' do
          expect(@assignment.submission_rule
            .can_collect_grouping_now?(@grouping_without_section))
            .to eq false
        end
      end

      # in accuracy range of 10 minutes
      context '#get_collection_time(section)' do
        it 'should return correct date value' do
          time_returned = @assignment.submission_rule
                                     .get_collection_time(@section)
          time_difference = (1.days.from_now - time_returned).abs
          expect(time_difference).to be < 600
        end
      end

      # in accuracy range of 10 minutes
      context '#get_collection_time(nil) (i.e. global due date)' do
        it 'should return correct date value' do
          time_returned = @assignment.submission_rule
                                     .get_collection_time
          time_difference = (1.days.from_now - time_returned).abs
          expect(time_difference).to be < 600
        end
      end

      # in accuracy range of 10 minutes
      context '#calculate_grouping_collection_time(grouping) with section' do
        it 'should return correct date value' do
          time_returned = @assignment
                          .submission_rule
                          .calculate_grouping_collection_time(
                            @grouping_with_section)
          time_difference = (1.days.from_now - time_returned).abs
          expect(time_difference).to be < 600
        end
      end

      # in accuracy range of 10 minutes
      context '#calculate_grouping_collection_time(grouping) without section' do
        it 'should return correct date value' do
          time_returned = @assignment
                          .submission_rule
                          .calculate_grouping_collection_time(
                            @grouping_without_section)
          time_difference = (1.days.from_now - time_returned).abs
          expect(time_difference).to be < 600
        end
      end
    end
  end

  #FAILING, GracePeriodSubmissionRule factory not properly initialized
  context 'Grace period ids' do
    before(:each) do
    submission_rule = create(:GracePeriodSubmissionRule)
    @sub_rule_id = @submission_rule.id

    # Randomly create five periods for this SubmissionRule (ids unsorted):
    @period = create(:Period, submission_rule_id: @sub_rule_id)
    first_period_id = @period.id

    # Create four other periods
      for i in (1..4) do
        @period = create(:Period, id: first_period_id + i, submission_rule_id: @sub_rule_id)
      end
    end

    it 'sort in ascending order' do
      # Loop through periods for this SubmissionRule and verify the ids are
      # sorted in ascending order
      previous_id = @submission_rule.periods[0][:id]
      for i in (1..4) do
        expect(@submission_rule.periods[i][:id]).to be > previous_id
        previous_id = @submission_rule.periods[i][:id]
      end
    end
  end

  #FAILING, PenaltyPeriodSubmissionRule factory not properly initialized
  context 'Penalty period ids' do
    before(:each) do
    # Create SubmissionRule with default type 'PenaltyPeriodSubmissionRule'
    @submission_rule = create(:PenaltyPeriodSubmissionRule)
    sub_rule_id = @submission_rule.id

    # Randomly create five periods for this SubmissionRule (ids unsorted):
    @period = create(:Period, submission_rule_id: sub_rule_id)
    first_period_id = @period.id

    # Create four other periods
    for i in (1..4) do
      @period = create(:Period, id: first_period_id + i, submission_rule_id: @sub_rule_id)
    end
    end

    it 'should sort in ascending order' do
      # Loop through periods for this SubmissionRule and verify the ids are sorted in ascending order
      previous_id = @submission_rule.periods[0][:id]
      for i in (1..4) do
        expect(@submission_rule.periods[i][:id]).to be > previous_id
        previous_id = @submission_rule.periods[i][:id]
      end
    end
  end

  context 'Assignment with a due date in 2 days' do
    before(:each) do
      @assignment = create(:assignment)
    end

    it 'will not be able to collect submissions' do
      expect(@assignment.submission_rule.can_collect_all_now?).to be false
    end

    it 'will be able to get due date' do
      expect(@assignment.due_date).to eq(@assignment.submission_rule.get_collection_time)
    end
  end

  context 'Assignment with a coming due date and with a past section due date' do
    before(:each) do
      # the assignment due date is to come...
      @assignment = create(:assignment, section_due_dates_type: true,
                                    due_date: 2.days.from_now, group_min: 1)

      # ... but the section due date is in the past
      @section = create(:section, name: 'section1')
      @sectionDueDate = create(:SectionDueDate, section: @section,
                                assignment: @assignment, due_date: 2.days.ago)

      # create a group of one student from this section, for this assignment
      @student = create(:student, section: @section)
      @grouping = create(:grouping, assignment: @assignment)
      @studentMembership = create(:student_membership, user: @student, grouping: @grouping,
                                                  membership_status:  StudentMembership::STATUSES[:inviter])
      end

    it 'will be able to collect the submissions from groups of this section' do
      expect(@assignment.submission_rule.can_collect_grouping_now?(@grouping)).to be true
      #Could not collect submission of the group whereas due date for the group's section is past
    end
  end

  context 'Assignment with a past due date' do
    before(:each) do
      @assignment = create(:assignment, due_date: 2.days.ago)
    end

    it 'can collect submission files' do
      expect(@assignment.due_date.eql?(@assignment.submission_rule.get_collection_time))

      # due date is two days ago, so it can be collected
      expect(@assignment.submission_rule.can_collect_all_now?).to be true
    end
  end
end
