# GradeEntryStudent represents a row (i.e. a student's grades for each question) 
# in a grade entry form.
class GradeEntryStudent < ActiveRecord::Base
  belongs_to :user
  belongs_to :grade_entry_form
  
  has_many  :grades, :dependent => :destroy
  has_many  :grade_entry_items, :through => :grades
  
  validates_associated :user
  validates_associated :grade_entry_form
  
  validates_numericality_of :user_id, :only_integer => true, :greater_than => 0, 
                            :message => I18n.t('invalid_id')
  validates_numericality_of :grade_entry_form_id, :only_integer => true, :greater_than => 0, 
                            :message => I18n.t('invalid_id')
  
end
