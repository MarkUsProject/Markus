describe TextAnnotation do
  context 'A valid TextAnnotation model' do
    subject { create(:text_annotation) }

    it { is_expected.to validate_presence_of(:line_start) }
    it { is_expected.to validate_presence_of(:line_end) }
    it { is_expected.to allow_value(10).for(:line_start) }
    it { is_expected.to allow_value(10).for(:line_end) }

    include_examples 'course associations'

    describe '#get_data' do
      let(:annotation) { create(:text_annotation) }
      let(:extra_keys) { Set[:line_start, :line_end, :column_start, :column_end] }

      it_behaves_like 'gets annotation data'
    end

    # TODO: Change Model.
    # We should not allow negative values vor lines
    # should_not allow_value(-1).for(:line_start)
    # should_not allow_value(-1).for(:line_end)
  end
end
