describe CheckboxCriterion do
  let(:criterion_factory_name) { :checkbox_criterion }

  it_behaves_like 'a criterion'

  context 'validations work properly' do
    before(:each) do
      @criterion = create(:checkbox_criterion)
    end

    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:max_mark) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:assessment_id) }
    it { is_expected.to validate_numericality_of(:max_mark) }

    it { is_expected.to allow_value(0.1).for(:max_mark) }
    it { is_expected.to allow_value(1.0).for(:max_mark) }
    it { is_expected.to allow_value(100.0).for(:max_mark) }
    it { is_expected.not_to allow_value(0.0).for(:max_mark) }
    it { is_expected.not_to allow_value(-1.0).for(:max_mark) }
    it { is_expected.not_to allow_value(-100.0).for(:max_mark) }
    it { is_expected.to have_one(:course) }

    context 'when a result is released' do
      before(:each) do
        @marks = @criterion.marks
        results = []
        3.times do
          results << create(:complete_result, released_to_students: false)
        end
        @marks.create(mark: 0, result: results[0])
        @marks.create(mark: 1, result: results[1])
        @marks.create(mark: 1, result: results[2])
        results.each do |result|
          # have to release to students after or else cannot assign marks
          result.released_to_students = true
          result.save
        end
      end

      describe 'checkbox criteria can\'t be updated' do
        it 'not raise error' do
          expect(@criterion.update(max_mark: 10)).to be false
        end
      end
    end
  end

  context 'With non-existent criteria' do
    before :each do
      @assignment = create(:assignment)
    end

    it 'raises en error message on an empty row' do
      expect { CheckboxCriterion.create_or_update_from_csv_row([], @assignment) }
        .to raise_error(CsvInvalidLineError, I18n.t('upload_errors.invalid_csv_row_format'))
    end

    it 'raises an error message on a 1 element row' do
      expect { CheckboxCriterion.create_or_update_from_csv_row(%w[name], @assignment) }
        .to raise_error(CsvInvalidLineError, I18n.t('upload_errors.invalid_csv_row_format'))
    end

    it 'raises an error message on an invalid maximum value' do
      expect { CheckboxCriterion.create_or_update_from_csv_row(%w[name max_value], @assignment) }
        .to raise_error(CsvInvalidLineError)
    end

    it 'raises an error message on a max mark that is zero' do
      expect { CheckboxCriterion.create_or_update_from_csv_row(%w[name 0], @assignment) }
        .to raise_error(CsvInvalidLineError, I18n.t('upload_errors.invalid_csv_row_format'))
    end

    it 'raises an error message if the checkbox criterion fails to save' do
      allow_any_instance_of(CheckboxCriterion).to receive(:save).and_return(false)

      expect { CheckboxCriterion.create_or_update_from_csv_row(%w[name 2], @assignment) }
        .to raise_error(CsvInvalidLineError)
    end
  end

  context 'for an assignment' do
    before :each do
      @assignment = create(:assignment)
    end

    context 'with criterion from a 2 element row with no description overwritten' do
      before :each do
        @criterion = CheckboxCriterion.create_or_update_from_csv_row(['name', 10.0], @assignment)
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
        @criterion = CheckboxCriterion.create_or_update_from_csv_row(['name', 10.0, 'description'], @assignment)
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

    context 'with three checkbox criteria allows criterion with same name to overwrite' do
      before :each do
        create(:checkbox_criterion,
               assignment: @assignment,
               name: 'criterion1',
               description: 'description1, for criterion 1',
               max_mark: 10)
        create(:checkbox_criterion,
               assignment: @assignment,
               name: 'criterion2',
               description: 'description2, "with quotes"',
               max_mark: 10,
               position: 2)
        create(:checkbox_criterion,
               assignment: @assignment,
               name: 'criterion3',
               description: 'description3!',
               max_mark: 1.6,
               position: 3)
        @csv_base_row = ['criterion2', '10', 'description2, "with quotes"']

        @criterion = CheckboxCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
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
