# Policy for managing KeyPairs
class KeyPairPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    enabled? && git_enabled? && (user.admin? || user.ta? || any_vcs_submit?)
  end

  def git_enabled?
    Rails.configuration.x.repository.type == 'git'
  end

  def enabled?
    Rails.configuration.enable_key_storage
  end

  def any_vcs_submit?
    Assignment.joins(:assignment_properties)
              .where('assignment_properties.vcs_submit': true,
                     is_hidden: false)
              .exists?
  end
end
