class KeyPair < ApplicationRecord
  belongs_to :user

  after_create :update_authorized_keys
  after_destroy :update_authorized_keys
  validates_presence_of :public_key
  validates_presence_of :user
  before_validation(on: :create) { self.public_key&.strip! }
  validate :public_key_format, if: -> { self.public_key }

  AUTHORIZED_KEYS_FILE = 'authorized_keys'.freeze
  AUTHORIZED_KEY_ARGS = 'no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty'.freeze
  KEY_TYPES = %w[sk-ecdsa-sha2-nistp256@openssh.com
                 ecdsa-sha2-nistp256
                 ecdsa-sha2-nistp384
                 ecdsa-sha2-nistp521
                 sk-ssh-ed25519@openssh.com
                 ssh-ed25519
                 ssh-dss
                 ssh-rsa].freeze

  # Return a single line to add to the authorized_key file that contains the +public_key+,
  # all +AUTHORIZED_KEY_ARGS+ and the command to call +Rails.configuration.x.repository.git_shell+
  # with environment variables indicating the +user_name+ and this instance's relative url root
  def self.full_key_string(user_name, public_key)
    markus_shell = Rails.configuration.x.repository.git_shell
    relative_url_root = Rails.configuration.action_controller.relative_url_root
    command = "command=\"LOGIN_USER=#{user_name} RELATIVE_URL_ROOT=#{relative_url_root} #{markus_shell}\""
    "#{command},#{AUTHORIZED_KEY_ARGS} #{public_key}"
  end

  private

  # Update the authorized_key file
  def update_authorized_keys
    UpdateKeysJob.perform_later
  end

  # Check if +self.public_key+ is formatted correctly
  def public_key_format
    single_line = self.public_key.lines.map(&:strip).select(&:present?).length == 1
    key_type, key, _comment = self.public_key.split
    valid_key_type = KEY_TYPES.include? key_type
    errors.add(:public_key, I18n.t('key_pairs.create.invalid_key')) unless single_line && valid_key_type && !key.nil?
  end
end
