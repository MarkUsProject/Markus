class AssignmentFile < ActiveRecord::Base
  belongs_to  :assignment
  
  validates_presence_of   :filename
  validates_uniqueness_of :filename, :scope => :assignment_id
 
end
