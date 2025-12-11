# GradeEntryForm can represent a test, lab, exam, etc.
# A grade entry form has many columns which represent the questions and their total
# marks (i.e. GradeEntryItems) and many rows which represent students and their
# marks on each question (i.e. GradeEntryStudents).
class GradeEntryForm < Assessment
  has_many :grade_entry_items,
           -> { order(:position) },
           dependent: :destroy,
           inverse_of: :grade_entry_form,
           foreign_key: :assessment_id

  has_many :grade_entry_students,
           dependent: :destroy,
           inverse_of: :grade_entry_form,
           foreign_key: :assessment_id

  has_many :grades, through: :grade_entry_items

  accepts_nested_attributes_for :grade_entry_items, allow_destroy: true

  after_create :create_all_grade_entry_students

  before_destroy -> { throw(:abort) if self.grades.where.not(grade: nil).exists? }, prepend: true

  # Set the default order of spreadsheets: in ascending order of id
  default_scope { order(:id) }

  # Constants
  BLANK_MARK = ''.freeze

  # The total number of marks for this grade entry form
  def max_mark
    self.grade_entry_items.where(bonus: false).sum(:out_of)
  end

  # Returns a list of total marks for each grade entry student for this grade entry form.
  # There is one mark per student. Does NOT include:
  #   - students with no marks
  #   - inactive students
  # Currently results are represented as GradeEntryStudents, but in the future we plan to unify
  # the representations of Assignments and GradeEntryForms.
  def completed_result_marks
    return @completed_result_marks if defined? @completed_result_marks

    ges_ids = self.grade_entry_students
                  .joins(:role)
                  .where(roles: { hidden: false })
                  .pluck('grade_entry_students.id')

    @completed_result_marks = GradeEntryStudent.get_total_grades(ges_ids).values.compact
    @completed_result_marks.sort!
  end

  def released_marks
    self.grade_entry_students.joins(role: :user)
        .where(roles: { hidden: false })
        .where(released_to_student: true)
  end

  # Determine the total mark for a particular student, as a percentage
  def calculate_total_percent(grade_entry_student)
    out_of = self.max_mark

    # Check for NA mark f or division by 0
    ges_total_grade = grade_entry_student&.get_total_grade
    unless ges_total_grade.nil? || out_of == 0
      return (ges_total_grade / out_of) * 100
    end

    BLANK_MARK
  end

  # Determine the number of active grade_entry_students that have been given a mark.
  def count_non_nil
    completed_result_marks.size
  end

  # Create grade_entry_student for each student in the course
  def create_all_grade_entry_students
    new_data = course.students.map do |student|
      { role_id: student.id, assessment_id: id, released_to_student: false }
    end
    GradeEntryStudent.insert_all(new_data, returning: false) unless new_data.empty?
  end

  def export_as_csv(role)
    if role.instructor?
      students = Student.left_outer_joins(:grade_entry_students, :user, :section)
                        .where(hidden: false, 'grade_entry_students.assessment_id': self.id)
                        .order(:user_name)
                        .pluck_to_hash(:user_name, :last_name, :first_name, 'name as section_name',
                                       :id_number, :email, 'grade_entry_students.id')
    elsif role.ta?

      students = role.grade_entry_students
                     .joins(:user)
                     .joins('LEFT OUTER JOIN sections ON sections.id = roles.section_id')
                     .where(grade_entry_form: self, 'roles.hidden': false,
                            'grade_entry_students.assessment_id': self.id)
                     .order(:user_name)
                     .pluck_to_hash(:user_name, :last_name, :first_name, 'name as section_name',
                                    :id_number, :email, 'grade_entry_students.id')

    end
    headers = []
    titles = Student::CSV_ORDER.map { |field| GradeEntryForm.human_attribute_name(field) } +
      self.grade_entry_items.pluck(:name)

    titles << GradeEntryForm.human_attribute_name(:total) if self.show_total
    headers << titles

    # The second row in the CSV file will contain the column totals
    totals = [''] * (Student::CSV_ORDER.length - 1) +
      [GradeEntryItem.human_attribute_name(:out_of)] + self.grade_entry_items.pluck(:out_of)
    totals << self.max_mark if self.show_total
    headers << totals

    if role.instructor?
      grade_data = self.grades
                       .joins(:grade_entry_item, grade_entry_student: :user)
                       .pluck('users.user_name', 'grade_entry_items.position', :grade)
                       .group_by { |x| x[0] }
      num_items = self.grade_entry_items.count
    elsif role.ta?
      grade_data = self.grades
                       .joins(:grade_entry_item, grade_entry_student: :user)
                       .joins(grade_entry_student: :grade_entry_student_tas)
                       .where('grade_entry_student_tas.ta_id': role.id)
                       .pluck('users.user_name', 'grade_entry_items.position', 'grades.grade')
                       .group_by { |x| x[0] }
      num_items = self.grade_entry_items.count
    end

    total_grades = GradeEntryStudent.get_total_grades(students.pluck('grade_entry_students.id'))

    MarkusCsv.generate(students, headers) do |student|
      total_grade = total_grades[student['grade_entry_students.id']]
      row = Student::CSV_ORDER.map { |field| student[field] }
      if grade_data.key? student[:user_name]
        student_grades = Array.new(num_items, '')
        grade_data[student[:user_name]].each do |g|
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
    grade_entry_students = self.grade_entry_students.joins(:user).pluck('users.user_name', :id).to_h
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
        names = row
        next
      elsif totals.empty?
        totals = row.map { |cell| Float(cell, exception: false)&.>=(0) ? cell : nil }
        totals[-1] = nil if self.show_total && names.last == GradeEntryForm.human_attribute_name(:total)
        names = names.reject.with_index { |_cell, i| totals[i].nil? }
        self.update_grade_entry_items(names, totals.compact, overwrite)
        updated_columns = self.grade_entry_items.reload.pluck(:name, :id).to_h
        next
      else
        s_id = grade_entry_students[row[0]]
        raise CsvInvalidLineError if s_id.nil?
        row = row.reject.with_index { |_cell, i| totals[i].nil? }
      end
      row.each_with_index do |grade, i|
        item_id = updated_columns[names[i]]
        begin
          new_grade = Float(grade, exception: false)
          new_grade = new_grade&.>=(0) ? Float(grade) : nil
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
    unless updated_grades.empty?
      Grade.upsert_all(updated_grades, unique_by: [:grade_entry_item_id, :grade_entry_student_id])
    end
    result
  end

  def update_grade_entry_items(names, totals, overwrite)
    if names.size != totals.size || names.empty? || totals.empty?
      raise CsvInvalidLineError, "Invalid header rows: '#{names}' and '#{totals}'."
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
    GradeEntryItem.upsert_all(updated_items, unique_by: [:assessment_id, :name])
    self.grade_entry_items.reload
  end

  def display_median_to_students
    false
  end
end
