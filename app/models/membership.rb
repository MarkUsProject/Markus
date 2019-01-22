# Join model representing a member in a grouping
class Membership < ApplicationRecord

  has_many :grace_period_deductions, dependent: :destroy

  belongs_to :user
  validates_associated :user

  belongs_to :grouping
  validates_associated :grouping

end
