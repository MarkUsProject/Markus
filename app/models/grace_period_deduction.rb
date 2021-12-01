class GracePeriodDeduction < ApplicationRecord
  belongs_to :membership, optional: true
  has_one :course, through: :membership
end
