class Assignment < ActiveRecord::Base
  
  has_many  :assignment_files
  validates_associated :assignment_files
  
  validates_presence_of     :name, :group_min
  validates_uniqueness_of   :name, :case_sensitive => true
  
  validates_numericality_of :group_min, :only_integer => true,  :greater_than => 0
  validates_numericality_of :group_max, :only_integer => true
  
  def validate
    if group_max && group_min && group_max < group_min
      errors.add(:group_max, "must be greater than the minimum number of groups")
    end
  end
  
  # Checks if an assignment is an individually-submitted assignment (no groups)
  def individual?
    group_min == 1 && group_max == 1
  end
  
end
