describe FlexibleCriterion do
  let(:criterion_factory_name) { :flexible_criterion }

  context 'A good FlexibleCriterion model' do
    before :each do
      @criterion = create(:flexible_criterion)
    end

    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:max_mark) }

    it do
      is_expected.to validate_uniqueness_of(:name).scoped_to(:assignment_id)
                       .with_message('Criterion name already used.')
    end

    it do
      is_expected.to validate_numericality_of(:max_mark).with_message(I18n.t('criteria.errors.messages.input_number'))
    end

    it { is_expected.to allow_value(0.1).for(:max_mark) }
    it { is_expected.to allow_value(1.0).for(:max_mark) }
    it { is_expected.to allow_value(100.0).for(:max_mark) }
    it { is_expected.not_to allow_value(0.0).for(:max_mark) }
    it { is_expected.not_to allow_value(-1.0).for(:max_mark) }
    it { is_expected.not_to allow_value(-100.0).for(:max_mark) }
  end

  context 'With non-existent criteria' do
    before :each do
      @assignment = create(:assignment)
    end

    it 'raises en error message on an empty row' do
      expect { FlexibleCriterion.create_or_update_from_csv_row([], @assignment) }
        .to raise_error(CSVInvalidLineError, 'Invalid Row Format')
    end

    it 'raises an error message on a 1 element row' do
      expect { FlexibleCriterion.create_or_update_from_csv_row(%w(name), @assignment) }
        .to raise_error(CSVInvalidLineError, 'Invalid Row Format')
    end

    it 'raises an error message on an invalid maximum value' do
      expect { FlexibleCriterion.create_or_update_from_csv_row(%w(name max_value), @assignment) }
        .to raise_error(CSVInvalidLineError)
    end
  end

  context 'for an assignment' do
    before :each do
      @assignment = create(:assignment)
    end

    context 'with criterion from a 2 element row with no description overwritten' do
      before :each do
        @criterion = FlexibleCriterion.create_or_update_from_csv_row(['name', 10.0], @assignment)
      end

      describe '.name' do
        it 'is equal to name' do
          expect(@criterion.name).to eq('name')
        end
      end

      describe '.max_mark' do
        it 'is equal to 10.0' do
          expect(@criterion.max_mark).to eq(10.0)
        end
      end

      describe '.assignment' do
        it 'is equal to current assignment' do
          expect(@criterion.assignment).to eq(@assignment)
        end
      end
    end

    context 'with criterion from a 3 elements row that includes a description overwritten' do
      before :each do
        @criterion = FlexibleCriterion.create_or_update_from_csv_row(['name', 10.0, 'description'], @assignment)
      end

      describe '.name' do
        it 'is equal to name' do
          expect(@criterion.name).to eq('name')
        end
      end

      describe '.max_mark' do
        it 'is equal to 10.0' do
          expect(@criterion.max_mark).to eq(10.0)
        end
      end

      describe '.assignment' do
        it 'is equal to current assignment' do
          expect(@criterion.assignment).to eq(@assignment)
        end
      end

      describe '.description' do
        it 'is equal to description' do
          expect(@criterion.description).to eq('description')
        end
      end
    end

    context 'with three flexible criteria allows criterion with same name to overwrite' do
      before :each do
        create(:flexible_criterion,
               assignment: @assignment,
               name: 'criterion1',
               description: 'description1, for criterion 1',
               max_mark: 10)
        create(:flexible_criterion,
               assignment: @assignment,
               name: 'criterion2',
               description: 'description2, "with quotes"',
               max_mark: 10,
               position: 2)
        create(:flexible_criterion,
               assignment: @assignment,
               name: 'criterion3',
               description: 'description3!',
               max_mark: 1.6,
               position: 3)
        @csv_base_row = ['criterion2', '10', 'description2, "with quotes"']

        @criterion = FlexibleCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
      end

      describe '.name' do
        it 'equals criterion 2' do
          expect(@criterion.name).to eq('criterion2')
        end
      end

      describe '.max_mark' do
        it 'equals 10' do
          expect(@criterion.max_mark).to eq(10)
        end
      end

      describe '.description' do
        it 'equals description2, "with quotes"' do
          expect(@criterion.description).to eq('description2, "with quotes"')
        end
      end

      describe '.position' do
        it 'equals 2' do
          expect(@criterion.position).to eq(2)
        end
      end
    end
  end
end
