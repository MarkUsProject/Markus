# GradeEntryStudent represents a row (i.e. a student's grades for each question)
# in a grade entry form.
class GradeEntryStudent < ActiveRecord::Base
  belongs_to :user
  belongs_to :grade_entry_form

  has_many  :grades, :dependent => :destroy
  has_many  :grade_entry_items, :through => :grades

  has_and_belongs_to_many :tas

  validates_associated :user
  validates_associated :grade_entry_form

  validates_numericality_of :user_id, :only_integer => true, :greater_than => 0,
                            :message => I18n.t('invalid_id')
  validates_numericality_of :grade_entry_form_id, :only_integer => true, :greater_than => 0,
                            :message => I18n.t('invalid_id')

  # Given a row from a CSV file in the format
  # username,q1mark,q2mark,...,
  # create or update the GradeEntryStudent and Grade objects that
  # correspond to the student
  def self.create_or_update_from_csv_row(row, grade_entry_form, grade_entry_items, names)
    working_row = row.clone
    user_name = working_row.shift

    # Attempt to find the student
    student = Student.find_by_user_name(user_name)
    if student.nil?
      raise I18n.t('grade_entry_forms.csv.invalid_user_name')
    end

    # Create the GradeEntryStudent if it doesn't already exist
    grade_entry_student = grade_entry_form.grade_entry_students.find_or_create_by_user_id(student.id)

    # Create or update the student's grade for each question
    names.each do |grade_entry_name|
      grade_for_grade_entry_item = working_row.shift
      grade_entry_item = grade_entry_items.find_by_name(grade_entry_name)

      # Don't add empty grades and remove grades that did exist but are now empty
      if !grade_for_grade_entry_item || grade_for_grade_entry_item.empty?
        grade = grade_entry_student.grades.find_by_grade_entry_item_id(grade_entry_item.id)
        unless grade.nil?
          grade.destroy
        end
      else
        grade = grade_entry_student.grades.find_or_create_by_grade_entry_item_id(grade_entry_item.id)
        grade.grade = grade_for_grade_entry_item
        unless grade.save
          grade_entry_student.update_total_grade
          raise RuntimeError.new(grade.errors)
        end
      end
    end
    grade_entry_student.update_total_grade
  end

  # Returns an array containing the student names that didn't exist
  def self.assign_tas_by_csv(csv_file_contents, grade_entry_form_id, encoding)
    grade_entry_form = GradeEntryForm.find(grade_entry_form_id)

    failures = []
    if encoding != nil
      csv_file_contents = StringIO.new(Iconv.iconv('UTF-8', encoding, csv_file_contents).join)
    end
    CsvHelper::Csv.parse(csv_file_contents) do |row|
      student_name = row.shift # Knocks the first item from array
      student = Student.find_by_user_name(student_name)
      if student.nil?
        failures.push(student_name)
      else
        grade_entry_student = grade_entry_form.grade_entry_students.find_or_create_by_user_id(student.id)
        if grade_entry_student.nil?
          failures.push(student_name)
        else
          grade_entry_student.add_tas_by_user_name_array(row) # The rest of the array
        end
      end
    end
    return failures
  end

  def add_tas_by_user_name_array(ta_user_name_array)
    grade_entry_tas = []
    ta_user_name_array.each do |ta_user_name|
      ta = Ta.find_by_user_name(ta_user_name)
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

    tas_to_remove = grade_entry_student_tas.find_all_by_id(ta_id_array)
    tas_to_remove.each do |ta_to_remove|
      self.tas.delete(ta_to_remove)
    end
    self.save
  end

  def update_total_grade
    total = self.grades.sum('grade').round(2)
    if total == 0 && self.all_blank_grades?
      total = nil
    end

    if self.total_grade != total
      self.total_grade = total
      self.save
    end
    total
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
end
