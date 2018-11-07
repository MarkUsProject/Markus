class ApplicationPolicy < ActionPolicy::Base
  # make :manage? a real catch-all
  alias_rule :index?, :create?, to: :manage?
end
