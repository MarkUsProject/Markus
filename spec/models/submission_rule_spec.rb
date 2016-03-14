require 'spec_helper'

describe SubmissionRule do
  it { is_expected.to belong_to(:assignment) }
  context '#calculate_collection_time' do
    let(:assignment) { create(:assignment) }

    it 'should return something other than nil at the end' do
      expect(assignment.submission_rule.calculate_collection_time)
        .to_not be_nil
    end

    it 'should return some date value at the end' do
      expect(assignment.submission_rule
        .calculate_collection_time.to_date)
        .to be_kind_of(Date)
    end

    # in accuracy range of 10 minutes
    it 'should return a correct time value at the end' do
      time_returned = assignment.submission_rule.calculate_collection_time
      time_now = Time.now
      time_difference = (time_now - time_returned).abs
      expect(time_difference)
        .to be < 600
    end
  end
  context '#calculate_grouping_collection_time' do
    let(:assignment) { create(:assignment) }
    let(:grouping_with_inviter) { create(:grouping_with_inviter) }

    it 'should return something other than nil at the end' do
      expect(assignment.submission_rule
        .calculate_grouping_collection_time(grouping_with_inviter))
        .to_not be_nil
    end

    it 'should return some date value at the end' do
      expect(assignment.submission_rule
        .calculate_grouping_collection_time(grouping_with_inviter).to_date)
        .to be_kind_of(Date)
    end

    # in accuracy range of 10 minutes
    it 'should return a correct time value at the end' do
      time_returned = assignment.submission_rule
                      .calculate_grouping_collection_time(grouping_with_inviter)
      time_now = Time.now
      time_difference = (time_now - time_returned).abs
      expect(time_difference)
        .to be < 600
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
          @section_due_date = SectionDueDate.create(section: @section,
                                                    assignment: @assignment,
                                                    due_date: 2.days.ago)
          @inviter_with_section = Student.create(section: @section)
          @inviter_without_section = Student.create
          @grouping_with_section = Grouping.create(
            inviter: @inviter_with_section)
          @grouping_without_section = Grouping.create(
            inviter: @inviter_without_section)
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
          @section_due_date = SectionDueDate.create(section: @section,
                                                    assignment: @assignment,
                                                    due_date: 2.days.ago)
          @inviter_with_section = Student.create(section: @section)
          @inviter_without_section = Student.create
          @grouping_with_section = Grouping.create(
            inviter: @inviter_with_section)
          @grouping_without_section = Grouping.create(
            inviter: @inviter_without_section)
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
        @inviter_with_section = Student.create(section: @section)
        @inviter_without_section = Student.create
        @grouping_with_section = Grouping.create(
          inviter: @inviter_with_section)
        @grouping_without_section = Grouping.create(
          inviter: @inviter_without_section)
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
end
