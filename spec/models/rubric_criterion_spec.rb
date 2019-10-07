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
      r = RubricCriterion.new
      r.set_default_levels
      byebug
      expect(r.LEVELS[0]).to eq(I18n.t('rubric_criteria.defaults.level_0'))
      expect(r.LEVELS[1]).to eq(I18n.t('rubric_criteria.defaults.level_1'))
      expect(r.LEVELS[2]).to eq(I18n.t('rubric_criteria.defaults.level_2'))
      expect(r.LEVELS[3]).to eq(I18n.t('rubric_criteria.defaults.level_3'))
      expect(r.LEVELS[4]).to eq(I18n.t('rubric_criteria.defaults.level_4'))
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
        (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
          row << 'name' + i.to_s
        end
        # ...containing commas and quotes in the descriptions
        (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
          row << 'description' + i.to_s + ' with comma (,) and ""quotes""'
        end
        @csv_base_row = row
      end

      it 'be able to create a new instance without level descriptions' do
        criterion = RubricCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
        expect(criterion).not_to be_nil
        expect(criterion).to be_an_instance_of(RubricCriterion)
        expect(criterion.assignment).to eq(@assignment)
        (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
          expect('name' + i.to_s).to eq(criterion['level_' + i.to_s + '_name'])
        end
      end

      context 'and there is an existing rubric criterion with the same name' do
        setup do
          criterion = RubricCriterion.new
          criterion.set_default_levels
          # 'criterion 5' is the name used in the criterion held
          # in @csv_base_row - but they use different level names/descriptions.
          # I'll use the defaults here, and see if I can overwrite with
          # @csv_base_row.
          criterion.name = 'criterion 5'
          criterion.assignment = @assignment
          criterion.position = @assignment.next_criterion_position
          criterion.max_mark = 5.0
          expect(criterion.save)
        end

        context 'allow a criterion with the same name to overwrite' do
          it 'not raise error' do
            criterion = RubricCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
            (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
              expect('name' + i.to_s).to eq(criterion['level_' + i.to_s + '_name'])
              expect(4.0).to eq(criterion.max_mark)
            end
          end
        end

        context 'be able to create a new instance with level descriptions' do
          it 'not raise error' do
            criterion = RubricCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
            expect(criterion).not_to be_nil
            expect(criterion).to be_an_instance_of(RubricCriterion)
            expect(criterion.assignment).to eq(@assignment)
            (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
              assert_equal 'name' + i.to_s, criterion['level_' + i.to_s + '_name']
              expect('name' + i.to_s).to eq(criterion['level_' + i.to_s + '_name'])
              expect(
                'description' + i.to_s + ' with comma (,) and ""quotes""'
              ).to eq(criterion['level_' + i.to_s + '_description'])
            end
          end
        end
      end
    end
  end
end
