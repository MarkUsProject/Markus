class Tag < ActiveRecord::Base

  belongs_to :user
  has_and_belongs_to_many :assignments
  has_and_belongs_to_many :groupings

end
