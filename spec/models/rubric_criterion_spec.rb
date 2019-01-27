describe RubricCriterion do
  let(:criterion_factory_name) { :rubric_criterion }

  it_behaves_like 'a criterion'

  context 'A good rubric criterion model' do

    before(:each) do
      @rubric = create(:rubric_criterion)
    end

    it{is_expected.to belong_to(:assignment)}
    it{is_expected.to validate_numericality_of(:max_mark)}
    it{is_expected.to validate_presence_of(:max_mark)}
    it{is_expected.to validate_presence_of(:name)}

    # Test that Criteria assigned to non-existent Assignment
    #is NOT OK
    def test_assignment_id_dne
      assignment_id_dne = create(:rubric_criterion)
      assignment_id_dne.assignment = create(:assignment)
      assert !assignment_id_dne.save
    end

    it 'should round weights that have more than 1 significant digits' do
      expect(RubricCriterion.count).to be >0
      criterion = RubricCriterion.first
      criterion.max_mark = 0.5555555555
      criterion.save
      expect(criterion.max_mark).to eq 0.6
    end

    it 'find a mark for a specific rubric and result' do
      assignment = create(:assignment)
      grouping = create(:grouping, assignment: assignment)
      submission = create(:submission, grouping: grouping)

      complete_result = create(:complete_result, submission: submission)

      rubric = create(:rubric_criterion, assignment: assignment)

      mark = create(:mark, result: complete_result, markable: rubric)

      expect(rubric.mark_for(complete_result.id))
    end

    it 'Set default levels' do
      r = RubricCriterion.new
      expect(r.set_default_levels)
      r.save
      expect(r.level_0_name).to eq(I18n.t('rubric_criteria.defaults.level_0'))
      expect(r.level_1_name).to eq(I18n.t('rubric_criteria.defaults.level_1'))
      expect(r.level_2_name).to eq(I18n.t('rubric_criteria.defaults.level_2'))
      expect(r.level_3_name).to eq(I18n.t('rubric_criteria.defaults.level_3'))
      expect(r.level_4_name).to eq(I18n.t('rubric_criteria.defaults.level_4'))
    end

    it 'be able to set all the level names at once' do
      r = RubricCriterion.new
      levels = []
      0.upto(RubricCriterion::RUBRIC_LEVELS - 1) do |i|
        levels << 'l' + i.to_s()
      end
      expect(r).to receive(:save).once
      r.set_level_names(levels)
      0.upto(RubricCriterion::RUBRIC_LEVELS - 1) do |i|
        expect(r['level_' + i.to_s() + '_name']).to eq('l' + i.to_s())
      end

    end

  end

  context 'A rubric criterion assigning a TA' do
    before(:each) do
      @criterion = create(:rubric_criterion)
      @ta = create(:ta)
    end

    it 'assign a TA by id' do
      expect(@criterion.criterion_ta_associations.count).to eq(0), 'Got unexpected TA membership count'
      @criterion.add_tas(@ta)
      expect(@criterion.criterion_ta_associations.count).to eq(1), 'Got unexpected TA membership count'
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
      expect(@criterion.criterion_ta_associations.count).to eq(1), 'Got unexpected TA membership count'
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
      @criterion.remove_tas([ta1, @a3])
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
          expect {
            RubricCriterion.create_or_update_from_csv_row([], @assignment).to raise_error(CSVInvalidLineError)
          }
        end
      end
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on a 1 element row' do
        it 'raises' do
          expect {
            rubric.create_or_update_from_csv_row(%w(name), @assignment).to raise_error(CSVInvalidLineError)
          }
        end
      end
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on a 2 element row' do
        it 'raises' do
          expect {
            rubric.create_or_update_from_csv_row(%w(name 1.0), @assignment).to raise_error(CSVInvalidLineError)
          }
        end
      end
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on rows with elements without names for every criterion' do
        row = %w(name 1.0)
        (0..RubricCriterion::RUBRIC_LEVELS - 2).each do |i|
          row << 'name' + i.to_s
          it 'raises' do
            expect {
              RubricCriterion.create_or_update_from_csv_row(row, @assignment).to raise_error(CSVInvalidLineError)
            }
          end
        end
      end
    end

    context 'when parsing a CSV file' do
      describe 'raise csv line error on a row with an invalid weight' do
        row = %w(name max_mark l0 l1 l2 l3 l4)
        it 'raises' do
          expect {
            RubricCriterion.create_or_update_from_csv_row(row, @assignment).to raise_error(CSVInvalidLineError)
          }
        end
      end
    end

    context 'and the row is valid' do
      before(:each) do
        # we'll need a valid assignment for those cases.
        @assignment = create(:assignment)
        @row = ['criterion 5', '1.0']
        (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
          @row << 'name' + i.to_s
        end
        # ...containing commas and quotes in the descriptions
        (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
          @row << 'description' + i.to_s + ' with comma (,) and ""quotes""'
        end
        @csv_base_row = @row
      end
    end

    context 'be able to create a new instance without level descriptions' do
      criterion = RubricCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
      expect(criterion).not_to be_nil
      expect(criterion).to be_an_instance_of(RubricCriterion)
      expect(criterion.assignment).to equal(@assignment)
    end

    should 'be able to create a new instance without level descriptions' do
      criterion = RubricCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
      assert_not_nil criterion
      assert_instance_of RubricCriterion, criterion
      assert_equal criterion.assignment, @assignment
      (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
        assert_equal 'name' + i.to_s, criterion['level_' + i.to_s + '_name']
      end
    end

  end

end

