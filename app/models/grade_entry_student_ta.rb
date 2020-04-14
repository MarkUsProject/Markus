# Join model that associates a grade entry student and a TA.
class GradeEntryStudentTa < ApplicationRecord
  self.table_name = 'grade_entry_students_tas'

  belongs_to :grade_entry_student
  belongs_to :ta

  # Merges records of GradeEntryStudentTa that do not exist yet using a caller-
  # specified block. The block is given the passed-in grade entry student IDs
  # and TA IDs and must return a list of (grade entry student ID, TA ID) pair
  # that represents the associations.
  def self.merge_non_existing(grade_entry_student_ids, ta_ids)
    # Only use IDs that identify existing model instances.
    grade_entry_student_ids =
      GradeEntryStudent.where(id: Array(grade_entry_student_ids)).pluck(:id)
    ta_ids = Ta.where(id: Array(ta_ids)).pluck(:id)

    # Create non-existing association between grade entry students and TAs.
    columns = [:grade_entry_student_id, :ta_id]
    # Get all existing associations to avoid violating the unique constraint.
    existing_values = GradeEntryStudentTa
      .where(grade_entry_student_id: grade_entry_student_ids, ta_id: ta_ids)
      .pluck(:grade_entry_student_id, :ta_id)
    # Delegate the generation of records to the caller-specified block and
    # remove values that already exist in the database.
    values = yield(grade_entry_student_ids, ta_ids) - existing_values
    # TODO replace import with create when the PG driver supports bulk create,
    # then remove the activerecord-import gem.
    import(columns, values, validate: false)
  end

  def self.from_csv(grade_entry_form, csv_data, remove_existing)
    if remove_existing
      self.joins(:grade_entry_student)
          .where('grade_entry_students.assessment_id': grade_entry_form.id)
          .delete_all
    end

    new_mappings = []
    tas = Hash[Ta.pluck(:user_name, :id)]
    grade_entry_students = Hash[
      grade_entry_form.grade_entry_students.joins(:user).pluck('users.user_name', :id)
    ]

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
    GradeEntryStudentTa.import new_mappings, validate: false, on_duplicate_key_ignore: true
    result
  end
end
