class Assignment < ActiveRecord::Base
  
  has_many  :assignment_files
  validates_associated :assignment_files
  
  validates_numericality_of :group_limit, :only_integer => true,  :greater_than => 0
end
