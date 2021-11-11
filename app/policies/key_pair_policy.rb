# Policy for managing KeyPairs
class KeyPairPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    Settings.repository.type == 'git' && Settings.enable_key_storage
  end
end
