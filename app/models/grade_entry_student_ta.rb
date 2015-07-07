# Join model that associates a grade entry student and a TA.
class GradeEntryStudentTa < ActiveRecord::Base
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
end
