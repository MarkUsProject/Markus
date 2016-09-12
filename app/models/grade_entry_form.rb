require 'encoding'

# GradeEntryForm can represent a test, lab, exam, etc.
# A grade entry form has many columns which represent the questions and their total
# marks (i.e. GradeEntryItems) and many rows which represent students and their
# marks on each question (i.e. GradeEntryStudents).
class GradeEntryForm < ActiveRecord::Base
  has_many                  :grade_entry_items,
                            -> { order(:position) },
                            dependent: :destroy

  has_many                  :grade_entry_students,
                            dependent: :destroy

  has_many                  :grades, through: :grade_entry_items

  # Call custom validator in order to validate the date attribute
  # date: true maps to DateValidator (custom_name: true maps to CustomNameValidator)
  # Look in lib/validators/* for more info
  validates                 :date, date: true

  validates_presence_of     :short_identifier
  validates_uniqueness_of   :short_identifier, case_sensitive: true

  validates                 :is_hidden, inclusion: { in: [true, false] }
  accepts_nested_attributes_for :grade_entry_items, allow_destroy: true

  after_create :create_all_grade_entry_students

  BLANK_MARK = ''

  # The total number of marks for this grade entry form
  def out_of_total
    total = 0
    grade_entry_items.each do |grade_entry_item|
      unless grade_entry_item.bonus
        total += grade_entry_item.out_of
      end
    end
    total
  end

  # Determine the total mark for a particular student, as a percentage
  def calculate_total_percent(grade_entry_student)
    unless grade_entry_student.nil?
      total = grade_entry_student.total_grade
    end

    percent = BLANK_MARK
    out_of = self.out_of_total

    # Check for NA mark or division by 0
    unless total.nil? || out_of == 0
      percent = (total / out_of) * 100
    end
    percent
  end

  # Determine the average of all of the students' marks that have been
  # released so far (return a percentage).
  def calculate_released_average
    total_marks  = 0
    num_released = 0

    grade_entry_students = self.grade_entry_students
                               .where(released_to_student: true)
    grade_entry_students.each do |grade_entry_student|
      total_mark = grade_entry_student.total_grade

      unless total_mark.nil?
        total_marks += total_mark
        num_released += 1
      end
    end

    # Watch out for division by 0
    return 0 if num_released.zero?
    ((total_marks / num_released) / out_of_total) * 100
  end

  # Create grade_entry_student for each student in the course
  def create_all_grade_entry_students
    new_students = Student.all.map do |student|
      grade_entry_students.build(user_id: student.id, released_to_student: false)
    end
    GradeEntryStudent.import new_students, validate: false
  end
end
