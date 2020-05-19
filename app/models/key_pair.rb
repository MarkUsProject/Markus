class KeyPair < ApplicationRecord
  after_create :update_authorized_keys
  after_destroy :update_authorized_keys

  AUTHORIZED_KEYS_FILE = 'authorized_keys'.freeze
  AUTHORIZED_KEY_ARGS = "no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty".freeze

  def self.full_key_string(user_name, public_key)
    markus_shell = Rails.configuration.x.repository.git_shell
    relative_url_root = Rails.configuration.action_controller.relative_url_root
    command = "command=\"LOGIN_USER=#{user_name} RELATIVE_URL_ROOT=#{relative_url_root} #{markus_shell}\""
    "#{command},#{AUTHORIZED_KEY_ARGS} #{public_key}"
  end

  private

  def update_authorized_keys
    UpdateKeysJob.perform_later
  end
end
