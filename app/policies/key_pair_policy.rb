# Policy for managing KeyPairs
class KeyPairPolicy < ApplicationPolicy
  skip_pre_check :role_exists?
  skip_pre_check :view_hidden_course?

  default_rule :manage?

  def manage?
    Settings.repository.type == 'git' && Settings.enable_key_storage
  end
end
