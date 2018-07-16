# GradeEntryForm can represent a test, lab, exam, etc.
# A grade entry form has many columns which represent the questions and their total
# marks (i.e. GradeEntryItems) and many rows which represent students and their
# marks on each question (i.e. GradeEntryStudents).
class GradeEntryForm < ApplicationRecord
  has_many                  :grade_entry_items,
                            -> { order(:position) },
                            dependent: :destroy,
                            inverse_of: :grade_entry_form

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

  # Set the default order of spreadsheets: in ascending order of id
  default_scope { order('id ASC') }

  # Constants
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
      total_grades = grade_entry_student_total_grades
      ges_total_grade = total_grades[grade_entry_student.id]
    end

    percent = BLANK_MARK
    out_of = self.out_of_total

    # Check for NA mark f or division by 0
    unless ges_total_grade.nil? || out_of == 0
        percent = (ges_total_grade / out_of) * 100
    end

    percent
  end

  # Return a hash of each grade_entry_student's total_grade
  def grade_entry_student_total_grades
    if defined? @ges_total_grades
      return @ges_total_grades
    end

    total_grades = grade_entry_students.joins(:grades).group(:grade_entry_student_id).sum(:grade)
    @ges_total_grades = total_grades
    total_grades
  end


  # An array of all grade_entry_students' released percentage total grades that are not nil
  def released_percentage_grades_array
    if defined? @released_grades_array
      return @released_grades_array
    end

    total_grades = grade_entry_student_total_grades
    grades = Array.new
    out_of = out_of_total

    grade_entry_students.where(released_to_student: true).find_each do |grade_entry_student|
      ges_total_grade = total_grades[grade_entry_student.id]
      if !ges_total_grade.nil? && out_of != 0
        grades.push((ges_total_grade / out_of) * 100 )
      end
    end

    @released_grades_array = grades

    grades
  end

  # An array of all grade_entry_students' percentage total grades that are not nil
  def percentage_grades_array
    if defined? @grades_array
      return @grades_array
    end

    total_grades = grade_entry_student_total_grades
    grades = Array.new
    out_of = out_of_total

    grade_entry_students.find_each do |grade_entry_student|
      ges_total_grade = total_grades[grade_entry_student.id]
      if !ges_total_grade.nil? && out_of != 0
        grades.push((ges_total_grade / out_of) * 100 )
      end
    end

    @grades_array = grades

    grades
  end

  # Returns grade distribution for a grade entry form for all students
  def grade_distribution_array(intervals = 20)
    data = percentage_grades_array
    data.extend(Histogram)
    histogram = data.histogram(intervals, :min => 1, :max => 100, :bin_boundary => :min, :bin_width => 100 / intervals)
    distribution = histogram.fetch(1)
    distribution[0] = distribution.first + data.count{ |x| x < 1 }
    distribution[-1] = distribution.last + data.count{ |x| x > 100 }

    return distribution
  end

  # Determine the average of all of the students' marks that have been
  # released so far (return a percentage).
  def calculate_released_average
    percentage_grades = released_percentage_grades_array
    percentage_grades.blank? ? 0 : DescriptiveStatistics.mean(percentage_grades)
  end

  # Determine the median of all of the students' marks that have been
  # released so far (return a percentage).
  def calculate_released_median
    percentage_grades = released_percentage_grades_array
    percentage_grades.blank? ? 0 : DescriptiveStatistics.median(percentage_grades)
  end

  # Determine the number of grade_entry_students that have submitted
  # the grade_entry_form
  def grade_entry_forms_submitted
    percentage_grades = percentage_grades_array
    percentage_grades.blank? ? 0 : percentage_grades.size
  end

  def calculate_released_failed
    percentage_grades = released_percentage_grades_array
    percentage_grades.blank? ? 0 : percentage_grades.count { |mark| mark < 50 }
  end

  def calculate_released_zeros
    percentage_grades = released_percentage_grades_array
    percentage_grades.blank? ? 0 : percentage_grades.count(&:zero?)
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

  def export_as_csv
    students = Student.where(hidden: false).order(:user_name)
    csv_rows = []
    # prepare first two csv rows
    # The first row in the CSV file will contain the question names
    row = ['']
    self.grade_entry_items.each do |grade_entry_item|
      row.push(grade_entry_item.name)
    end
    if self.show_total
      row.push(GradeEntryForm.human_attribute_name(:total))
    end
    csv_rows.push(row)
    # The second row in the CSV file will contain the question totals
    row = [GradeEntryItem.human_attribute_name(:out_of)]
    self.grade_entry_items.each do |grade_entry_item|
      row.push(grade_entry_item.out_of)
    end
    if self.show_total
      row.concat([self.out_of_total])
    end
    csv_rows.push(row)
    # The rest of the rows in the CSV file will contain the students' grades
    MarkusCSV.generate(students, csv_rows) do |student|
      row = []
      row.push(student.user_name)
      grade_entry_student = self.grade_entry_students.where(user_id: student.id).first
      # Check whether or not we have grades recorded for this student
      if grade_entry_student.nil?
        self.grade_entry_items.each do |grade_entry_item|
          # Blank marks for each question
          row.push('')
        end
        # Blank total percent
        row.push('')
      else
        self.grade_entry_items.each do |grade_entry_item|
          grade = grade_entry_student
                    .grades
                    .where(grade_entry_item_id: grade_entry_item.id)
                    .first
          if grade.nil?
            row.push('')
          else
            row.push(grade.grade || '')
          end
        end
        if self.show_total
          total_grades = grade_entry_student_total_grades
          ges_total_grade = total_grades[grade_entry_student.id]
          row.push(ges_total_grade)
        end
      end
      row
    end
  end

end
