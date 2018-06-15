# Join model representing a member in a grouping
class Membership < ApplicationRecord

  has_many :grace_period_deductions, dependent: :destroy

  belongs_to :user
  validates_associated :user,
                       message: 'associated user needs to be valid'

  belongs_to :grouping
  validates_associated :grouping,
                       message: 'associated grouping needs to be valid'

end
