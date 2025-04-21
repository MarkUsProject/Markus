describe TextAnnotation do
  context 'A valid TextAnnotation model' do
    subject { create(:text_annotation) }

    it { is_expected.to validate_presence_of(:line_start) }
    it { is_expected.to validate_presence_of(:line_end) }
    it { is_expected.to validate_presence_of(:column_start) }
    it { is_expected.to validate_presence_of(:column_end) }

    it { is_expected.to allow_value(1).for(:line_start) }
    it { is_expected.to allow_value(1).for(:line_end) }
    it { is_expected.to allow_value(0).for(:column_start) }
    it { is_expected.to allow_value(0).for(:column_end) }

    it { is_expected.to allow_value(10).for(:line_start) }
    it { is_expected.to allow_value(10).for(:line_end) }
    it { is_expected.to allow_value(5).for(:column_start) }
    it { is_expected.to allow_value(5).for(:column_end) }

    it { is_expected.not_to allow_value(0).for(:line_start) }
    it { is_expected.not_to allow_value(0).for(:line_end) }
    it { is_expected.not_to allow_value(-1).for(:line_start) }
    it { is_expected.not_to allow_value(-1).for(:line_end) }
    it { is_expected.not_to allow_value(-1).for(:column_start) }
    it { is_expected.not_to allow_value(-1).for(:column_end) }

    it_behaves_like 'course associations'

    describe '#get_data' do
      let(:annotation) { create(:text_annotation) }
      let(:extra_keys) { Set[:line_start, :line_end, :column_start, :column_end] }

      it_behaves_like 'gets annotation data'
    end
  end
end
