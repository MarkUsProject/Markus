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

  # Tests for out_of_total
  context 'A grade entry form object: ' do
    before(:each) do
      @grade_entry_form = make_grade_entry_form_with_multiple_grade_entry_items
    end

    it 'verify that the total number of marks is calculated correctly' do
      expect(@grade_entry_form.out_of_total).to eq (30)
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

  # Tests for calculate_average
  describe '#calculate_average' do
    before(:each) do
      @grade_entry_form = make_grade_entry_form_with_multiple_grade_entry_items
      @grade_entry_items = @grade_entry_form.grade_entry_items
      # Set up 6 GradeEntryStudents
      (0..5).each do |i|
        student = create(:student)
        grade_entry_student = @grade_entry_form.grade_entry_students.find_by(user: student)
        # Give the student a grade for all three questions for the grade entry form
        (0..2).each do |j|
          grade_entry_student.grades.create(grade_entry_item: @grade_entry_items[j],
                                            grade: 5 + i + j)
        end
        # The marks will be released for 3 out of the 6 students
        if i <= 2
          grade_entry_student.released_to_student = true
        else
          grade_entry_student.released_to_student = false
        end
        grade_entry_student.save
        # The last student is inactive.
        if i == 5
          student.update(hidden: true)
        end
      end
    end

    it 'verify the correct value is returned when multiple marks have been released and there are no blank marks' do
      expect(@grade_entry_form.calculate_average).to eq 80.00
    end

    it 'verify the correct value is returned when the student has grades for none of the questions' do
      # Blank marks for students
      (0..2).each do
        student = create(:student)
        @grade_entry_form.grade_entry_students.find_by(user: student).update(released_to_student: true)
      end
      expect(@grade_entry_form.calculate_average).to eq 80.00
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
