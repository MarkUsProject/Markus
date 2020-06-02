class MarkingSchemePolicy < ApplicationPolicy
  alias_rule :index?, :populate?, :create?, :update?, :new?,
             :edit?, :destroy?, to: :manage?

  def manage?
    user.admin? || (user.ta? && allowed_to?(:manage_marking_schemes?, with: GraderPermissionsPolicy))
  end
end
