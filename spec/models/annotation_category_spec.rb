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

    context 'when changing flexible criterion id' do
      let(:assignment) { create(:assignment_with_deductive_annotations) }
      let(:category) { assignment.annotation_categories.where.not(flexible_criterion_id: nil).first }

      it 'does not allow the flexible_criterion_id to be set to reference a criterion of another assignment' do
        other_assignment = create(:assignment_with_criteria_and_results)
        other_criterion_id = other_assignment.criteria.where(type: 'FlexibleCriterion').first.id
        category.flexible_criterion_id = other_criterion_id
        expect(category).to_not be_valid
      end

      it 'allows the flexible_criterion_id to be set to reference a criterion of its assignment' do
        other_criterion = create(:flexible_criterion, assignment: assignment)
        category.flexible_criterion_id = other_criterion.id
        expect(category).to be_valid
      end
    end
  end

  describe '.add_by_row' do
    it 'returns an error message if the category name is blank' do
      row = [nil, 'criterion_name', 'text_content', '1.0']
      expected_message = I18n.t('annotation_categories.upload.empty_category_name')
      expect { AnnotationCategory.add_by_row(row, assignment, admin) }.to raise_error(CsvInvalidLineError,
                                                                                      expected_message)
    end

    it 'returns an error message if a criterion with the name given does not exist' do
      row = ['category_name', 'criterion_name', 'text_content', '1.0']
      expected_message = I18n.t('annotation_categories.upload.criterion_not_found',
                                missing_criterion: 'criterion_name')
      expect { AnnotationCategory.add_by_row(row, assignment, admin) }.to raise_error(CsvInvalidLineError,
                                                                                      expected_message)
    end

    it 'returns an error message if a criterion with the name given exists only as a non flexible criterion' do
      row = ['category_name', 'criterion_name', 'text_content', '1.0']
      create(:rubric_criterion, assignment: assignment, name: 'criterion_name')
      expected_message = I18n.t('annotation_categories.upload.criterion_not_found',
                                missing_criterion: 'criterion_name')
      expect { AnnotationCategory.add_by_row(row, assignment, admin) }.to raise_error(CsvInvalidLineError,
                                                                                      expected_message)
    end

    it 'returns an error message if a deduction given for an annotation text '\
       'is greater than the max mark of the criterion' do
      row = ['category_name', 'criterion_name', 'text_content', '1.0']
      create(:flexible_criterion, assignment: assignment, name: 'criterion_name', max_mark: 0.5)
      expected_message = I18n.t('annotation_categories.upload.invalid_deduction',
                                annotation_content: 'text_content',
                                criterion_name: 'criterion_name',
                                value: 1.0)
      expect { AnnotationCategory.add_by_row(row, assignment, admin) }.to raise_error(CsvInvalidLineError,
                                                                                      expected_message)
    end

    it 'returns an error message if a deduction given for an annotation text is negative' do
      row = ['category_name', 'criterion_name', 'text_content', '-1.0']
      create(:flexible_criterion, assignment: assignment, name: 'criterion_name', max_mark: 1.5)
      expected_message = I18n.t('annotation_categories.upload.invalid_deduction',
                                annotation_content: 'text_content',
                                criterion_name: 'criterion_name',
                                value: -1.0)
      expect { AnnotationCategory.add_by_row(row, assignment, admin) }.to raise_error(CsvInvalidLineError,
                                                                                      expected_message)
    end

    it 'rounds value if a deduction given for an annotation text is specified past two decimal points' do
      row = ['category_name', 'criterion_name', 'text_content', '1.333']
      create(:flexible_criterion, assignment: assignment, name: 'criterion_name', max_mark: 1.5)
      AnnotationCategory.add_by_row(row, assignment, admin)
      expect(AnnotationText.find_by(content: 'text_content').deduction).to eq(1.33)
    end

    it 'returns an error message if given another text rather than a deduction for an annotation text '\
       'despite there being a criterion specified for the category' do
      row = %w[category_name criterion_name text_content other_text_content]
      create(:flexible_criterion, assignment: assignment, name: 'criterion_name', max_mark: 0.5)
      expected_message = I18n.t('annotation_categories.upload.deduction_absent',
                                value: 'other_text_content',
                                annotation_category: 'category_name')
      expect { AnnotationCategory.add_by_row(row, assignment, admin) }.to raise_error(CsvInvalidLineError,
                                                                                      expected_message)
    end

    it 'returns an error message if given nil rather than a deduction for an annotation text '\
       'despite there being a criterion specified for the category' do
      row = ['category_name', 'criterion_name', 'text_content', nil]
      create(:flexible_criterion, assignment: assignment, name: 'criterion_name', max_mark: 0.5)
      expected_message = I18n.t('annotation_categories.upload.deduction_absent',
                                value: nil,
                                annotation_category: 'category_name')
      expect { AnnotationCategory.add_by_row(row, assignment, admin) }.to raise_error(CsvInvalidLineError,
                                                                                      expected_message)
    end

    context 'when no annotation categories exists' do
      before :each do
        @row = []
        @row.push('annotation category name')
        @row.push(nil)
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
        @row.push(nil)
        @row.push('annotation text 2 1')
        @row.push('annotation text 2 2')

        @initial_size = AnnotationCategory.all.size
      end

      # an annotation category has been created.
      it 'creates an annotation' do
        AnnotationCategory.add_by_row(@row, assignment, admin)
        expect(@initial_size + 1).to eq(AnnotationCategory.all.size)
      end

      context 'and the assignment has deductive annotations' do
        let(:assignment) { create(:assignment_with_deductive_annotations) }
        let(:category) { assignment.annotation_categories.where.not(flexible_criterion_id: nil).first }

        it 'does not allow the flexible criterion to change to nil' do
          row = [category.annotation_category_name, nil, 'text 1']
          expected_message = I18n.t('annotation_categories.upload.invalid_criterion',
                                    annotation_category: category.annotation_category_name)
          expect { AnnotationCategory.add_by_row(row, assignment, admin) }.to raise_error(CsvInvalidLineError,
                                                                                          expected_message)
        end

        it 'does not allow the flexible criterion for the category to change to a different criterion' do
          other_criterion = create(:flexible_criterion, assignment: assignment)
          row = [category.annotation_category_name, other_criterion.name, 'text 1', 1.0]
          expected_message = I18n.t('annotation_categories.upload.invalid_criterion',
                                    annotation_category: category.annotation_category_name)
          expect { AnnotationCategory.add_by_row(row, assignment, admin) }.to raise_error(CsvInvalidLineError,
                                                                                          expected_message)
        end

        it 'does not allow a criterion to be specified for the category if the category did not have one previously' do
          other_category = create(:annotation_category, assignment: assignment)
          row = [other_category.annotation_category_name,
                 assignment.criteria.where(type: 'FlexibleCriterion').first.name,
                 'text 1', 1.0]
          expected_message = I18n.t('annotation_categories.upload.invalid_criterion',
                                    annotation_category: other_category.annotation_category_name)
          expect { AnnotationCategory.add_by_row(row, assignment, admin) }.to raise_error(CsvInvalidLineError,
                                                                                          expected_message)
        end
      end
    end

    context 'when the text of the annotation category already exists' do
      before do
        @row = []
        @row.push('annotation category name 3')
        @row.push(nil)
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
        @row = ['annotation category name 4', nil]
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
               criterion_id: new_criterion.id,
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
      flex_criterion = new_assignment.criteria.where(type: 'FlexibleCriterion').first
      annotation_category = create(:annotation_category, assignment: new_assignment)
      create(:annotation_text, annotation_category: annotation_category)
      create(:annotation_text, annotation_category: annotation_category)
      annotation_category.update!(flexible_criterion_id: flex_criterion.id)
      annotation_text_deductions = []
      annotation_category.annotation_texts.each do |text|
        annotation_text_deductions << text.deduction
      end
      expect(annotation_text_deductions).to all(eq(0.0))
    end
  end

  describe 'delete_allowed?' do
    let(:assignment) { create(:assignment_with_deductive_annotations) }
    let(:annotation_category_with_criteria) do
      assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
    end

    it 'prevents deletion of an annotation_category if results were released and annotations have deductions' do
      assignment.groupings.first.current_result.update!(released_to_students: true)
      expect { assignment.annotation_categories.destroy_all }.to raise_error ActiveRecord::RecordNotDestroyed
    end

    it 'does not prevent deletion of an annotation_category if annotations have '\
       'no deduction and results not released' do
      annotation_category_with_criteria.update!(flexible_criterion_id: nil)
      expect { assignment.annotation_categories.destroy_all }.to_not raise_error
    end

    it 'does not prevent deletion of an annotation_category if annotations have no deduction and results released' do
      annotation_category_with_criteria.update!(flexible_criterion_id: nil)
      assignment.groupings.first.current_result.update!(released_to_students: true)
      expect { assignment.annotation_categories.destroy_all }.to_not raise_error
    end

    it 'does not prevent deletion of an annotation_category if results not released and annotations have deductions' do
      expect { assignment.annotation_categories.destroy_all }.to_not raise_error
    end

    it 'does not prevent deletion of an annotation_category if results released '\
       'and annotations have deductions of value 0 only' do
      annotation_category_with_criteria.annotation_texts.first.update!(deduction: 0)
      expect { assignment.annotation_categories.destroy_all }.to_not raise_error
    end
  end
end
