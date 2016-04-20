require 'encoding'

# GradeEntryStudent represents a row (i.e. a student's grades for each question)
# in a grade entry form.
class GradeEntryStudent < ActiveRecord::Base
  attr_accessor :total_grade

  belongs_to :user
  validates_associated :user

  belongs_to :grade_entry_form
  validates_associated :grade_entry_form

  has_many :grades, dependent: :destroy

  has_many :grade_entry_items, through: :grades

  has_many :grade_entry_student_tas
  has_many :tas, through: :grade_entry_student_tas

  validates_numericality_of :user_id,
                            only_integer: true,
                            greater_than: 0,
                            message: I18n.t('invalid_id')

  validates_numericality_of :grade_entry_form_id,
                            only_integer: true,
                            greater_than: 0,
                            message: I18n.t('invalid_id')

  # Merges records of GradeEntryStudent that do not exist yet using a caller-
  # specified block. The block is given the passed-in student IDs and grade
  # entry form IDs and must return a list of (student ID, grade entry form IDs)
  # pair that represents the grade entry students.
  def self.merge_non_existing(student_ids, form_ids)
    # Only use IDs that identify existing model instances.
    student_ids = Student.where(id: Array(student_ids)).pluck(:id)
    form_ids = GradeEntryForm.where(id: Array(form_ids)).pluck(:id)

    columns = [:user_id, :grade_entry_form_id]
    existing_values = GradeEntryStudent
      .where(user_id: student_ids, grade_entry_form_id: form_ids)
      .pluck(:user_id, :grade_entry_form_id)
    # Delegate the generation of records to the caller-specified block and
    # remove values that already exist in the database.
    values = yield(student_ids, form_ids) - existing_values
    # TODO replace import with create when the PG driver supports bulk create,
    # then remove the activerecord-import gem.
    import(columns, values, validate: false)
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
  def self.assign_tas(student_ids, ta_ids, form, &block)
    # Create non-existing grade entry students.
    merge_non_existing(student_ids, form.id) do |sids, form_ids|
      # Pair a single form ID with each student ID.
      sids.zip(form_ids.cycle)
    end

    # Create non-existing grade entry student TA associations.
    ges_ids = joins(:user).where(users: { id: student_ids }).pluck(:id)
    GradeEntryStudentTa.merge_non_existing(ges_ids, ta_ids, &block)
  end

  # Unassigns TAs from grade entry students. +gest_ids+ is a list of IDs to the
  # join model GradeEntryStudentTa that specifies the unassignment to be done.
  def self.unassign_tas(gest_ids)
    GradeEntryStudentTa.delete_all(id: gest_ids)
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
    student = Student.where(user_name: user_name).first
    if student.nil?
      raise CSVInvalidLineError
    end

    # Create the GradeEntryStudent if it doesn't already exist
    grade_entry_student = grade_entry_form.grade_entry_students.find_or_create_by(user_id: student.id)

    # Create or update the student's grade for each question
    names.each do |grade_entry_name|
      grade_for_grade_entry_item = working_row.shift
      grade_entry_item = grade_entry_items.where(name: grade_entry_name).first

      # Don't add empty grades and remove grades that did exist but are now empty
      old_grade = grade_entry_student.grades
                  .where(grade_entry_item_id: grade_entry_item.id)
                  .first

      if overwrite
        if !grade_for_grade_entry_item || grade_for_grade_entry_item.empty?

          unless old_grade.nil?
            old_grade.destroy
          end
        else
          grade = grade_entry_student.grades
                  .find_or_create_by(grade_entry_item: grade_entry_item)
          grade.grade = grade_for_grade_entry_item

          unless grade.save
            raise RuntimeError.new(grade.errors)
          end
        end

      else
        if old_grade.nil? &&
           (grade_for_grade_entry_item && !grade_for_grade_entry_item.empty?)

          grade = grade_entry_student.grades
                  .find_or_create_by(grade_entry_item_id: grade_entry_item.id)
          grade.grade = grade_for_grade_entry_item

          unless grade.save
            raise RuntimeError.new(grade.errors)
          end
        end
      end
    end

    grade_entry_student.total_grade
  end

  def add_tas_by_user_name_array(ta_user_name_array)
    grade_entry_tas = []
    ta_user_name_array.each do |ta_user_name|
      ta = Ta.where(user_name: ta_user_name).first
      if !ta.nil?
        if !self.tas.include?(ta)
          self.tas << ta
        end
      end
      grade_entry_tas += Array(ta)
    end
    self.save
  end


  def add_tas(tas)
    return unless self.valid?
    grade_entry_student_tas = self.tas
    tas = Array(tas)
    tas.each do |ta|
      if !grade_entry_student_tas.include? ta
        self.tas << ta
        grade_entry_student_tas += [ta]
      end
    end
    self.save
  end

  def remove_tas(ta_id_array)
    #if no tas to remove, return.
    return if ta_id_array == []
    grade_entry_student_tas = self.tas

    tas_to_remove = grade_entry_student_tas.where(id: ta_id_array)
    tas_to_remove.each do |ta_to_remove|
      self.tas.delete(ta_to_remove)
    end
    self.save
  end

  # Return the total of all the grades.
  def total_grade
    # TODO: This should be a calculated column
    # Why are we managing it by hand?
    refresh_total_grade
  end

  def save(*)
    refresh_total_grade # make sure the latest total grade is always saved
    super
  end

  # Return whether or not the given student's grades are all blank
  # (Needed because ActiveRecord's "sum" method returns 0 even if
  #  all the grade.grade values are nil and we need to distinguish
  #  between a total mark of 0 and a blank mark.)
  def all_blank_grades?
    grades = self.grades
    grades_without_nils = grades.select do |grade|
      !grade.grade.nil?
    end
    grades_without_nils.blank?
  end

  private

  # Calculate and set the total grade
  def refresh_total_grade
    total = grades.sum(:grade).round(2)

    if total == 0 && self.all_blank_grades?
      total = nil
    end

    write_attribute(:total_grade, total)

    total
  end
end
