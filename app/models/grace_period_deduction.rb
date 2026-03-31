# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: grace_period_deductions
#
#  id            :integer          not null, primary key
#  deduction     :integer
#  created_at    :datetime
#  updated_at    :datetime
#  membership_id :integer
#
# Indexes
#
#  index_grace_period_deductions_on_membership_id  (membership_id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class GracePeriodDeduction < ApplicationRecord
  belongs_to :membership, optional: true
  has_one :course, through: :membership
end
