class Tag < ActiveRecord::Base

  belongs_to  :user
  has_and_belongs_to_many  :assignment
  has_and_belongs_to_many :groupings

end
