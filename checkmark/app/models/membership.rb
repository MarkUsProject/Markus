
# Join model representing a member in a group
class Membership < ActiveRecord::Base
  
  belongs_to  :user
  belongs_to  :group
  validates_uniqueness_of :user_id, :scope => :group_id 
  
  attr_protected  :status
  validates_format_of :status, :with => /inviter|pending|accepted/
  
end
