describe NoLateSubmissionRule do
  let(:rule_type) { :no_late_submission_rule }

  it { is_expected.to have_one(:course) }

  shared_examples 'valid overtime message' do |submission_time_offset|
    it 'has an overtime message' do
      Timecop.freeze(due_date + submission_time_offset) do
        apply_rule
        rule_overtime_message = rule.overtime_message(grouping)
        human_after_collection_message = NoLateSubmissionRule.human_attribute_name(:after_collection_message)
        expect(rule_overtime_message).to eq(human_after_collection_message)
      end
    end
  end

  context 'when the group submitted on time' do
    include_context 'submission_rule_on_time'
    it 'should be able to calculate collection time' do
      expect(assignment.due_date).to eq(rule.calculate_collection_time)
    end

    it 'should be able to calculate collection time for a grouping' do
      expect(assignment.due_date).to eq(rule.calculate_grouping_collection_time(grouping))
    end

    it_behaves_like 'valid overtime message', -5.days
  end

  context 'when the group submitted late' do
    include_context 'submission_rule_during_first'
    it 'does not deduct credits' do
      expect { apply_rule }.not_to(change { grouping.inviter.grace_period_deductions.count })
    end

    it 'should not create an extra mark' do
      expect { apply_rule }.not_to(change { submission.get_latest_result.extra_marks.count })
    end

    it_behaves_like 'valid overtime message', 5.days
  end
end
