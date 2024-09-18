describe PenaltyPeriodSubmissionRule do
  let(:rule_type) { :penalty_period_submission_rule }
  let(:result) { submission.get_latest_result }

  it { is_expected.to have_one(:course) }

  shared_examples 'valid overtime message' do |potential_penalty, submission_time_offset|
    it 'has an overtime message with a potential penalty' do
      pretend_now_is(due_date + submission_time_offset)
      apply_rule
      rule_overtime_message = rule.overtime_message(grouping)
      expected_overtime_message = I18n.t 'penalty_decay_period_submission_rules.overtime_message',
                                         potential_penalty: potential_penalty
      expect(rule_overtime_message).to eq expected_overtime_message
    end
  end

  context 'when the group submitted on time' do
    include_context 'submission_rule_on_time'
    context 'when the student did not submit any files' do
      before do
        pretend_now_is(collection_time) { grouping }
      end

      let(:submission) { create(:version_used_submission, grouping: grouping, is_empty: true) }
      let(:collection_time) { due_date - 5.days }

      it 'should not create an extra mark' do
        expect { apply_rule }.not_to(change { result.extra_marks.count })
      end
    end

    context 'when the student submitted a file' do
      it 'should not create an extra mark' do
        expect { apply_rule }.not_to(change { result.extra_marks.count })
      end
    end

    it_behaves_like 'valid overtime message', 0, -5.days
  end

  context 'when the group submitted during the first penalty period' do
    include_context 'submission_rule_during_first'
    it 'should create an extra mark' do
      expect { apply_rule }.to(change { result.extra_marks.count }.by(1))
    end

    it 'should create a percentage penalty' do
      apply_rule
      expect(result.extra_marks.first.unit).to eq ExtraMark::PERCENTAGE
    end

    it_behaves_like 'valid overtime message', 1.0, 10.hours
  end

  context 'when the group submitted during the second penalty period' do
    include_context 'submission_rule_during_second'
    it 'should create an extra mark' do
      expect { apply_rule }.to(change { result.extra_marks.count }.by(1))
    end

    it 'should create a percentage penalty' do
      apply_rule
      expect(result.extra_marks.first.unit).to eq ExtraMark::PERCENTAGE
    end

    it_behaves_like 'valid overtime message', 2.0, 25.hours
  end
end
