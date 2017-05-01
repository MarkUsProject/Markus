require 'encoding'
require 'descriptive_statistics'

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

  # An array of all grade_entry_students' released percentage total grades that are not nil
  def released_percentage_grades_array
    grades = Array.new()
    grade_entry_students = self.grade_entry_students
                             .where(released_to_student: true)
    grade_entry_students.each do |grade_entry_student|
      if !grade_entry_student.total_grade.nil?
        grades.push(calculate_total_percent(grade_entry_student))
      end
    end

    return grades
  end

  # An array of all grade_entry_students' percentage total grades that are not nil
  def percentage_grades_array
    grades = Array.new()
    grade_entry_students.each do |grade_entry_student|
      if !grade_entry_student.total_grade.nil?
        grades.push(calculate_total_percent(grade_entry_student))
      end
    end

    return grades
  end

  def grade_distribution_array(intervals = 20)
    distribution = Array.new(intervals, 0)
    percentage_grades_array.each do |grade|
      distribution = update_distribution(distribution, grade, intervals)
    end
    distribution.to_json
  end

  # def update_distribution(distribution, result, out_of, intervals)
  def update_distribution(distribution, result, intervals)
    steps = 100 / intervals # number of percentage steps in each interval
    percentage = [100, result.ceil].min
    interval = (percentage / steps).floor
    if interval > 0
      interval -= (percentage % steps == 0) ? 1 : 0
    else
      interval = 0
    end
    distribution[interval] += 1
    distribution
  end

  # Determine the average of all of the students' marks that have been
  # released so far (return a percentage).
  def calculate_released_average
    percentage_grades = released_percentage_grades_array
    # byebug
    avg_mark = percentage_grades.mean
    return avg_mark
  end

  # Determine the median of all of the students' marks that have been
  # released so far (return a percentage).
  def calculate_released_median
    percentage_grades = released_percentage_grades_array
    med = percentage_grades.median
    return med
  end

  # Determine the number of grade_entry_forms that have been released
  def calculate_released_grade_entry_forms
    nums_released = released_percentage_grades_array.number.round

    return nums_released
  end

  # Determine the number of grade_entry_students that have submitted
  # the grade_entry_form
  def grade_entry_forms_submitted

    submitted = percentage_grades_array.number.round

    return submitted
  end

  # Determine the number of failed results
  def calculate_released_failed
    nums_failed = 0

    percentage_grades = released_percentage_grades_array
    percentage_grades.each do |percentage_grade|
      if percentage_grade < 50
        nums_failed += 1
      end
    end

    return nums_failed
  end

  # # Determine the number of zeros
  # def calculate_released_zeros
  #   nums_zeros = 0
  #
  #   percentage_grades = released_percentage_grades_array
  #   percentage_grades.each do |percentage_grade|
  #     if percentage_grade == 0
  #       nums_zeros += 1
  #     end
  #   end
  #
  #   return nums_zeros
  # end

  def calculate_released_zeros
    released_percentage_grades_array.count(&:zero?)
  end

  # Create grade_entry_student for each student in the course
  def create_all_grade_entry_students
    columns = [:user_id, :grade_entry_form_id, :released_to_student]

    values = Student.all.map do |student|
      # grade_entry_students.build(user_id: student.id, released_to_student: false)
      [student.id, id, false]
    end
    GradeEntryStudent.import columns, values, validate: false
  end
end
