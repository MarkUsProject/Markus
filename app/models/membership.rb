# Join model representing a member in a grouping
class Membership < ApplicationRecord

  has_many :grace_period_deductions, dependent: :destroy

  belongs_to :user
  validates_associated :user,
                       message: 'associated user needs to be valid'
  validates_presence_of :user_id, message: 'needs a user id'

  belongs_to :grouping
  validates_associated :grouping,
                       message: 'associated grouping needs to be valid'
  validates_presence_of :grouping_id, message: 'needs a grouping id'

end
