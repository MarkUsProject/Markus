require 'spec_helper'

describe FlexibleCriterion do
  let(:criterion_factory_name) { :flexible_criterion }

  CSV_STRING = "criterion1,10.0,\"description1, for criterion 1\"\ncriterion2,10.0,\"description2, \"\"with quotes\"\"\"\ncriterion3,1.6,description3!\n"
  UPLOAD_CSV_STRING = "criterion4,10.0,\"description4, \"\"with quotes\"\"\"\n"
  INVALID_CSV_STRING = "criterion3\n"

  context 'A good FlexibleCriterion model' do
    before :each do
      @criterion = create(:flexible_criterion)
    end

    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:max_mark) }

    it do
      is_expected.to validate_uniqueness_of(
                       :name).scoped_to(:assignment_id).with_message('Criterion name already used.')
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

    it 'raise en error message on an empty row' do
      expect { FlexibleCriterion.create_or_update_from_csv_row([], @assignment) }.
        to raise_error(CSVInvalidLineError, 'Invalid Row Format')
    end

    it 'raise an error message on a 1 element row' do
      expect { FlexibleCriterion.create_or_update_from_csv_row(%w(name), @assignment) }.
        to raise_error(CSVInvalidLineError, 'Invalid Row Format')
    end

    it 'raise an error message on an invalid maximum value' do
      expect { FlexibleCriterion.create_or_update_from_csv_row(%w(name max_value), @assignment) }.
        to raise_error(CSVInvalidLineError)
    end
  end

  context 'An assignment, of type flexible criteria' do
    before :each do
      @assignment = create(:assignment)
    end

    it 'overwrite criterion from a 2 element row with no description' do
      criterion = FlexibleCriterion.create_or_update_from_csv_row(['name', 10.0], @assignment)
      expect(criterion).not_to be_nil
      expect(criterion.name).to eq('name')
      expect(criterion.max_mark).to eq(10.0)
      expect(criterion.assignment).to eq(@assignment)
    end

    it 'overwrite criterion from a 3 elements row that includes a description' do
      criterion = FlexibleCriterion.create_or_update_from_csv_row(['name', 10.0, 'description'], @assignment)
      expect(criterion).not_to be_nil
      expect(criterion.name).to eq('name')
      expect(criterion.max_mark).to eq(10.0)
      expect(criterion.description).to eq('description')
      expect(criterion.assignment).to eq(@assignment)
    end

    context 'with three flexible criteria' do
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
      end

      it 'allow a criterion with the same name to overwrite' do
        expect {
          criterion = FlexibleCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
          expect(criterion.name).to eq('criterion2')
          expect(criterion.max_mark).to eq(10)
          expect(criterion.description).to eq('description2, "with quotes"')
          expect(criterion.position).to eq(2)
        }.not_to raise_error
      end
    end
  end
end

