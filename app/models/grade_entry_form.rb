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

  # Get a CSV report of the grades for this grade entry form
  def get_csv_grades_report
    students = Student.where(hidden: false).order(:user_name)
    CSV.generate do |csv|

      # The first row in the CSV file will contain the question names
      final_result = []
      final_result.push('')
      grade_entry_items.each do |grade_entry_item|
        final_result.push(grade_entry_item.name)
      end
      csv << final_result

      # The second row in the CSV file will contain the question totals
      final_result = []
      final_result.push('')
      grade_entry_items.each do |grade_entry_item|
        final_result.push(grade_entry_item.out_of)
      end
      csv << final_result

      # The rest of the rows in the CSV file will contain the students' grades
      students.each do |student|
        final_result = []
        final_result.push(student.user_name)
        grade_entry_student = self.grade_entry_students
                                  .where(user_id: student.id)
                                  .first

        # Check whether or not we have grades recorded for this student
        if grade_entry_student.nil?
          self.grade_entry_items.each do |grade_entry_item|
            # Blank marks for each question
            final_result.push(BLANK_MARK)
          end
          # Blank total percent
          final_result.push(BLANK_MARK)
        else
          self.grade_entry_items.each do |grade_entry_item|
            grade = grade_entry_student
                      .grades
                      .where(grade_entry_item_id: grade_entry_item.id)
                      .first
            if grade.nil?
              final_result.push(BLANK_MARK)
            else
              final_result.push(grade.grade || BLANK_MARK)
            end
          end
          total_percent = self.calculate_total_percent(grade_entry_student)
          final_result.push(total_percent)
        end
        csv << final_result
      end
    end
  end

  # Parse a grade entry form CSV file.
  # grades_file is the CSV file to be parsed
  # grade_entry_form is the grade entry form that is being updated
  # invalid_lines will store all problematic lines from the CSV file
  def self.parse_csv(grades_file, grade_entry_form, invalid_lines, encoding,
                     overwrite)
    num_updates = 0
    num_lines_read = 0
    names = []
    totals = []
    grades_file = StringIO.new(grades_file.read.utf8_encode(encoding))

    # Parse the question names
    CSV.parse(grades_file.readline) do |row|
      unless CSV.generate_line(row).strip.empty?
        names = row
        num_lines_read += 1
      end
    end

    # Parse the question totals
    CSV.parse(grades_file.readline) do |row|
      unless CSV.generate_line(row).strip.empty?
        totals = row
        num_lines_read += 1
      end
    end

    # Create/update the grade entry items
    begin
      GradeEntryItem.create_or_update_from_csv_rows(names, totals, grade_entry_form)
      num_updates += 1
    rescue RuntimeError => e
      invalid_lines << names.join(',')
      error = e.message.is_a?(String) ? e.message : ''
      invalid_lines << totals.join(',') + ': ' + error unless invalid_lines.nil?
    end

    # Parse the grades
    CSV.parse(grades_file.read) do |row|
      next if CSV.generate_line(row).strip.empty?
      begin
        if num_lines_read > 1
          GradeEntryStudent.create_or_update_from_csv_row(row,
                                                          grade_entry_form,
                                                          grade_entry_form.grade_entry_items,
                                                          names, overwrite)
          num_updates += 1
        end
        num_lines_read += 1
      rescue RuntimeError => e
        error = e.message.is_a?(String) ? e.message : ''
        invalid_lines << row.join(',') + ': ' + error unless invalid_lines.nil?
      end
    end
    return num_updates
  end

end
