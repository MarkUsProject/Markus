# GradeEntryForm can represent a test, lab, exam, etc.
# A grade entry form has many columns which represent the questions and their total
# marks (i.e. GradeEntryItems) and many rows which represent students and their
# marks on each question (i.e. GradeEntryStudents).
class GradeEntryForm < ActiveRecord::Base
  has_many                  :grade_entry_items, :dependent => :destroy
  has_many                  :grade_entry_students, :dependent => :destroy  
  
  validates_presence_of     :short_identifier
  validates_uniqueness_of   :short_identifier, :case_sensitive => true
  
  accepts_nested_attributes_for :grade_entry_items, :allow_destroy => true
  
  def validate
    
    # Check that the date is valid - the date is allowed to be in the past
    if Time.zone.parse(date.to_s).nil?
      errors.add :date, I18n.t('grade_entry_forms.invalid_date')
    end
  end
end
