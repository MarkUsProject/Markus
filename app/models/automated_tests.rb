class AutomatedTests < ActiveRecord::Base
  belongs_to :group
  belongs_to :assignment

  validates :assignment_id, :presence => true
  validates :group_id, :presence => true
end
