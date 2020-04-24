# GradeEntryForm can represent a test, lab, exam, etc.
# A grade entry form has many columns which represent the questions and their total
# marks (i.e. GradeEntryItems) and many rows which represent students and their
# marks on each question (i.e. GradeEntryStudents).
class GradeEntryForm < Assessment
  has_many                  :grade_entry_items,
                            -> { order(:position) },
                            dependent: :destroy,
                            inverse_of: :grade_entry_form,
                            foreign_key: :assessment_id

  has_many                  :grade_entry_students,
                            dependent: :destroy,
                            inverse_of: :grade_entry_form,
                            foreign_key: :assessment_id

  has_many                  :grades, through: :grade_entry_items

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

    total_grades = Hash[
      grade_entry_students.where.not(total_grade: nil).pluck(:id, :total_grade)
    ]
    @ges_total_grades = total_grades
    total_grades
  end

  # An array of all active grade_entry_students' percentage total grades that are not nil
  def percentage_grades_array
    if defined? @grades_array
      return @grades_array
    end

    grades = Array.new
    out_of = out_of_total

    grade_entry_students.joins(:user).where('users.hidden': false).find_each do |grade_entry_student|
      ges_total_grade = grade_entry_student.total_grade
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

  # Returns the average of all active student marks.
  def calculate_average
    percentage_grades = percentage_grades_array
    percentage_grades.blank? ? 0 : DescriptiveStatistics.mean(percentage_grades)
  end

  # Returns the median of all active student marks.
  def calculate_median
    percentage_grades = percentage_grades_array
    percentage_grades.blank? ? 0 : DescriptiveStatistics.median(percentage_grades)
  end

  # Determine the number of active grade_entry_students that have been given a mark.
  def count_non_nil
    percentage_grades = percentage_grades_array
    percentage_grades.blank? ? 0 : percentage_grades.size
  end

  def calculate_failed
    percentage_grades = percentage_grades_array
    percentage_grades.blank? ? 0 : percentage_grades.count { |mark| mark < 50 }
  end

  def calculate_zeros
    percentage_grades = percentage_grades_array
    percentage_grades.blank? ? 0 : percentage_grades.count(&:zero?)
  end

  # Create grade_entry_student for each student in the course
  def create_all_grade_entry_students
    columns = [:user_id, :assessment_id, :released_to_student]

    values = Student.all.map do |student|
      # grade_entry_students.build(user_id: student.id, released_to_student: false)
      [student.id, id, false]
    end
    GradeEntryStudent.import columns, values, validate: false, on_duplicate_key_ignore: true
  end

  def export_as_csv
    students = Student.left_outer_joins(:grade_entry_students)
                      .where(hidden: false, 'grade_entry_students.assessment_id': self.id)
                      .order(:user_name)
                      .pluck(:user_name, 'grade_entry_students.total_grade')
    headers = []
    # The first row in the CSV file will contain the column names
    titles = [''] + self.grade_entry_items.pluck(:name)
    titles << GradeEntryForm.human_attribute_name(:total) if self.show_total
    headers << titles

    # The second row in the CSV file will contain the column totals
    totals = [GradeEntryItem.human_attribute_name(:out_of)] + self.grade_entry_items.pluck(:out_of)
    totals << self.out_of_total if self.show_total
    headers << totals

    grade_data = self.grades
                     .joins(:grade_entry_item, grade_entry_student: :user)
                     .pluck('users.user_name', 'grade_entry_items.position', :grade)
                     .group_by { |x| x[0] }
    num_items = self.grade_entry_items.count
    MarkusCsv.generate(students, headers) do |user_name, total_grade|
      row = [user_name]
      if grade_data.key? user_name
        student_grades = Array.new(num_items, '')
        grade_data[user_name].each do |g|
          grade_index = g[1] - 1
          student_grades[grade_index] = g[2].nil? ? '' : g[2]
        end
        row.concat(student_grades)
        row << (total_grade.nil? ? '' : total_grade) if self.show_total
      else
        row.concat(Array.new(num_items, ''))
        row << '' if self.show_total
      end
      row
    end
  end

  def from_csv(grades_data, overwrite)
    grade_entry_students = Hash[
      self.grade_entry_students.joins(:user).pluck('users.user_name', :id)
    ]
    all_grades = Set.new(
      self.grades.where.not(grade: nil).pluck(:grade_entry_student_id, :grade_entry_item_id)
    )

    names = []
    totals = []
    updated_columns = []
    updated_grades = []

    # Parse the grades
    result = MarkusCsv.parse(grades_data, header_count: 2) do |row|
      next unless row.any?
      # grab names and totals from the first two rows
      if names.empty?
        names = row.drop(1)
        next
      elsif totals.empty?
        totals = row.drop(1)
        if self.show_total && names.last == GradeEntryForm.human_attribute_name(:total)
          self.update_grade_entry_items(names[0...-1], totals[0...-1], overwrite)
        else
          self.update_grade_entry_items(names, totals, overwrite)
        end
        updated_columns = self.grade_entry_items.reload.pluck(:id)
        next
      end

      s_id = grade_entry_students[row[0]]
      raise CsvInvalidLineError if s_id.nil?

      row.drop(1).zip(updated_columns).take([row.size - 1, updated_columns.size].min).each do |grade, item_id|
        begin
          new_grade = grade.blank? ? nil : Float(grade)
        rescue ArgumentError
          raise CsvInvalidLineError
        end
        if overwrite || !all_grades.member?([s_id, item_id])
          updated_grades << {
            grade_entry_student_id: s_id,
            grade_entry_item_id: item_id,
            grade: new_grade
          }
        end
      end
    end
    Grade.import updated_grades,
                 on_duplicate_key_update: { conflict_target: [:grade_entry_item_id, :grade_entry_student_id],
                                            columns: [:grade] }
    GradeEntryStudent.refresh_total_grades(updated_grades.map { |h| h[:grade_entry_student_id] })
    result
  end

  def update_grade_entry_items(names, totals, overwrite)
    if names.size != totals.size || names.empty? || totals.empty?
      raise "Invalid header rows: '#{names}' and '#{totals}'."
    end

    updated_items = []
    names.size.times do |i|
      updated_items << {
        name: names[i],
        out_of: totals[i],
        position: i + 1,
        assessment_id: self.id
      }
    end

    # Delete old questions if we want to overwrite them
    missing_items = self.grade_entry_items.where.not(name: names)
    if overwrite
      missing_items.destroy_all
    else
      i = names.size
      missing_items.each do |item|
        updated_items << {
          name: item.name,
          out_of: item.out_of,
          position: i + 1,
          assessment_id: item.assessment_id
        }
        i += 1
      end
    end

    GradeEntryItem.import updated_items,
                          on_duplicate_key_update: { conflict_target: [:name, :assessment_id],
                                                     columns: [:out_of, :position] }
    self.grade_entry_items.reload
  end
end
