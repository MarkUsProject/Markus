class Notes < ActiveRecord::Base
  belongs_to :grouping
  belongs_to :user, :foreign_key => :creator_id
  
  validates_presence_of :note_message, :grouping_id, :creator_id, :type_association
  validates_associated :grouping, :user
end
