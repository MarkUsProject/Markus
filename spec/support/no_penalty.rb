shared_examples 'No penalty' do
  describe 'When the student did not submit any files' do
    it 'should not add any extra mark' do
      @rule.apply_submission_rule(@submission)
      result = @submission.get_latest_result
      expect(result).not_to be_nil
      expect(result.extra_marks).to be_empty
      expect(result.get_total_extra_percentage).to eq 0
    end
  end
end
