describe GradeEntryItem do
  context 'checks relationships' do
    it { is_expected.to belong_to(:grade_entry_form) }
    it { is_expected.to have_many(:grades).dependent(:delete_all) }
    it { is_expected.to have_many(:grade_entry_students).through(:grades) }
    it { is_expected.to have_one(:course) }

    it { is_expected.to validate_presence_of(:name) }

    describe 'uniqueness validation' do
      subject { create :grade_entry_item }
      it { is_expected.to validate_uniqueness_of(:name).scoped_to(:assessment_id) }
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
    course = create :course
    grade_entry_form1 = GradeEntryForm.create!(short_identifier: 'a',
                                               due_date: 1.day.from_now,
                                               description: '1',
                                               message: '1',
                                               is_hidden: false,
                                               course: course)
    grade_entry_form2 = GradeEntryForm.create!(short_identifier: 'b',
                                               due_date: 1.day.from_now,
                                               description: '2',
                                               message: '2',
                                               is_hidden: false,
                                               course: course)
    column = grade_entry_form1.grade_entry_items.create!(name: 'Q1', position: 1, out_of: 1)

    # Re-use the column name for a different grade entry form
    dup_column = GradeEntryItem.new
    dup_column.name = column.name
    dup_column.out_of = column.out_of
    dup_column.position = column.position
    dup_column.grade_entry_form = grade_entry_form2

    expect(dup_column).to be_valid
  end

  describe '#grades_array' do
    let(:grade_entry_form) { create(:grade_entry_form_with_data) }
    let(:grade_entry_item) { create(:grade_entry_item, grade_entry_form: grade_entry_form) }
    let(:grades) { grade_entry_item.grades.pluck(:grade) }

    it 'returns the correct grades' do
      expect(grade_entry_item.grades_array).to match_array(grades)
    end

    it 'does not include marks for incomplete submissions' do
      grade_entry_item.grades.first.update(grade: nil)
      expect(grade_entry_item.grades_array).to match_array(grades[1..-1])
    end
  end

  describe '#average' do
    let(:grade_entry_item) { create(:grade_entry_item, max_mark: 10) }

    it 'returns 0 when there are no results' do
      allow(grade_entry_item).to receive(:grades_array).and_return([])
      expect(grade_entry_item.average).to eq 0
    end

    it 'returns the correct number when there are completed results' do
      allow(grade_entry_item).to receive(:grades_array).and_return([2, 3, 4, 1, 0])
      expect(grade_entry_item.average).to eq 2
    end

    it 'returns 0 when the assignment has a max_mark of 0' do
      grade_entry_item.update(max_mark: 0)
      allow(grade_entry_item).to receive(:grades_array).and_return([2, 3, 4, 1, 0])
      expect(grade_entry_item.average).to eq 0
    end
  end

  describe '#median' do
    let(:grade_entry_item) { create(:grade_entry_item, max_mark: 10) }

    it 'returns 0 when there are no results' do
      allow(grade_entry_item).to receive(:grades_array).and_return([])
      expect(grade_entry_item.median).to eq 0
    end

    it 'returns the correct number when there are completed results' do
      allow(grade_entry_item).to receive(:grades_array).and_return([2, 3, 4, 1, 0])
      expect(grade_entry_item.median).to eq 2
    end

    it 'returns 0 when the assignment has a max_mark of 0' do
      grade_entry_item.update(max_mark: 0)
      allow(grade_entry_item).to receive(:grades_array).and_return([2, 3, 4, 1, 0])
      expect(grade_entry_item.median).to eq 0
    end
  end

  describe '#standard_deviation' do
    let(:grade_entry_item) { create(:grade_entry_item, max_mark: 10) }

    it 'returns 0 when there are no results' do
      allow(grade_entry_item).to receive(:grades_array).and_return([])
      expect(grade_entry_item.standard_deviation).to eq 0
    end

    it 'returns the correct number when there are completed results' do
      allow(grade_entry_item).to receive(:grades_array).and_return([2, 3, 4, 1, 0])
      expect(grade_entry_item.standard_deviation.round(9)).to eq 1.414213562
    end

    it 'returns 0 when the assignment has a max_mark of 0' do
      grade_entry_item.update(max_mark: 0)
      allow(grade_entry_item).to receive(:grades_array).and_return([2, 3, 4, 1, 0])
      expect(grade_entry_item.standard_deviation).to eq 0
    end
  end
end
