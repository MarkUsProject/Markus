# Join model representing a member in a grouping
# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: memberships
#
#  id                :integer          not null, primary key
#  membership_status :string
#  type              :string
#  created_at        :datetime
#  updated_at        :datetime
#  grouping_id       :integer          not null
#  role_id           :bigint           not null
#
# Indexes
#
#  index_memberships_on_role_id  (role_id)
#
# Foreign Keys
#
#  fk_memberships_groupings  (grouping_id => groupings.id)
#  fk_rails_...              (role_id => roles.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class Membership < ApplicationRecord
  has_many :grace_period_deductions, dependent: :destroy

  belongs_to :role
  validates_associated :role

  has_one :user, through: :role

  belongs_to :grouping
  validates_associated :grouping

  has_one :course, through: :grouping
  validate :courses_should_match
end
