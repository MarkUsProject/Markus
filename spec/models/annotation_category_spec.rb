require 'spec_helper'

describe AnnotationCategory do
  let(:assignment) { create(:assignment) }
  let(:admin) { create(:admin) }

  describe 'validations hold' do
    subject { FactoryGirl.create(:annotation_category) }

    it { is_expected.to validate_presence_of(:annotation_category_name) }
    it { is_expected.to validate_presence_of(:assignment_id) }
    it { is_expected.to have_many(:annotation_texts) }
    it { is_expected.to belong_to(:assignment) }

    it do
      is_expected.to validate_uniqueness_of(:annotation_category_name)
                          .scoped_to(:assignment_id)
                          .with_message('is already taken')
    end
  end

  describe '.add_by_row' do
    context 'when no annotation categories exists' do
      before :each do
        @row = []
        @row.push('annotation category name')
        @row.push('annotation text 1')
        @row.push('annotation text 2')
      end

      it 'saves the annotation' do
        AnnotationCategory.add_by_row(@row, assignment, admin)
        expect(AnnotationCategory
                 .where(annotation_category_name: @row[0])).not_to be_nil
      end
    end

    context 'when the annotation category already exists' do
      before do
        @row = []
        @row.push('annotation category name 2')
        @row.push('annotation text 2 1')
        @row.push('annotation text 2 2')

        @initial_size = AnnotationCategory.all.size
      end

      # an annotation category has been created.
      it 'creates an annotation' do
        AnnotationCategory.add_by_row(@row, assignment, admin)
        expect(@initial_size + 1).to eq(AnnotationCategory.all.size)
      end
    end

    context 'when the text of the annotation category already exists' do
      before do
        @row = []
        @row.push('annotation category name 3')
        @row.push('annotation text 3 1')
        @row.push('annotation text 3 2')

        @initial_size = AnnotationText.all.size
      end

      it 'updates the numeber of annotation texts' do
        AnnotationCategory.add_by_row(@row, assignment, admin)
        expect(@initial_size + 2).to eq(AnnotationText.all.size)
      end
    end
  end
end
