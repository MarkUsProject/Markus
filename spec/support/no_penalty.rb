shared_examples 'No penalty' do
  describe 'When the student did not submit any files' do
    it 'should not add any extra mark' do
      result = @submission.get_latest_result
      expect(result).not_to be_nil
      expect(result.extra_marks).to be_empty
      expect(result.get_total_extra_percentage).to eq 0
    end
  end
end
