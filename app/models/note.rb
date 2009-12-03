class Note < ActiveRecord::Base
  belongs_to :user, :foreign_key => :creator_id
  belongs_to :noteable, :polymorphic => true
  
  validates_presence_of :notes_message, :creator_id, :noteable
  validates_associated :user
  
  def user_can_modify?(current_user)
    return current_user.admin? || user == current_user
  end
  
  def format_date
    return created_at.strftime(LONG_DATE_TIME_FORMAT)
  end
end
