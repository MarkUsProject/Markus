describe AnnotationCategory do
  let(:assignment) { create(:assignment) }
  let(:admin) { create(:admin) }

  describe 'validations hold' do
    subject { FactoryBot.create(:annotation_category) }

    it { is_expected.to validate_presence_of(:annotation_category_name) }
    it { is_expected.to have_many(:annotation_texts) }
    it { is_expected.to belong_to(:assignment) }

    it { is_expected.to allow_value(nil).for(:flexible_criterion_id) }

    it do
      is_expected.to validate_uniqueness_of(:annotation_category_name).scoped_to(:assessment_id)
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

    context 'when the annotation category has no associated texts' do
      before do
        @row = ['annotation category name 4']
        @initial_size = AnnotationText.all.size
      end

      it 'creates an annotation category' do
        AnnotationCategory.add_by_row(@row, assignment, admin)
        expect(@initial_size + 1).to eq(AnnotationCategory.all.size)
      end
    end
  end

  describe '#update_annotation_text_deductions' do
    let(:assignment) { create(:assignment_with_deductive_annotations) }
    let(:annotation_category_with_criteria) do
      assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
    end

    it 'correctly scales annotation text deductions when called due to flexible_criterion_id update' do
      new_criterion = create(:flexible_criterion, assignment: assignment)
      assignment.groupings.includes(:current_result).each do |grouping|
        create(:mark,
               markable_id: new_criterion.id,
               markable_type: 'FlexibleCriterion',
               result: grouping.current_result)
      end
      annotation_category_with_criteria.update!(flexible_criterion_id: new_criterion.id)
      annotation_category_with_criteria.reload
      expect(annotation_category_with_criteria.annotation_texts.first.deduction).to eq(0.33)
    end

    it 'updates deductions to nil if it has its flexible_criterion disassociated from it' do
      annotation_category_with_criteria.update!(flexible_criterion_id: nil)
      annotation_category_with_criteria.reload
      expect(annotation_category_with_criteria.annotation_texts.first.deduction).to eq(nil)
    end

    it 'updates deductions to 0.0 if it becomes associated with a flexible_criterion after previously not being so' do
      new_assignment = create(:assignment_with_criteria_and_results)
      flex_criterion = new_assignment.flexible_criteria.first
      annotation_category = create(:annotation_category, assignment: new_assignment)
      create(:annotation_text, annotation_category: annotation_category)
      create(:annotation_text, annotation_category: annotation_category)
      annotation_category.update!(flexible_criterion_id: flex_criterion.id)
      annotation_text_deductions = []
      annotation_category.annotation_texts.each do |text|
        annotation_text_deductions << text.deduction
      end
      expect(annotation_text_deductions).to all( eq(0.0) )
    end
  end

  describe 'check_if_deductions_exist' do
    let(:assignment) { create(:assignment_with_deductive_annotations) }
    let(:annotation_category_with_criteria) do
      assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
    end

    it 'prevent deletion of an annotation_category if results were released' do
      assignment.groupings.first.current_result.update!(released_to_students: true)
      expect { assignment.annotation_categories.destroy_all }.to raise_error ActiveRecord::RecordNotDestroyed
    end

    it 'prevent deletion of an annotation_category if deductions have been applied' do
      expect { assignment.annotation_categories.destroy_all }.to raise_error ActiveRecord::RecordNotDestroyed
    end

    it 'do not prevent deletion of an annotation_category if annotations have no deduction' do
      annotation_category_with_criteria.update!(flexible_criterion_id: nil)
      expect { assignment.annotation_categories.destroy_all }.to_not raise_error
    end
  end
end
