describe ImageAnnotation do
  subject { create(:image_annotation) }

  it { is_expected.to validate_presence_of(:x1) }
  it { is_expected.to validate_presence_of(:y1) }
  it { is_expected.to validate_presence_of(:x2) }
  it { is_expected.to validate_presence_of(:y2) }
  it { is_expected.to validate_numericality_of(:x1) }
  it { is_expected.to validate_numericality_of(:y1) }
  it { is_expected.to validate_numericality_of(:x2) }
  it { is_expected.to validate_numericality_of(:y2) }
  it { is_expected.to have_one(:course) }

  it_behaves_like 'course associations'

  describe '#get_data' do
    let(:annotation) { create(:image_annotation) }
    let(:extra_keys) { Set[:x_range, :y_range] }

    it_behaves_like 'gets annotation data'
  end

  describe '#extract_coords' do
    context 'testing extract coords' do
      let(:basic_annot) do
        build_stubbed(:image_annotation, x1: 0, x2: 10, y1: 0, y2: 10, id: 100)
      end

      let(:negative_annot) do
        build_stubbed(:image_annotation, x1: -1, x2: 3, y1: -2, y2: 5, id: 101)
      end
      let(:spaces_annot) do
        build_stubbed(:image_annotation, x1: -1, x2: 3, y1: 123, y2: 5, id: 102)
      end

      it 'creates coords specified above for basic annot' do
        expected_basic_hash = { id: basic_annot.annotation_text_id,
                                annot_id: basic_annot.id,
                                x_range: { start: 0, end: 10 },
                                y_range: { start: 0, end: 10 } }

        expect(basic_annot.extract_coords).to eq(expected_basic_hash)
      end

      it 'creates negative coords as specified above' do
        expected_negative_hash = { id: negative_annot.annotation_text_id,
                                   annot_id: negative_annot.id,
                                   x_range: { start: -1, end: 3 },
                                   y_range: { start: -2, end: 5 } }

        expect(negative_annot.extract_coords).to eq(expected_negative_hash)
      end

      it 'creates coords as specified above for spaces_annot' do
        expected_spaces_hash = { id: spaces_annot.annotation_text_id,
                                 annot_id: spaces_annot.id,
                                 x_range: { start: -1, end: 3 },
                                 y_range: { start: 5, end: 123 } }

        expect(spaces_annot.extract_coords).to eq(expected_spaces_hash)
      end
    end
  end
end
