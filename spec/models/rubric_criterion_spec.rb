describe RubricCriterion do
  let(:criterion_factory_name) { :rubric_criterion }

  it_behaves_like 'a criterion'
  context 'A good rubric criterion model' do
    before(:each) do
      @rubric = create(:rubric_criterion)
    end

    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to validate_numericality_of(:max_mark) }
    it { is_expected.to validate_presence_of(:max_mark) }
    it { is_expected.to validate_presence_of(:name) }

    it 'rounds weights that have more than 1 significant digits' do
      expect(RubricCriterion.count).to be > 0
      criterion = RubricCriterion.first
      criterion.max_mark = 0.5555555555
      criterion.save
      expect(criterion.max_mark).to eq 0.6
    end

    it 'finds a mark for a specific rubric and result' do
      assignment = create(:assignment)
      rubric = create(:rubric_criterion, assignment: assignment)
      grouping = create(:grouping, assignment: assignment)
      submission = create(:submission, grouping: grouping)
      incomplete_result = create(:incomplete_result, submission: submission)

      mark = rubric.mark_for(incomplete_result.id)
      expect(mark).to_not be_nil
      expect(mark.mark).to be_nil
    end

    it 'sets default levels' do
      assignment = create(:assignment)
      rubric = create(:rubric_criterion, assignment: assignment)
      rubric.levels.delete_all
      rubric.set_default_levels
      levels = rubric.levels
      expect(levels[0].name).to eq(I18n.t('rubric_criteria.defaults.level_0'))
      expect(levels[1].name).to eq(I18n.t('rubric_criteria.defaults.level_1'))
      expect(levels[2].name).to eq(I18n.t('rubric_criteria.defaults.level_2'))
      expect(levels[3].name).to eq(I18n.t('rubric_criteria.defaults.level_3'))
      expect(levels[4].name).to eq(I18n.t('rubric_criteria.defaults.level_4'))
    end
  end

  context 'from an assignment without criteria' do
    before(:each) do
      @assignment = create(:assignment)
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on an empty row' do
        it 'raises' do
          expect do
            RubricCriterion.create_or_update_from_csv_row([], @assignment)
                           .to raise_error CsvInvalidLineError
          end
        end
      end
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on a 1 element row' do
        it 'raises' do
          expect do
            RubricCriterion.create_or_update_from_csv_row(%w[name], @assignment)
                           .to raise_error CsvInvalidLineError
          end
        end
      end
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on a 2 element row' do
        it 'raises' do
          expect do
            RubricCriterion.create_or_update_from_csv_row(%w[name 1.0], @assignment)
                           .to raise_error CsvInvalidLineError
          end
        end
      end
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on rows with elements without names for every criterion' do
        row = %w[name 1.0]
        levels = 5
        (0..levels).each do |i|
          row << 'name' + i.to_s
          it 'raises' do
            expect do
              RubricCriterion.create_or_update_from_csv_row(row, @assignment)
                             .to raise_error CsvInvalidLineError
            end
          end
        end
      end
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on a row with an invalid weight' do
        row = %w[name max_mark l0 l1 l2 l3 l4]
        it 'raises' do
          expect do
            RubricCriterion.create_or_update_from_csv_row(row, @assignment)
                           .to raise_error CsvInvalidLineError
          end
        end
      end
    end
  end

  context 'from an assignment without criteria' do
    before(:each) do
      @assignment = create(:assignment)
    end

    context 'and the row is valid' do
      before(:each) do
        # we'll need a valid assignment for those cases.
        @assignment = create(:assignment)
        row = ['criterion 5']
        rubric_levels = 5
        # order is name, number, description, mark
        (0..rubric_levels - 1).each do |i|
          row << 'name' + i.to_s
          # ...containing commas and quotes in the descriptions
          row << 'description' + i.to_s + ' with comma (,) and ""quotes""'
          row << i + 10
        end
        @csv_base_row = row
      end

      context 'and there is an existing rubric criterion with the same name' do
        before(:each) do
          @criterion = create(:rubric_criterion, assignment: @assignment)
          @criterion.levels.delete_all
          @criterion.set_default_levels
          # 'criterion 5' is the name used in the criterion held
          # in @csv_base_row - but they use different level names/descriptions.
          # I'll use the defaults here, and see if I can overwrite with
          # @csv_base_row.
          @criterion.name = 'criterion 5'
          @criterion.assignment = @assignment
          @criterion.position = @assignment.next_criterion_position
          @criterion.max_mark = 5.0
          expect(@criterion.save)
        end

        context 'allow a criterion with the same name to overwrite' do
          it 'not raise error' do
            names = ['Very Poor', 'Weak', 'Passable', 'Good', 'Excellent']
            row = ['criterion 5']
            # order is name, number, description, mark
            (0..@criterion.levels.length - 1).each do |i|
              row << names[i]
              # ...containing commas and quotes in the descriptions
              row << 'new description number ' + i.to_s
              row << i + 10
            end

            RubricCriterion.create_or_update_from_csv_row(row, @assignment)
            @criterion.reload
            levels = @criterion.levels
            expect(levels.length).to eq(5)
            (0..levels.length - 1).each do |i|
              expect(names[i]).to eq(levels[i].name)
              expect('new description number ' + i.to_s).to eq(levels[i].description)
            end
          end
        end

        context 'allow a criterion with the same name to add levels' do
          it 'not raise error' do
            RubricCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
            @criterion.reload
            levels = @criterion.levels
            expect(levels[0].mark).to eq(0.0)
            expect(levels.length).to eq(10)
          end
        end
      end
    end
  end

  context 'A rubric criteria with levels' do
    before(:each) do
      @criterion = create(:rubric_criterion)
      @levels = @criterion.levels
    end

    context 'has basic levels functionality' do
      describe 'can add levels' do
        it 'not raise error' do
          expect(@levels.length).to eq(5)
          @levels.create(name: 'New level', description: 'Description for level', mark: '5')
          @levels.create(name: 'New level 2', description: 'Description for level 2', mark: '6')
          expect(@levels.length).to eq(7)
        end
      end

      describe 'can delete levels' do
        it 'not raise error' do
          expect(@levels.length).to eq(5)
          @levels.destroy_by(mark: 0)
          @levels.destroy_by(mark: 1)
          @levels.reload
          expect(@levels.length).to eq(3)
        end
      end

      describe 'can edit levels' do
        it 'not raise error' do
          @levels[0].update(name: 'Custom Level', description: 'Custom Description', mark: 10.0)
          @levels.reload
          expect(@levels[@levels.length - 1].mark).to eq(10)
          expect(@levels[@levels.length - 1].name).to eq('Custom Level')
          expect(@levels[@levels.length - 1].description).to eq('Custom Description')
        end
      end

      describe 'deleting a rubric criterion deletes all levels' do
        it 'not raise error' do
          @criterion.destroy
          expect(@criterion.destroyed?).to eq true
          expect(@levels).to be_empty
        end
      end
    end

    context 'when scaling max mark' do
      describe 'can scale levels up' do
        it 'not raise error' do
          expect(@levels[1].mark).to eq(1.0)
          @criterion.update(max_mark: 8.0)
          expect(@levels[1].mark).to eq(2.0)
        end
      end
      describe 'can scale levels down' do
        it 'not raise error' do
          expect(@levels[1].mark).to eq(1.0)
          @criterion.update(max_mark: 2.0)
          expect(@levels[1].mark).to eq(0.5)
        end
      end
      describe 'manually changed levels won\'t be affected' do
        it 'not raise error' do
          expect(@levels[1].mark).to eq(1.0)
          @levels[1].mark = 3
          @criterion.update(max_mark: 8.0)
          expect(@levels[1].mark).to eq(3.0)
        end
      end
    end

    context 'editing levels edits marks' do
      before(:each) do
        @marks = @criterion.marks
        result1 = create(:result, marking_state: Result::MARKING_STATES[:incomplete])
        result2 = create(:result, marking_state: Result::MARKING_STATES[:incomplete])
        result3 = create(:result, marking_state: Result::MARKING_STATES[:incomplete])
        @marks.create(mark: 0, result: result1)
        @marks.create(mark: 1, result: result2)
        @marks.create(mark: 1, result: result3)
      end

      context 'updating level updates respective mark' do
        describe 'updates a single mark' do
          it 'not raise error' do
            @levels[0].update(mark: 0.5)
            @marks.reload
            expect(@marks[0].mark).to eq(0.5)
          end
        end

        describe 'updates multiple marks' do
          it 'not raise error' do
            @levels[1].update(mark: 0.5)
            expect(@marks[1].mark).to eq(0.5)
            expect(@marks[2].mark).to eq(0.5)
          end
        end
      end

      context 'deleting level updates mark to nil' do
        describe 'updates a single mark' do
          it 'not raise error' do
            @levels[0].destroy
            expect(@marks[0].mark).to be_nil
          end
        end

        describe 'deleting level updates multiple marks to nil' do
          it 'not raise error' do
            @levels[1].destroy
            expect(@marks[1].mark).to be_nil
            expect(@marks[2].mark).to be_nil
          end
        end
      end
    end

    context 'validations work properly' do
      describe 'validates max mark can\' be greater than maximum level mark' do
        it 'raises an error' do
          expect(@levels.last.mark).to eq(4.0)
          expect(@criterion.max_mark).to eq(4.0)
          @criterion.update(max_mark: 5.0)
          @criterion.levels.last.update(mark: 3.5)
          @criterion.save
          expect(@criterion.errors[:max_mark].size).to eq(1)
        end
      end

      describe 'cannot have two levels with the same mark' do
        it 'not raise error' do
          expect(@levels[0].update(mark: 1)).to be false
        end
      end
    end
  end
end
