describe GradeEntryForm do

  # Basic validation tests
  it { is_expected.to have_many(:grade_entry_items) }
  it { is_expected.to have_many(:grade_entry_students) }
  it { is_expected.to have_many(:grades) }
  it { is_expected.to validate_presence_of(:short_identifier) }

  # Dates in the past should also be allowed
  it { is_expected.to allow_value(1.day.ago).for(:due_date) }
  it { is_expected.to allow_value(1.day.from_now).for(:due_date) }
  # it { is_expected.not_to allow_value('100-10').for(:due_date) }
  it { is_expected.not_to allow_value('2009-').for(:due_date) }
  it { is_expected.not_to allow_value('abcd').for(:due_date) }

  describe 'uniqueness validation' do
    subject { create :grade_entry_form }
    it { is_expected.to validate_uniqueness_of(:short_identifier) }
  end

  describe '#max_mark' do
    before(:each) do
      @grade_entry_form = make_grade_entry_form_with_multiple_grade_entry_items
    end

    it 'calculates the sum of the grade_entry_item out_of values' do
      expect(@grade_entry_form.max_mark).to eq 30
    end

    it 'ignores grade_entry_items that are marked as bonus' do
      @grade_entry_form.grade_entry_items.update_all(bonus: true)
      expect(@grade_entry_form.max_mark).to eq 0
    end
  end

  # Tests for calculate_total_mark
  context 'Calculate the total mark for a student: ' do
    before(:each) do
      @grade_entry_form = make_grade_entry_form_with_multiple_grade_entry_items
      @grade_entry_items = @grade_entry_form.grade_entry_items
    end

    it 'verify the correct value is returned when the student has grades for some of the questions' do
      student = create(:student)
      grade_entry_student_with_some_grades = @grade_entry_form.grade_entry_students.find_by(user: student)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[0], grade: 0.4)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[1], grade: 0.3)
      grade_entry_student_with_some_grades.save
      expect(grade_entry_student_with_some_grades.total_grade).to eq 0.7
    end

    it 'when the student has grades for all of the questions' do
      student = create(:student)
      grade_entry_student_with_some_grades = @grade_entry_form.grade_entry_students.find_by(user: student)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[0], grade: 0.4)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[1], grade: 0.3)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[2], grade: 60.5)
      grade_entry_student_with_some_grades.save
      expect(grade_entry_student_with_some_grades.total_grade).to eq 61.2
    end

    it 'verify the correct value is returned when the student has grades for none of the questions' do
      student1 = create(:student)
      grade_entry_student_with_no_grades = @grade_entry_form.grade_entry_students.find_by(user: student1)
      expect(grade_entry_student_with_no_grades.total_grade).to be_nil
    end

    it 'verify the correct value is returned when the student has zero for all of the questions' do
      student1 = create(:student)
      grade_entry_student_with_all_zeros = @grade_entry_form.grade_entry_students.find_by(user: student1)
      @grade_entry_items.each do |grade_entry_item|
        grade_entry_student_with_all_zeros.grades.create(grade_entry_item: grade_entry_item, grade: 0.0)
      end
      grade_entry_student_with_all_zeros.save
      expect(grade_entry_student_with_all_zeros.total_grade).to eq 0.0
    end
  end

  # Tests for calculate_total_percent
  context 'Calculate the total percent for a student: ' do
    before(:each) do
      @grade_entry_form = make_grade_entry_form_with_multiple_grade_entry_items
      @grade_entry_items = @grade_entry_form.grade_entry_items
    end

    it 'verify the correct percentage is returned when the student has grades for some of the questions' do
      student = create(:student)
      grade_entry_student_with_some_grades = @grade_entry_form.grade_entry_students.find_by(user: student)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[0], grade: 3)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[1], grade: 7)
      grade_entry_student_with_some_grades.save
      expect(@grade_entry_form.calculate_total_percent(grade_entry_student_with_some_grades).round(2)).to eq 33.33
    end

    it 'verify the correct percentage is returned when the student has grades for all of the questions' do
      student = create(:student)
      grade_entry_student_with_some_grades = @grade_entry_form.grade_entry_students.find_by(user: student)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[0], grade: 3)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[1], grade: 7)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[2], grade: 8)
      grade_entry_student_with_some_grades.save
      expect(@grade_entry_form.calculate_total_percent(grade_entry_student_with_some_grades)).to eq 60.00
    end

    it 'verify the correct percentage is returned when the student has grades for none of the questions' do
      student1 = create(:student)
      grade_entry_student_with_no_grades = @grade_entry_form.grade_entry_students.find_by(user: student1)
      grade_entry_student_with_no_grades.save
      expect(@grade_entry_form.calculate_total_percent(grade_entry_student_with_no_grades)).to eq ''
    end

    it 'verify the correct percentage is returned when the student has zero for all of the questions' do
      student1 = create(:student)
      grade_entry_student_with_all_zeros = @grade_entry_form.grade_entry_students.find_by(user: student1)
      @grade_entry_items.each do |grade_entry_item|
        grade_entry_student_with_all_zeros.grades.create(grade_entry_item: grade_entry_item, grade: 0.0)
      end
      grade_entry_student_with_all_zeros.save
      expect(@grade_entry_form.calculate_total_percent(grade_entry_student_with_all_zeros)).to eq 0.0
    end
  end

  # Tests for all_blank_grades
  context "Determine whether or not a student's grades are all blank: " do
    before(:each) do
      @grade_entry_form = make_grade_entry_form_with_multiple_grade_entry_items
      @grade_entry_items = @grade_entry_form.grade_entry_items
    end

    it 'verify the correct value is returned when the student has grades for some of the questions' do
      student = create(:student)
      grade_entry_student_with_some_grades = @grade_entry_form.grade_entry_students.find_by(user: student)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[0], grade: 3)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[1], grade: 7)
      expect(grade_entry_student_with_some_grades.all_blank_grades?).to be false
    end

    it 'verify the correct value is returned when the student has grades for all of the questions' do
      student = create(:student)
      grade_entry_student_with_some_grades = @grade_entry_form.grade_entry_students.find_by(user: student)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[0], grade: 3)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[1], grade: 7)
      grade_entry_student_with_some_grades.grades.create(grade_entry_item: @grade_entry_items[2], grade: 8)
      expect(grade_entry_student_with_some_grades.all_blank_grades?).to be false
    end

    it 'verify the correct value is returned when the student has grades for none of the questions' do
      student = create(:student)
      grade_entry_student_with_no_grades = @grade_entry_form.grade_entry_students.find_by(user: student)
      expect(grade_entry_student_with_no_grades.all_blank_grades?).to be true
    end
  end

  describe '#upcoming' do
    it 'returns true if a grade entry form is due after the current time' do
      gef = create(:grade_entry_form, due_date: Time.current + (60 * 60 * 24))
      expect(gef.upcoming(create(:student))).to be true
    end

    it 'returns false if a grade entry form was due before the current time' do
      gef = create(:grade_entry_form, due_date: Time.current - (60 * 60 * 24))
      expect(gef.upcoming(create(:student))).to be false
    end

    it 'returns true if a grade entry form has a nil due date' do
      gef = create(:grade_entry_form, due_date: nil)
      expect(gef.upcoming(create(:student))).to be true
    end
  end

  describe '#results_average' do
    let(:form) { create(:grade_entry_form) }
    let(:grade_entry_items) { create_list(:grade_entry_item, 10, grade_entry_form: form) }
    let!(:students) { create_list :student, 6 }

    before do
      form.grade_entry_students.order(:id).each_with_index do |ges, ind|
        grade_entry_items.each_with_index.map do |gei|
          ges.grades.find_or_create_by(grade_entry_item: gei).update(grade: grades[ind])
        end
        ges.save
      end
    end

    describe 'when no grades are nil and all grades are equal' do
      let(:grades) { [1, 1, 1, 1, 1, 1] }
      it 'calculates the correct average' do
        expect(form.results_average).to eq(10 * 100 / form.max_mark)
      end
    end

    describe 'when students have different total grades' do
      let(:grades) { [1, 1, 2, 3, 5, 9] }
      it 'calculates the correct average' do
        expect(form.results_average).to eq(35 * 100 / form.max_mark)
      end

      describe 'when some students are inactive' do
        it 'calculates the correct average (excluding all inactive students)' do
          form.grade_entry_students.order(:id).limit(3).each { |ges| ges.user.update!(hidden: true) }
          average_total_grade = ((3 + 5 + 9) / 3.0 * 10)
          expect(form.results_average).to eq((average_total_grade * 100 / form.max_mark).round(2))
        end
      end

      describe 'when some marks are released' do
        it 'calculates the correct average (including both released and unreleased marks)' do
          form.grade_entry_students.order(:id).limit(3).each { |ges| ges.update!(released_to_student: true) }
          expect(form.results_average).to eq(35 * 100 / form.max_mark)
        end
      end
    end

    describe 'when all grades are nil' do
      let(:grades) { [nil, nil, nil, nil, nil, nil] }
      it 'calculates the correct average' do
        expect(form.results_average).to eq 0
      end
    end

    describe 'when some grades are nil' do
      let(:grades) { [nil, 1, nil, 2, nil, 6] }
      it 'calculates the correct average (ignores nil grades)' do
        expect(form.results_average).to eq(30 * 100 / form.max_mark)
      end
    end
  end

  describe '#results_median' do
    let(:form) { create(:grade_entry_form) }
    let(:grade_entry_items) { create_list(:grade_entry_item, 10, grade_entry_form: form) }
    let!(:students) { create_list :student, 6 }

    before do
      form.grade_entry_students.each_with_index do |ges, ind|
        grade_entry_items.each_with_index.map do |gei|
          ges.grades.find_or_create_by(grade_entry_item: gei).update(grade: grades[ind])
        end
        ges.save
      end
    end

    describe 'when no grades are nil and all grades are equal' do
      let(:grades) { [1, 1, 1, 1, 1, 1] }
      it 'calculates the correct median' do
        expect(form.results_median).to eq(10 * 100 / form.max_mark)
      end
    end

    describe 'when students have different total grades' do
      let(:grades) { [1, 1, 2, 3, 5, 9] }
      it 'calculates the correct median' do
        expect(form.results_median).to eq(25 * 100 / form.max_mark)
      end

      describe 'when some students are inactive' do
        it 'calculates the correct median (excluding all inactive students)' do
          form.grade_entry_students.order(:id).limit(3).each { |ges| ges.user.update!(hidden: true) }
          median_total_grade = 5 * 10
          expect(form.results_median).to eq(median_total_grade * 100 / form.max_mark)
        end
      end

      describe 'when some marks are released' do
        it 'calculates the correct median (including both released and unreleased marks)' do
          form.grade_entry_students.order(:id).limit(3).each { |ges| ges.update!(released_to_student: true) }
          expect(form.results_median).to eq(25 * 100 / form.max_mark)
        end
      end
    end

    describe 'when all grades are nil' do
      let(:grades) { [nil, nil, nil, nil, nil, nil] }
      it 'calculates the correct median' do
        expect(form.results_median).to eq 0
      end
    end

    describe 'when some grades are nil' do
      let(:grades) { [nil, 1, nil, 2, nil, 6] }
      it 'calculates the correct median (ignores nil grades)' do
        expect(form.results_median).to eq(20 * 100 / form.max_mark)
      end
    end
  end

  def make_grade_entry_form_with_multiple_grade_entry_items
    grade_entry_form = GradeEntryForm.create(short_identifier: 'T1',
                                             description: 'Test 1',
                                             message: 'Test 1',
                                             due_date: 1.day.ago,
                                             is_hidden: false)
    grade_entry_items = []
    (1..3).each do |i|
      grade_entry_items << GradeEntryItem.create(grade_entry_form: @grade_entry_form,
                                                 out_of: 10,
                                                 name: 'Q' + i.to_s,
                                                 position: i)
    end
    grade_entry_form.grade_entry_items = grade_entry_items
    return grade_entry_form
  end
end
