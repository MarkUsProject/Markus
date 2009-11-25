class Notes < ActiveRecord::Base
  belongs_to :user, :foreign_key => :creator_id
  belongs_to :noteable, :polymorphic => true
  
  validates_presence_of :notes_message, :creator_id, :noteable
  validates_associated :user
end
