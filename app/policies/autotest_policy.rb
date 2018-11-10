class AutotestPolicy < ApplicationPolicy
  def not_a_ta?
    !user.ta?
  end
end
