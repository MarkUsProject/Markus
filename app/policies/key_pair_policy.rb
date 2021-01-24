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
    Settings.repository.type == 'git' && Settings.enable_key_storage
  end
end
