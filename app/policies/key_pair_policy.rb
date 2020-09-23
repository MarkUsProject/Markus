# Policy for managing KeyPairs
class KeyPairPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    view? && (
      user.admin? ||
      user.ta? ||
      Assignment.joins(:assignment_properties).where('assignment_properties.vcs_submit': true, is_hidden: false).exists?
    )
  end

  def view?
    Rails.configuration.x.repository.type == 'git' && Rails.configuration.enable_key_storage
  end
end
