shared_examples 'gets annotation data' do
  let(:keys) do
    extras = defined?(extra_keys) ? extra_keys : Set.new
    Set[:id, :filename, :path, :submission_file_id, :annotation_text_id,
        :content, :annotation_category, :annotation_category_id, :type,
        :number, :is_remark, :deduction, :criterion_id, :criterion_name] + extras
  end
  context 'when include_creator is false' do
    it 'gets all data' do
      data = annotation.get_data(include_creator: false)
      expect(Set.new(data.keys)).to eq(keys + [:creator])
      expect(data[:creator]).to eq(I18n.t('users.deleted'))
    end
  end

  context 'when include_creator is true' do
    it 'gets all data including creator' do
      expect(Set.new(annotation.get_data(include_creator: true).keys)).to eq keys + [:creator]
    end
  end
end
