class KeyPair < ApplicationRecord
  belongs_to :user

  validates :public_key, presence: true
  before_validation(on: :create) { self.public_key&.strip! }
  validate :public_key_format, if: -> { self.public_key }

  KEY_TYPES = %w[sk-ecdsa-sha2-nistp256@openssh.com
                 ecdsa-sha2-nistp256
                 ecdsa-sha2-nistp384
                 ecdsa-sha2-nistp521
                 sk-ssh-ed25519@openssh.com
                 ssh-ed25519
                 ssh-dss
                 ssh-rsa].freeze

  private

  # Check if +self.public_key+ is formatted correctly
  def public_key_format
    single_line = self.public_key.lines.one? { |line| line.strip.present? }
    key_type, key, _comment = self.public_key.split
    valid_key_type = KEY_TYPES.include? key_type
    errors.add(:public_key, :invalid_key) unless single_line && valid_key_type && !key.nil?
  end
end
