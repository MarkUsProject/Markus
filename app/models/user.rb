require 'English'
require 'digest' # required for {set,reset}_api_token
require 'base64' # required for {set,reset}_api_token

# We always assume the following fields exists:
# => :user_name, :last_name, :first_name
# If there are added columns, add the default values to default_values
class User < ApplicationRecord
  after_initialize :set_display_name, :set_time_zone
  before_validation :strip_name
  before_validation :nillify_empty_email_and_id_number

  enum :theme, { light: 1, dark: 2 }

  # Group relationships
  has_many :key_pairs, dependent: :destroy
  has_many :roles, inverse_of: :user
  has_many :courses, through: :roles
  has_many :lti_users
  validates :type, format: { with: /\AEndUser|AutotestUser|AdminUser\z/ }

  validates :user_name, :last_name, :first_name, :time_zone, :display_name, presence: true
  validates :user_name, uniqueness: true
  validates :email, uniqueness: { allow_nil: true }
  validates :id_number, uniqueness: { allow_nil: true }
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  validates :user_name,
            format: { with: /\A[a-zA-Z0-9\-_]+\z/ },
            unless: ->(u) { u.autotest_user? || u.admin_user? }

  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }

  # Authentication constants to be used as return values
  # see self.authenticated? and main_controller for details
  AUTHENTICATE_SUCCESS = 'success'.freeze
  AUTHENTICATE_ERROR = 'error'.freeze
  AUTHENTICATE_BAD_PLATFORM = 'bad_platform'.freeze
  AUTHENTICATE_BAD_CHAR = 'bad_char'.freeze
  AUTHENTICATE_LOCAL = 'local'.freeze
  AUTHENTICATE_REMOTE = 'remote'.freeze

  # If auth_type == AUTHENTICATE_LOCAL: Authenticates login against its password
  # through a script specified by Settings.validate_file
  # if auth_type == AUTHENTICATE_REMOTE: Authenticates user name
  # through a script specified by Settings.remote_validate_file
  def self.authenticate(login, password: nil, ip: nil, auth_type: AUTHENTICATE_LOCAL)
    # Do not allow the following characters in usernames/passwords
    # Right now, this is \n and \0 only, since username and password
    # are delimited by \n and C programs use \0 to terminate strings
    not_allowed_regexp = /[\n\0]+/
    if not_allowed_regexp.match(login) || not_allowed_regexp.match(password)
      m_logger = MarkusLogger.instance
      m_logger.log("User '#{login}' failed to log in. Username/password contained " \
                   'illegal characters', MarkusLogger::ERROR)
      AUTHENTICATE_BAD_CHAR
    else
      # Open a pipe and write to stdin of the program specified by Settings.validate_file.
      # We could read something from the programs stdout, but there is no need
      # for that at the moment (you would do it by e.g. pipe.readlines)

      # External validation is supported on *NIX only
      if RUBY_PLATFORM.match?(/(:?mswin|mingw)/) # should match for Windows only
        return AUTHENTICATE_BAD_PLATFORM
      end

      # In general, the external password validation program should exit with 0 for success
      # and exit with any other integer for failure.
      validate_script = auth_type == AUTHENTICATE_LOCAL ? Settings.validate_file : Settings.remote_validate_file
      pipe = IO.popen("'#{validate_script}'", 'w+') # quotes to avoid choking on spaces
      to_stdin = [login, password, ip].compact.join("\n")
      pipe.puts(to_stdin) # write to stdin of Settings.validate_file
      pipe.close
      m_logger = MarkusLogger.instance
      custom_message = Settings.validate_custom_status_message[$CHILD_STATUS.exitstatus.to_s]
      if $CHILD_STATUS.exitstatus == 0
        m_logger.log("User '#{login}' logged in.", MarkusLogger::INFO)
        AUTHENTICATE_SUCCESS
      elsif custom_message
        m_logger.log("Login failed for user #{login}. Reason: #{custom_message}", MarkusLogger::ERROR)
        $CHILD_STATUS.exitstatus.to_s
      else
        m_logger.log("User '#{login}' failed to log in.", MarkusLogger::ERROR)
        AUTHENTICATE_ERROR
      end
    end
  end

  def self.get_orphaned_users
    self.where.missing(:roles)
  end

  # Helper methods -----------------------------------------------------
  def autotest_user?
    self.instance_of?(AutotestUser)
  end

  def admin_user?
    self.instance_of?(AdminUser)
  end

  def end_user?
    self.instance_of?(EndUser)
  end

  def set_display_name
    strip_name
    self.display_name ||= "#{self.first_name} #{self.last_name}"
  end

  def set_time_zone
    self.time_zone ||= Time.zone.name
  end

  # Reset API key for user model. The key is a SHA2 512 bit long digest,
  # which is in turn MD5 digested and Base64 encoded so that it doesn't
  # include bad HTTP characters.
  #
  # TODO: If we end up using this heavily we should probably let this key
  # expire every X days/hours/weeks. When it does, a new token should be
  # automatically generated.
  def reset_api_key
    key = generate_api_key
    md5 = Digest::MD5.new
    md5.update(key)
    # base64 encode md5 hash
    self.update(api_key: Base64.encode64(md5.to_s).strip)
  end

  def admin_courses
    if self.admin_user?
      courses = Course.all
    else
      courses = self.courses.where('roles.type': 'Instructor')
    end
    courses
  end

  private

  # Create some random, hard to guess SHA2 512 bit long
  # digest.
  def generate_api_key
    digest = Digest::SHA2.new(512)
    # generate a unique token
    unique_seed = SecureRandom.hex(20)
    digest.update("#{unique_seed} SECRET! #{Time.current.to_f}").to_s
  end

  # strip input string
  def strip_name
    if self.user_name
      self.user_name = self.user_name.strip
    end
    if self.last_name
      self.last_name = self.last_name.strip
    end
    if self.first_name
      self.first_name = self.first_name.strip
    end
    if self.email
      self.email = self.email.strip
    end
    if self.id_number
      self.id_number = self.id_number.strip
    end
  end

  def nillify_empty_email_and_id_number
    self.email = nil if self.email.blank?
    self.id_number = nil if self.id_number.blank?
  end
end
