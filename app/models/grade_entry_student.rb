# GradeEntryStudent represents a row (i.e. a student's grades for each question)
# in a grade entry form.
class GradeEntryStudent < ApplicationRecord
  belongs_to :role
  validates_associated :role, on: :create

  belongs_to :grade_entry_form, foreign_key: :assessment_id, inverse_of: :grade_entry_students
  validates_associated :grade_entry_form, on: :create

  validates :role_id, uniqueness: { scope: :assessment_id }

  has_one :course, through: :grade_entry_form

  has_many :grades, dependent: :destroy

  has_many :grade_entry_items, through: :grades

  has_many :grade_entry_student_tas
  has_many :tas, through: :grade_entry_student_tas

  has_one :user, through: :role

  validates :released_to_student, inclusion: { in: [true, false] }

  validate :courses_should_match

  before_destroy -> { throw(:abort) if self.grades.where.not(grade: nil).exists? }, prepend: true

  # Merges records of GradeEntryStudent that do not exist yet using a caller-
  # specified block. The block is given the passed-in student IDs and grade
  # entry form IDs and must return a list of (student ID, grade entry form IDs)
  # pair that represents the grade entry students.
  def self.merge_non_existing(student_ids, form_ids)
    # Only use IDs that identify existing model instances.
    student_ids = Student.where(id: Array(student_ids)).ids
    form_ids = GradeEntryForm.where(id: Array(form_ids)).ids

    existing_values = GradeEntryStudent.where(role_id: student_ids, assessment_id: form_ids)
                                       .pluck(:role_id, :assessment_id)
    # Delegate the generation of records to the caller-specified block and
    # remove values that already exist in the database.
    values = yield(student_ids, form_ids) - existing_values

    data = values.map { |sid, aid| { role_id: sid, assessment_id: aid } }
    insert_all data if data.present?
  end

  # Assigns a random TA from a list of TAs specified by +ta_ids+ to each student
  # in a list students specified by +student_ids+ for the given grade entry
  # form +form+. Instances of the join model GradeEntryStudent are created if
  # they do not exist.
  def self.randomly_assign_tas(student_ids, ta_ids, form)
    assign_tas(student_ids, ta_ids, form) do |grade_entry_student_ids, tids|
      # Assign TAs in a round-robin fashion to a list of random grade entry
      # students.
      grade_entry_student_ids.shuffle.zip(tids.cycle)
    end
  end

  # Assigns all TAs in a list of TAs specified by +ta_ids+ to each student in a
  # list of students specified by +student_ids+ for the given grade entry form
  # +form+. Instances of the join model GradeEntryStudent are created if they do
  # not exist.
  def self.assign_all_tas(student_ids, ta_ids, form)
    assign_tas(student_ids, ta_ids, form) do |grade_entry_student_ids, tids|
      # Get the Cartesian product of grade entry student IDs and TA IDs.
      grade_entry_student_ids.product(tids)
    end
  end

  # Assigns TAs to grade entry students using a caller-specified block. The
  # block is given the passed-in students' associated grade entry student IDs
  # and the passed-in TA IDs and must return a list of (grade entry student ID,
  # TA ID) pair that represents the TA assignments.
  #
  #   # Assign the TA with ID 3 to the student with ID 1 and the TA with ID 4
  #   # to the grade entry student with ID 2. Both assignments are for the
  #   # grade entry form +form+.
  #   assign_tas([1, 2], [3, 4], form) do |grade_entry_student_ids, ta_ids|
  #     grade_entry_student_ids.zip(ta_ids)  # => [[1, 3], [2, 4]]
  #   end
  #
  # Instances of the join model GradeEntryStudent are created if they do not
  # exist.
  def self.assign_tas(student_ids, ta_ids, form, &)
    # Create non-existing grade entry students.
    merge_non_existing(student_ids, form.id) do |sids, form_ids|
      # Pair a single form ID with each student ID.
      sids.zip(form_ids.cycle)
    end

    # Create non-existing grade entry student TA associations.
    ges_ids = form.grade_entry_students.where(role_id: student_ids).ids
    GradeEntryStudentTa.merge_non_existing(ges_ids, ta_ids, &)
  end

  def self.unassign_tas(student_ids, grader_ids, form)
    GradeEntryStudentTa.joins(:grade_entry_student)
                       .where('grade_entry_students.role_id': student_ids,
                              'grade_entry_students_tas.ta_id': grader_ids,
                              'grade_entry_students.assessment_id': form.id)
                       .delete_all
  end

  # Given a row from a CSV file in the format
  # username,q1mark,q2mark,...,
  # create or update the GradeEntryStudent and Grade objects that
  # correspond to the student
  def self.create_or_update_from_csv_row(row, grade_entry_form,
                                         grade_entry_items, names, overwrite)
    working_row = row.clone
    user_name = working_row.shift

    # Attempt to find the student
    student = grade_entry_form.course.students.joins(:user).where('users.user_name': user_name).first
    if student.nil?
      raise CsvInvalidLineError
    end

    # Create the GradeEntryStudent if it doesn't already exist
    grade_entry_student = grade_entry_form.grade_entry_students.find_or_create_by(role_id: student.id)

    # Create or update the student's grade for each question
    names.each do |grade_entry_name|
      grade_for_grade_entry_item = working_row.shift
      grade_entry_item = grade_entry_items.where(name: grade_entry_name).first

      # Don't add empty grades and remove grades that did exist but are now empty
      old_grade = grade_entry_student.grades
                                     .where(grade_entry_item_id: grade_entry_item.id)
                                     .first

      if overwrite
        if grade_for_grade_entry_item.blank?

          old_grade&.destroy
        else
          grade = grade_entry_student.grades
                                     .find_or_create_by(grade_entry_item: grade_entry_item)
          grade.grade = grade_for_grade_entry_item

          unless grade.save
            raise grade.errors
          end
        end

      elsif old_grade.nil? && grade_for_grade_entry_item.present?
        grade = grade_entry_student.grades
                                   .find_or_create_by(grade_entry_item_id: grade_entry_item.id)
        grade.grade = grade_for_grade_entry_item

        unless grade.save
          raise grade.errors
        end

      end
    end

    grade_entry_student.get_total_grade
  end

  # Return whether or not the given student's grades are all blank
  # (Needed because ActiveRecord's "sum" method returns 0 even if
  #  all the grade.grade values are nil and we need to distinguish
  #  between a total mark of 0 and a blank mark.)
  def all_blank_grades?
    grades = self.grades
    grades_without_nils = grades.reject do |grade|
      grade.grade.nil?
    end
    grades_without_nils.blank?
  end

  def self.get_total_grades(ges_ids)
    grades = GradeEntryStudent.left_outer_joins(:grades)
                              .where('grade_entry_students.id': ges_ids)
                              .pluck('grade_entry_students.id', :grade)
                              .group_by(&:first)
    grades.map do |k, v|
      ges_grades = v.map(&:last)
      ges_grades = ges_grades.all?(&:nil?) ? nil : [ges_grades.compact.sum, 0].max
      [k, ges_grades]
    end.to_h
  end

  def get_total_grade
    GradeEntryStudent.get_total_grades([self.id])[self.id]
  end
end
