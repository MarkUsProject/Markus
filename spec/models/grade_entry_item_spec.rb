describe GradeEntryItem do

  context 'checks relationships' do
    it { is_expected.to belong_to(:grade_entry_form) }
    it { is_expected.to have_many(:grades).dependent(:delete_all) }
    it { is_expected.to have_many(:grade_entry_students).through(:grades) }

    it { is_expected.to validate_presence_of(:name) }

    describe 'uniqueness validation' do
      subject { create :grade_entry_item }
      it { is_expected.to validate_uniqueness_of(:name).scoped_to(:grade_entry_form_id) }
    end

    it { is_expected.to validate_presence_of(:out_of) }
    it { is_expected.to validate_numericality_of(:out_of) }

    it { is_expected.to allow_value(0).for(:out_of) }
    it { is_expected.to allow_value(1).for(:out_of) }
    it { is_expected.to allow_value(2).for(:out_of) }
    it { is_expected.to allow_value(100).for(:out_of) }
    it { is_expected.not_to allow_value(-1).for(:out_of) }
    it { is_expected.not_to allow_value(-100).for(:out_of) }

    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_numericality_of(:position) }

    it { is_expected.to allow_value(0).for(:position) }
    it { is_expected.to allow_value(1).for(:position) }
    it { is_expected.to allow_value(2).for(:position) }
    it { is_expected.to allow_value(100).for(:position) }
    it { is_expected.not_to allow_value(-1).for(:position) }
    it { is_expected.not_to allow_value(-100).for(:position) }
  end

  # Make sure different grade entry forms can have grade entry items
  # with the same name
  it 'allows same column name for different grade entry forms' do
    grade_entry_form_1 = GradeEntryForm.create!(short_identifier: 'a', is_hidden: false)
    grade_entry_form_2 = GradeEntryForm.create!(short_identifier: 'b', is_hidden: false)
    column = grade_entry_form_1.grade_entry_items.create!(name: 'Q1', position: 1, out_of: 1)

    # Re-use the column name for a different grade entry form
    dup_column = GradeEntryItem.new
    dup_column.name = column.name
    dup_column.out_of = column.out_of
    dup_column.position = column.position
    dup_column.grade_entry_form = grade_entry_form_2

    expect(dup_column).to be_valid
  end
end
