class GracePeriodDeduction < ApplicationRecord
  belongs_to :membership, optional: true
end
