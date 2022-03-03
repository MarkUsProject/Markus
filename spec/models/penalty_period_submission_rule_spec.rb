describe PenaltyPeriodSubmissionRule do
  let(:rule_type) { :penalty_period_submission_rule }
  let(:result) { submission.get_latest_result }
  it { is_expected.to have_one(:course) }

  context 'when the group submitted on time' do
    include_context 'submission_rule_on_time'
    context 'when the student did not submit any files' do
      before :each do
        pretend_now_is(collection_time) { grouping }
      end
      let(:submission) { create :version_used_submission, grouping: grouping, is_empty: true }
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
  end
end
