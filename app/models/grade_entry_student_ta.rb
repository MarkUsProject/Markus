# Join model that associates a grade entry student and a TA.
class GradeEntryStudentTa < ApplicationRecord
  self.table_name = 'grade_entry_students_tas'

  belongs_to :grade_entry_student
  belongs_to :ta

  has_one :course, through: :grade_entry_student

  validate :courses_should_match

  # Merges records of GradeEntryStudentTa that do not exist yet using a caller-
  # specified block. The block is given the passed-in grade entry student IDs
  # and TA IDs and must return a list of (grade entry student ID, TA ID) pair
  # that represents the associations.
  def self.merge_non_existing(grade_entry_student_ids, ta_ids)
    # Only use IDs that identify existing model instances.
    grade_entry_student_ids =
      GradeEntryStudent.where(id: Array(grade_entry_student_ids)).ids
    ta_ids = Ta.where(id: Array(ta_ids)).ids
    # Get all existing associations to avoid violating the unique constraint.
    existing_values = GradeEntryStudentTa
                      .where(grade_entry_student_id: grade_entry_student_ids, ta_id: ta_ids)
                      .pluck(:grade_entry_student_id, :ta_id)
    # Delegate the generation of records to the caller-specified block and
    # remove values that already exist in the database.
    values = yield(grade_entry_student_ids, ta_ids) - existing_values

    student_ta_hash = values.map do |value|
      {
        grade_entry_student_id: value[0],
        ta_id: value[1]
      }
    end
    unless student_ta_hash.empty?
      insert_all(student_ta_hash)
    end
  end

  def self.from_csv(grade_entry_form, csv_data, remove_existing)
    if remove_existing
      self.joins(:grade_entry_student)
          .where('grade_entry_students.assessment_id': grade_entry_form.id)
          .delete_all
    end

    new_mappings = []
    tas = grade_entry_form.course.tas.joins(:user).pluck('users.user_name', :id).to_h
    grade_entry_students = grade_entry_form.grade_entry_students.joins(:user).pluck('users.user_name',
                                                                                    :id).to_h

    result = MarkusCsv.parse(csv_data.read) do |row|
      raise CsvInvalidLineError if row.empty?
      grade_entry_student_id = grade_entry_students[row.first]
      raise CsvInvalidLineError if grade_entry_student_id.nil?
      row.drop(1).each do |ta_user_name|
        next if ta_user_name.blank?
        ta_id = tas[ta_user_name]
        raise CsvInvalidLineError if ta_id.nil?
        new_mappings << { grade_entry_student_id: grade_entry_student_id, ta_id: ta_id }
      end
    end
    if new_mappings.present?
      GradeEntryStudentTa.insert_all new_mappings, unique_by: %i[grade_entry_student_id ta_id]
    end
    result
  end
end
