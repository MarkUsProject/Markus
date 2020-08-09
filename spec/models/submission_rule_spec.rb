shared_examples 'due_date_calculations' do |assignment_past, section_past, section_enabled: true|
  assignment_due_date_str = 'assignment due date'
  section_due_date_str = 'section_due_date'

  let(:assignment_due_date) { assignment.due_date }
  let(:section_due_date_due_date) { section_enabled ? section_due_date.due_date : assignment_due_date }

  unless section_enabled
    section_past = assignment_past
    section_due_date_str = assignment_due_date_str
  end

  context '#can_collect_now?(section)' do
    it "should return #{section_past}" do
      expect(assignment.submission_rule.can_collect_now?(section)).to eq(section_past)
    end
  end

  context '#can_collect_all_now?' do
    it "should return #{assignment_past && section_past}" do
      expect(assignment.submission_rule.can_collect_all_now?).to eq(assignment_past && section_past)
    end
  end

  context '#can_collect_grouping_now?(grouping) with section' do
    it "should return #{section_past}" do
      expect(assignment.submission_rule.can_collect_grouping_now?(grouping_with_section)).to eq(section_past)
    end
  end

  context '#can_collect_grouping_now?(grouping) without section' do
    it "should return #{assignment_past}" do
      expect(assignment.submission_rule.can_collect_grouping_now?(grouping_without_section)).to eq(assignment_past)
    end
  end

  context '#get_collection_time(section)' do
    it "should return #{section_due_date_str}" do
      due_date = section_due_date_due_date
      expect(assignment.submission_rule.get_collection_time(section)).to be_within(1.second).of(due_date)
    end
  end

  context '#get_collection_time(nil) (i.e. global due date)' do
    it "should return #{assignment_due_date_str}" do
      expect(assignment.submission_rule.get_collection_time).to be_within(1.second).of(assignment_due_date)
    end
  end

  context '#calculate_grouping_collection_time(grouping) with section' do
    it "should return #{section_due_date_str}" do
      time = assignment.submission_rule.calculate_grouping_collection_time(grouping_with_section)
      expect(time).to be_within(1.second).of(section_due_date_due_date)
    end
  end

  context '#calculate_grouping_collection_time(grouping) w/o section' do
    it "should return #{assignment_due_date_str}" do
      time = assignment.submission_rule.calculate_grouping_collection_time(grouping_without_section)
      expect(time).to be_within(1.second).of(assignment_due_date)
    end
  end
end

describe SubmissionRule do
  context 'A newly initialized submission rule' do
    it 'belongs to an assignment' do
      is_expected.to belong_to(:assignment)
    end
  end

  context '#calculate_collection_time' do
    let(:assignment) { create(:assignment) }

    it 'should return a TimeWithZone object' do
      expect(assignment.submission_rule.calculate_collection_time).to be_kind_of(ActiveSupport::TimeWithZone)
    end
  end

  context '#calculate_grouping_collection_time' do
    let(:assignment)            { create(:assignment) }
    let(:grouping_with_inviter) { create(:grouping_with_inviter) }

    it 'should return a TimeWithZone object if called with a grouping argument' do
      expect(assignment.submission_rule
        .calculate_grouping_collection_time(grouping_with_inviter))
        .to be_kind_of(ActiveSupport::TimeWithZone)
    end
  end

  context 'when Section Due Dates' do
    let(:section) { create(:section) }
    let(:section_due_date) { create(:section_due_date, section: section, assignment: assignment) }
    let(:inviter_with_section) { create(:student, section: section) }
    let(:inviter_without_section) { create(:student) }
    let(:grouping_with_section) do
      create(:grouping_with_inviter, inviter: inviter_with_section, assignment: assignment)
    end
    let(:grouping_without_section) do
      create(:grouping_with_inviter, inviter: inviter_without_section, assignment: assignment)
    end
    context 'are enabled' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { section_due_dates_type: true }) }

      context 'and Assignment Due Date is in the past' do
        before :each do
          assignment.update!(due_date: 2.days.ago)
        end

        context 'and Section Due Date is in the past' do
          before :each do
            section_due_date.update!(due_date: 1.day.ago)
          end
          include_examples 'due_date_calculations', true, true
        end

        context 'and Section Due Date is in the future' do
          before :each do
            section_due_date.update!(due_date: 1.day.from_now)
          end
          include_examples 'due_date_calculations', true, false
        end
      end

      context 'and Assignment Due Date is in the future' do
        before :each do
          assignment.update!(due_date: 2.days.from_now)
        end

        context 'and Section Due Date is in the past' do
          before :each do
            section_due_date.update!(due_date: 1.day.ago)
          end
          include_examples 'due_date_calculations', false, true
        end

        context 'and Section Due Date is in the future' do
          before :each do
            section_due_date.update!(due_date: 1.day.from_now)
          end
          include_examples 'due_date_calculations', false, false
        end
      end
    end
    context 'are disabled' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { section_due_dates_type: false }) }
      context 'and Assignment Due Date is in the past' do
        before :each do
          assignment.update!(due_date: 2.days.ago)
        end

        context 'and Section Due Date is in the past' do
          before :each do
            section_due_date.update!(due_date: 1.day.ago)
          end
          include_examples 'due_date_calculations', true, true, section_enabled: false
        end

        context 'and Section Due Date is in the future' do
          before :each do
            section_due_date.update!(due_date: 1.day.from_now)
          end
          include_examples 'due_date_calculations', true, true, section_enabled: false
        end
      end

      context 'and Assignment Due Date is in the future' do
        before :each do
          assignment.update!(due_date: 2.days.from_now)
        end

        context 'and Section Due Date is in the past' do
          before :each do
            section_due_date.update!(due_date: 1.day.ago)
          end
          include_examples 'due_date_calculations', false, false, section_enabled: false
        end

        context 'and Section Due Date is in the future' do
          before :each do
            section_due_date.update!(due_date: 1.day.from_now)
          end
          include_examples 'due_date_calculations', false, false, section_enabled: false
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
      @assignment = create(:assignment,
                           due_date: 2.days.from_now,
                           assignment_properties_attributes: { section_due_dates_type: true, group_min: 1 })

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
