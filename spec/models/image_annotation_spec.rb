require 'spec_helper'

describe ImageAnnotation do

  it { is_expected.to validate_presence_of(:x1) }
  it { is_expected.to validate_presence_of(:y1) }
  it { is_expected.to validate_presence_of(:x2) }
  it { is_expected.to validate_presence_of(:y2) }
  it { is_expected.to validate_numericality_of(:x1) }
  it { is_expected.to validate_numericality_of(:y1) }
  it { is_expected.to validate_numericality_of(:x2) }
  it { is_expected.to validate_numericality_of(:y2) }

  describe '#extract_coords' do
    context 'testing extract coords' do
      let(:basic_annot) do
        build_stubbed(:image_annotation, x1: 0, x2: 10, y1: 0, y2: 10)
      end

      let(:negative_annot) do
        build_stubbed(:image_annotation, x1: -1, x2: 3, y1: -2, y2: 5)
      end
      let(:spaces_annot) do
        build_stubbed(:image_annotation, x1: -1, x2: 3, y1: 123, y2: 5)
      end

      it 'creates coords specified above for basic annot' do
        expected_basic_hash = { id: basic_annot.annotation_text_id,
                                x_range: { start: 0, end: 10 },
                                y_range: { start: 0, end: 10 } }

        expect(basic_annot.extract_coords).to eq(expected_basic_hash)
      end

      it 'creates negative coords as specified above' do
        expected_negative_hash = { id: negative_annot.annotation_text_id,
                                   x_range: { start: -1, end: 3 },
                                   y_range: { start: -2, end: 5 } }

        expect(negative_annot.extract_coords).to eq(expected_negative_hash)
      end

      it 'creates coords as specified above for spaces_annot' do
        expected_spaces_hash = { id: spaces_annot.annotation_text_id,
                                 x_range: { start: -1, end: 3 },
                                 y_range: { start: 5, end: 123 } }

        expect(spaces_annot.extract_coords).to eq(expected_spaces_hash)
      end
    end
  end

  describe '#annotation_link_list_partial' do
    context 'testing annotation_link_list_partial' do
      let(:annotation) do
        build_stubbed(:image_annotation)
      end

      it 'renders partial' do
        expected = '/annotations/image_annotation_list_link'
        expect(annotation.annotation_list_link_partial).to eq(expected)
      end
    end
  end
end
