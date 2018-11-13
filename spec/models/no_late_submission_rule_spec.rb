describe NoLateSubmissionRule do
  it 'be able to create NoLateSubmissionRule' do
    rule = NoLateSubmissionRule.new
    rule.assignment = create(:assignment, section_due_dates_type: true)
    expect(rule.save).to be true
  end

  context 'A section with no_late_submission rules' do
    before(:each) do
      @grouping = create(:grouping)
      @sm = StudentMembership.create(
        grouping: @grouping,
        membership_status: StudentMembership::STATUSES[:inviter])
      @assignment = @grouping.assignment
      @rule = @assignment.submission_rule
    end

    it 'be able to calculate collection time' do
      expect(@assignment.due_date).to eq (@rule.calculate_collection_time)
    end

    it 'be able to calculate collection time for a grouping' do
      expect(@assignment.due_date).to eq (@rule.calculate_grouping_collection_time(@grouping))
    end
  end

  # Shouldn't apply any penalties
  context 'If submission collection date was after due date' do
    before(:each) do
      @assignment = create(:assignment, section_due_dates_type: true)
      @grouping = create(:grouping, assignment: @assignment)
      @assignment.due_date = Time.now - 2.days
      @submission = create(:submission, grouping: @grouping)
      @submission.revision_timestamp = Time.now
      @rule = NoLateSubmissionRule.new
      @assignment.replace_submission_rule(@rule)
      @result_extra_marks_num = @submission.get_latest_result.extra_marks.size
      @submission = @assignment.submission_rule.apply_submission_rule(@submission)
    end
    it 'not change the assignment at all when applied' do
      expect(@result_extra_marks_num).to eq (@submission.get_latest_result.extra_marks.size)
    end
  end
end
