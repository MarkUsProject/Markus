class Assignment < ActiveRecord::Base
  
  has_many  :assignment_files
  validates_associated :assignment_files
  
  validates_presence_of     :name, :group_min
  validates_uniqueness_of   :name, :case_sensitive => true
  
  validates_numericality_of :group_min, :only_integer => true,  :greater_than => 0
  validates_numericality_of :group_max, :only_integer => true,  :allow_nil => true
  
  # Checks if an assignment is an individually-submitted assignment (no groups)
  def individual?
    group_min == 1 && group_max == 1
  end
  
end
