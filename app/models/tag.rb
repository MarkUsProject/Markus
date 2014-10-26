class Tag < ActiveRecord::Base

  belongs_to  :assignment
  has_and_belongs_to_many :groupings

end
