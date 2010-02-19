# GradeEntryItem represents column names (i.e. question names and totals) 
# in a grade entry form. 
class GradeEntryItem < ActiveRecord::Base
  belongs_to  :grade_entry_form
  
  has_many   :grades, :dependent => :destroy
  has_many   :grade_entry_students, :through => :grades
  
  validates_presence_of   :name
  validates_presence_of   :out_of
  
  validates_associated    :grade_entry_form
  
  validates_numericality_of :out_of, :only_integer => true,  :greater_than => 0, 
                            :message => I18n.t('grade_entry_forms.invalid_column_out_of')                          
  validates_uniqueness_of   :name, :scope => :grade_entry_form_id, 
                            :message => I18n.t('grade_entry_forms.invalid_name')

end
