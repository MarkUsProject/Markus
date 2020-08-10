shared_examples 'gets annotation data' do
  let(:keys) do
    extras = defined?(extra_keys) ? extra_keys : Set.new
    Set[:id, :filename, :path, :submission_file_id, :annotation_text_id,
        :content, :annotation_category, :type, :number, :is_remark, :deduction,
        :criterion_id, :criterion_name] + extras
  end
  context 'when include_creator is false' do
    it 'gets all data' do
      expect(Set.new(annotation.get_data(false).keys)).to eq keys
    end
  end
  context 'when include_creator is true' do
    it 'gets all data including creator' do
      expect(Set.new(annotation.get_data(true).keys)).to eq keys + [:creator]
    end
  end
end
