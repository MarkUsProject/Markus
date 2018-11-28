describe SubmissionRule do
  context 'A newly initialized submission rule' do
    it 'belongs to an assignment' do
      is_expected.to belong_to(:assignment)
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
        @assignment.update_attributes(due_date: 1.day.ago)
        @section = create(:section)
      end

      context 'and Section Due Date is in the past' do
        before :each do
          @section_due_date = create(:section_due_date, section: @section,
                                                    assignment: @assignment,
                                                    due_date: 2.days.ago)
          @inviter_with_section = create(:student, section: @section)
          @inviter_without_section = create(:student)
          @grouping_with_section = create(:grouping, inviter: @inviter_with_section)
          @grouping_without_section = create(:grouping, inviter: @inviter_without_section)
        end

        context '#can_collect_now?(section)' do
          it 'should return true' do
            expect(@assignment.submission_rule.can_collect_now?(@section)).to eq true
          end
        end

        context '#can_collect_all_now?' do
          it 'should return true' do
            expect(@assignment.submission_rule.can_collect_all_now?).to eq true
          end
        end

        context '#can_collect_grouping_now?(grouping) with section' do
          it 'should return true' do
            expect(@assignment.submission_rule.can_collect_grouping_now?(@grouping_with_section)).to eq true
          end
        end

        context '#can_collect_grouping_now?(grouping) without section' do
          it 'should return true' do
            expect(@assignment.submission_rule.can_collect_grouping_now?(@grouping_without_section)).to eq true
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
            time_returned = @assignment.submission_rule.get_collection_time(@section)
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
                            .calculate_grouping_collection_time(@grouping_with_section)
            time_difference = (2.days.from_now - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#calculate_grouping_collection_time(grouping) w/o section' do
          it 'should return correct date value' do
            time_returned = @assignment
                            .submission_rule
                            .calculate_grouping_collection_time(@grouping_without_section)
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
          @section_due_date = create(:section_due_date, section: @section,
                                                    assignment: @assignment,
                                                    due_date: 2.days.ago)
          @inviter_with_section = create(:student, section: @section)
          @inviter_without_section = create(:student)
          @grouping_with_section = create(:grouping, inviter: @inviter_with_section)
          @grouping_without_section = create(:grouping, inviter: @inviter_without_section)
        end

        context '#can_collect_now?(section)' do
          it 'should return true' do
            expect(@assignment.submission_rule.can_collect_now?(@section)).to eq true
          end
        end

        context '#can_collect_all_now?' do
          it 'should return false' do
            expect(@assignment.submission_rule.can_collect_all_now?).to eq false
          end
        end

        context '#can_collect_grouping_now?(grouping) with section' do
          it 'should return true' do
            expect(@assignment.submission_rule.can_collect_grouping_now?(@grouping_with_section)).to eq true
          end
        end

        context '#can_collect_grouping_now?(grouping) without section' do
          it 'should return false' do
            expect(@assignment.submission_rule.can_collect_grouping_now?(@grouping_without_section)).to eq false
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
                            .calculate_grouping_collection_time(@grouping_with_section)
            time_difference = (2.days.ago - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#calculate_grouping_collection_time(grouping) w/o section' do
          it 'should return correct date value' do
            time_returned = @assignment
                            .submission_rule
                            .calculate_grouping_collection_time(@grouping_without_section)
            time_difference = (1.days.from_now - time_returned).abs
            expect(time_difference).to be < 600
          end
        end
      end

      context 'and Section Due Date is in the future' do
        before :each do
          @section_due_date = create(:section_due_date, section: @section,
                                     assignment: @assignment,
                                     due_date: 2.days.from_now)
          @inviter_with_section = create(:student, section: @section)
          @inviter_without_section = create(:student)
          @grouping_with_section = create(:grouping, inviter: @inviter_with_section)
          @grouping_without_section = create(:grouping, inviter: @inviter_without_section)
        end

        context '#can_collect_now?(section)' do
          it 'should return false' do
            expect(@assignment.submission_rule.can_collect_now?(@section)).to eq false
          end
        end

        context '#can_collect_all_now?' do
          it 'should return false' do
            expect(@assignment.submission_rule.can_collect_all_now?).to eq false
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
            time_returned = @assignment.submission_rule.get_collection_time(@section)
            time_difference = (2.days.from_now - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#get_collection_time() (i.e. global due date)' do
          it 'should return correct date value' do
            time_returned = @assignment.submission_rule.get_collection_time
            time_difference = (1.days.from_now - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#calculate_grouping_collection_time(grouping) with section' do
          it 'should return correct date value' do
            time_returned = @assignment
                            .submission_rule
                            .calculate_grouping_collection_time(@grouping_with_section)
            time_difference = (2.days.from_now - time_returned).abs
            expect(time_difference).to be < 600
          end
        end

        # in accuracy range of 10 minutes
        context '#calculate_grouping_collection_time(grouping) w/o section' do
          it 'should return correct date value' do
            time_returned = @assignment
                            .submission_rule
                            .calculate_grouping_collection_time(@grouping_without_section)
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
          expect(@assignment.submission_rule.can_collect_now?(@section)).to eq true
        end
      end

      context '#can_collect_all_now?' do
        it 'should return true' do
          expect(@assignment.submission_rule.can_collect_all_now?).to eq true
        end
      end

      context '#can_collect_grouping_now?(grouping) with section' do
        it 'should return true' do
          expect(@assignment.submission_rule.can_collect_grouping_now?(@grouping_with_section)).to eq true
        end
      end

      context '#can_collect_grouping_now?(grouping) without section' do
        it 'should return true' do
          expect(@assignment.submission_rule.can_collect_grouping_now?(@grouping_without_section)).to eq true
        end
      end

      # in accuracy range of 10 minutes
      context '#get_collection_time(section)' do
        it 'should return correct date value' do
          time_returned = @assignment.submission_rule.get_collection_time(@section)
          time_difference = (1.days.ago - time_returned).abs
          expect(time_difference).to be < 600
        end
      end

      # in accuracy range of 10 minutes
      context '#get_collection_time(nil) (i.e. global due date)' do
        it 'should return correct date value' do
          time_returned = @assignment.submission_rule.get_collection_time
          time_difference = (1.days.ago - time_returned).abs
          expect(time_difference).to be < 600
        end
      end

      # in accuracy range of 10 minutes
      context '#calculate_grouping_collection_time(grouping) with section' do
        it 'should return correct date value' do
          time_returned = @assignment
                          .submission_rule
                          .calculate_grouping_collection_time(@grouping_with_section)
          time_difference = (1.days.ago - time_returned).abs
          expect(time_difference).to be < 600
        end
      end

      # in accuracy range of 10 minutes
      context '#calculate_grouping_collection_time(grouping) without section' do
        it 'should return correct date value' do
          time_returned = @assignment
                          .submission_rule
                          .calculate_grouping_collection_time(@grouping_without_section)
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
        @grouping_without_section = Grouping.create(inviter: @inviter_without_section)
      end

      context '#can_collect_now?(section)' do
        it 'should return false' do
          expect(@assignment.submission_rule.can_collect_now?(@section)).to eq false
        end
      end

      context '#can_collect_all_now?' do
        it 'should return false' do
          expect(@assignment.submission_rule.can_collect_all_now?).to eq false
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
          time_returned = @assignment.submission_rule.get_collection_time(@section)
          time_difference = (1.days.from_now - time_returned).abs
          expect(time_difference).to be < 600
        end
      end

      # in accuracy range of 10 minutes
      context '#get_collection_time(nil) (i.e. global due date)' do
        it 'should return correct date value' do
          time_returned = @assignment.submission_rule.get_collection_time
          time_difference = (1.days.from_now - time_returned).abs
          expect(time_difference).to be < 600
        end
      end

      # in accuracy range of 10 minutes
      context '#calculate_grouping_collection_time(grouping) with section' do
        it 'should return correct date value' do
          time_returned = @assignment
                          .submission_rule
                          .calculate_grouping_collection_time(@grouping_with_section)
          time_difference = (1.days.from_now - time_returned).abs
          expect(time_difference).to be < 600
        end
      end

      # in accuracy range of 10 minutes
      context '#calculate_grouping_collection_time(grouping) without section' do
        it 'should return correct date value' do
          time_returned = @assignment
                          .submission_rule
                          .calculate_grouping_collection_time(@grouping_without_section)
          time_difference = (1.days.from_now - time_returned).abs
          expect(time_difference).to be < 600
        end
      end
    end
  end

  context 'Grace period ids' do
    before(:each) do
      @submission_rule = create(:grace_period_submission_rule)

      # Randomly create five periods for this SubmissionRule (ids unsorted):
      5.times do |_|
        create(:period, submission_rule: @submission_rule)
      end
    end

    it 'should sort in ascending order' do
      expect(@submission_rule.periods.pluck(:id)).to satisfy { |ids| ids == ids.sort }
    end
  end

  context 'Penalty period ids' do
    before(:each) do
      @submission_rule = create(:penalty_period_submission_rule)

      # Randomly create five periods for this SubmissionRule (ids unsorted):
      5.times do |_|
        create(:period, submission_rule: @submission_rule)
      end
    end

    it 'should sort in ascending order' do
      expect(@submission_rule.periods.pluck(:id)).to satisfy { |ids| ids == ids.sort }
    end
  end

  context 'Assignment with a due date in 2 days' do
    let(:assignment) { create(:assignment) }

    it 'will not be able to collect submissions' do
      expect(assignment.submission_rule.can_collect_all_now?).to be false
    end

    it 'will be able to get due date' do
      expect(assignment.due_date).to eq assignment.submission_rule.get_collection_time
    end
  end

  context 'Assignment with a coming due date and with a past section due date' do
    before(:each) do
      # the assignment due date is to come...
      @assignment = create(:assignment, section_due_dates_type: true,
                                    due_date: 2.days.from_now, group_min: 1)

      # ... but the section due date is in the past
      @section = create(:section)
      create(:section_due_date, section: @section,
             assignment: @assignment, due_date: 2.days.ago)

      # create a group of one student from this section, for this assignment
      @student = create(:student, section: @section)
      @grouping = create(:grouping, assignment: @assignment)
      @studentMembership = create(:student_membership, user: @student, grouping: @grouping,
                                                  membership_status:  StudentMembership::STATUSES[:inviter])
      end

    it 'will be able to collect the submissions from groups of this section' do
      expect(@assignment.submission_rule.can_collect_grouping_now?(@grouping)).to be true
    end
  end

  context 'Assignment that is past its due date' do
    let(:assignment) { create(:assignment, due_date: 2.days.ago) }

    it 'can collect submission files' do
      expect(assignment.due_date).to eql assignment.submission_rule.get_collection_time

      # due date is two days ago, so it can be collected
      expect(assignment.submission_rule.can_collect_all_now?).to be true
    end
  end
end
