
# Join model representing a member in a group
class Membership < ActiveRecord::Base
  
  belongs_to  :user
  belongs_to  :group
  validates_uniqueness_of :user_id, :scope => :group_id
  validates_format_of :status, :with => /inviter|pending|accepted/
  
  # user association/validations
  validates_presence_of   :user_id, :message => "presence is not strong with you"
  validates_associated    :user,    :message => 'association is not strong with you'
  
  def validate
    errors.add_to_base("User must be a student") if user && !user.student?
  end
end
