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
      rubric.set_default_levels
      levels = rubric.levels
      expect(levels[0].name).to eq(I18n.t('rubric_criteria.defaults.level_0'))
      expect(levels[1].name).to eq(I18n.t('rubric_criteria.defaults.level_1'))
      expect(levels[2].name).to eq(I18n.t('rubric_criteria.defaults.level_2'))
      expect(levels[3].name).to eq(I18n.t('rubric_criteria.defaults.level_3'))
      expect(levels[4].name).to eq(I18n.t('rubric_criteria.defaults.level_4'))
    end
  end

  context 'A rubric criterion assigning a TA' do
    before(:each) do
      @criterion = create(:rubric_criterion)
      @ta = create(:ta)
    end

    it 'not assign the same TA multiple times' do
      expect(@criterion.criterion_ta_associations.count).to eq(0), 'Got unexpected TA membership count'
      @criterion.add_tas(@ta)
      @ta.reload
      @criterion.add_tas(@ta)
      expect(@criterion.criterion_ta_associations.count).to eq(1), 'Got unexpected TA membership count'
    end

    it 'unassign a TA by id' do
      expect(@criterion.criterion_ta_associations.count).to eq(0), 'Got unexpected TA membership count'
      @criterion.add_tas(@ta)
      expect(@criterion.criterion_ta_associations.count).to eq(1), 'Got unexpected TA membership count'
      @ta.reload
      @criterion.remove_tas(@ta)
      expect(@criterion.criterion_ta_associations.count).to eq(0), 'Got unexpected TA membership count'
    end

    it 'assign multiple TAs' do
      ta1 = create(:ta)
      ta2 = create(:ta)
      ta3 = create(:ta)
      expect(@criterion.criterion_ta_associations.count).to eq(0), 'Got unexpected TA membership count'
      @criterion.add_tas([ta1, ta2, ta3])
      expect(@criterion.criterion_ta_associations.count).to eq(3), 'Got unexpected TA membership count'
    end

    it 'remove multiple TAs' do
      ta1 = create(:ta)
      ta2 = create(:ta)
      ta3 = create(:ta)
      expect(@criterion.criterion_ta_associations.count).to eq(0)
      @criterion.add_tas([ta1, ta2, ta3])
      expect(@criterion.criterion_ta_associations.count).to eq(3)
      ta1.reload
      ta2.reload
      ta3.reload
      @criterion.remove_tas([ta1, ta3])
      expect(@criterion.criterion_ta_associations.count).to eq(1)
      @criterion.reload
      expect(ta2.id).to be == @criterion.tas[0].id
    end

    it 'get the names of TAs assigned to it' do
      ta1 = create(:ta)
      ta2 = create(:ta)
      @criterion.add_tas(ta1)
      @criterion.add_tas(ta2)
      expect(@criterion.get_ta_names).to contain_exactly(ta1.user_name, ta2.user_name)
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
        (0..RubricCriterion::RUBRIC_LEVELS - 2).each do |i|
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
        row = ['criterion 5', '1.0']
        # order is name, number, description, mark
        (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
          row << 'name' + i.to_s
          row << i
          # ...containing commas and quotes in the descriptions
          row << 'description' + i.to_s + ' with comma (,) and ""quotes""'
          row << i
        end
        @csv_base_row = row
      end

      context 'and there is an existing rubric criterion with the same name' do
        before(:each) do
          @criterion = create(:rubric_criterion, assignment: @assignment)
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
            row = ['criterion 5', '1.0']
            # order is name, number, description, mark
            (0..@criterion.levels.length - 1).each do |i|
              row << names[i]
              row << i
              # ...containing commas and quotes in the descriptions
              row << 'new description number ' + i.to_s
              row << i
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
            levels = @criterion.levels
            expect(levels[0].mark).to eq(0.0)
            expect(levels.length).to eq(10)
          end
        end
      end
    end
  end
end
