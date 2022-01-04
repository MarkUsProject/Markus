# Join model representing a member in a grouping
class Membership < ApplicationRecord
  has_many :grace_period_deductions, dependent: :destroy

  belongs_to :role
  validates_associated :role

  belongs_to :grouping
  validates_associated :grouping

  has_one :course, through: :grouping
  validate :courses_should_match
end
