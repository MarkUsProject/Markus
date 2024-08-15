describe NoLateSubmissionRule do
  let(:rule_type) { :no_late_submission_rule }

  it { is_expected.to have_one(:course) }

  context 'when the group submitted on time' do
    include_context 'submission_rule_on_time'
    it 'should be able to calculate collection time' do
      expect(assignment.due_date).to eq(rule.calculate_collection_time)
    end

    it 'should be able to calculate collection time for a grouping' do
      expect(assignment.due_date).to eq(rule.calculate_grouping_collection_time(grouping))
    end
  end

  context 'when the group submitted late' do
    include_context 'submission_rule_during_first'
    it 'does not deduct credits' do
      expect { apply_rule }.not_to(change { grouping.inviter.grace_period_deductions.count })
    end

    it 'should not create an extra mark' do
      expect { apply_rule }.not_to(change { submission.get_latest_result.extra_marks.count })
    end
  end
end
