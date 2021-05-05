require 'digest' # required for {set,reset}_api_token
require 'base64' # required for {set,reset}_api_token

# We always assume the following fields exists:
# => :user_name, :last_name, :first_name
# If there are added columns, add the default values to default_values
class User < ApplicationRecord
  before_validation :strip_name
  before_validation :nillify_empty_email_and_id_number

  enum theme: { light: 1, dark: 2 }

  # Group relationships
  has_many :memberships, dependent: :delete_all
  has_many :grade_entry_students
  has_many :groupings, through: :memberships
  has_many :notes, as: :noteable, dependent: :destroy
  has_many :accepted_memberships,
           -> { where membership_status: [StudentMembership::STATUSES[:accepted], StudentMembership::STATUSES[:inviter]] },
           class_name: 'Membership'
  has_many :annotations, as: :creator
  has_many :test_runs, dependent: :destroy
  has_many :split_pdf_logs
  has_many :key_pairs, dependent: :destroy

  validates_presence_of     :user_name, :last_name, :first_name, :time_zone, :display_name
  validates_uniqueness_of   :user_name
  validates_uniqueness_of   :email, :allow_nil => true
  validates_uniqueness_of   :id_number, :allow_nil => true
  validates_inclusion_of    :time_zone, :in => ActiveSupport::TimeZone.all.map(&:name)
  validates                 :user_name,
                            format: { with: /\A[a-zA-Z0-9\-_]+\z/,
                                      message: 'user_name must be alphanumeric, hyphen, or underscore' },
                            unless: ->(u) { u.test_server? }
  after_initialize :set_display_name, :set_time_zone

  validates_format_of       :type,          with: /\AStudent|Admin|Ta|TestServer\z/
  # role constants
  STUDENT = 'Student'
  ADMIN = 'Admin'
  TA = 'Ta'
  TEST_SERVER = 'TestServer'

  # Authentication constants to be used as return values
  # see self.authenticated? and main_controller for details
  AUTHENTICATE_SUCCESS = 'success'.freeze
  AUTHENTICATE_ERROR = 'error'.freeze
  AUTHENTICATE_BAD_PLATFORM = 'bad_platform'.freeze
  AUTHENTICATE_BAD_CHAR = 'bad_char'.freeze

  # Verifies if user is allowed to enter MarkUs
  # Returns user object representing the user with the given login.
  def self.authorize(login)
    # fetch login in database to see if it is registered.
    where(user_name: login).first
  end

  # Authenticates login against its password
  # through a script specified by Settings.validate_file
  def self.authenticate(login, password, ip: nil)
    # Do not allow the following characters in usernames/passwords
    # Right now, this is \n and \0 only, since username and password
    # are delimited by \n and C programs use \0 to terminate strings
    not_allowed_regexp = Regexp.new(/[\n\0]+/)
    if not_allowed_regexp.match(login) || not_allowed_regexp.match(password)
      m_logger = MarkusLogger.instance
      m_logger.log("User '#{login}' failed to log in. Username/password contained " +
                       'illegal characters', MarkusLogger::ERROR)
      AUTHENTICATE_BAD_CHAR
    else
      # Open a pipe and write to stdin of the program specified by Settings.validate_file.
      # We could read something from the programs stdout, but there is no need
      # for that at the moment (you would do it by e.g. pipe.readlines)

      # External validation is supported on *NIX only
      if RUBY_PLATFORM =~ /(:?mswin|mingw)/ # should match for Windows only
        return AUTHENTICATE_BAD_PLATFORM
      end

      # In general, the external password validation program should exit with 0 for success
      # and exit with any other integer for failure.
      pipe = IO.popen("'#{Settings.validate_file}'", 'w+') # quotes to avoid choking on spaces
      to_stdin = [login, password, ip].reject(&:nil?).join("\n")
      pipe.puts(to_stdin) # write to stdin of Settings.validate_file
      pipe.close
      m_logger = MarkusLogger.instance
      custom_message = Settings.validate_custom_status_message[$?.exitstatus.to_s]
      if $?.exitstatus == 0
        m_logger.log("User '#{login}' logged in.", MarkusLogger::INFO)
        return AUTHENTICATE_SUCCESS
      elsif custom_message
        m_logger.log("Login failed for user #{login}. Reason: #{custom_message}", MarkusLogger::ERROR)
        return $?.exitstatus.to_s
      else
        m_logger.log("User '#{login}' failed to log in.", MarkusLogger::ERROR)
        return AUTHENTICATE_ERROR
      end
    end
  end

  # Helper methods -----------------------------------------------------

  def admin?
    self.class == Admin
  end

  def ta?
    self.class == Ta
  end

  def student?
    self.class == Student
  end

  def test_server?
    self.class == TestServer
  end

  def set_display_name
    strip_name
    self.display_name ||= "#{self.first_name} #{self.last_name}"
  end

  def set_time_zone
    self.time_zone ||= Time.zone.name
  end

  # Submission helper methods -------------------------------------------------

  def grouping_for(aid)
    groupings.find { |g| g.assessment_id == aid }
  end

  def is_a_reviewer?(assignment)
    is_a?(Student) && !assignment.nil? && assignment.is_peer_review?
  end

  def is_reviewer_for?(assignment, result)
    # aid is the peer review assignment id, and result_id
    # is the peer review result
    if assignment.nil?
      return false
    end
    group =  grouping_for(Integer(assignment.id))
    if group.nil?
      return false
    end
    prs = PeerReview.where(reviewer_id: group.id)
    if prs.first.nil?
      return false
    end
    pr = prs.find {|p| p.result_id == Integer(result.id)}

    is_a?(Student) && !pr.nil?
  end

  def self.upload_user_list(user_class, user_list, encoding)
    user_columns = user_class::CSV_UPLOAD_ORDER.dup
    users = []
    user_names = Set.new
    user_name_i = user_columns.find_index(:user_name)
    section_name_i = user_columns.find_index(:section_name)
    first_name_i = user_columns.find_index(:first_name)
    last_name_i = user_columns.find_index(:last_name)
    unless section_name_i.nil?
      user_columns[section_name_i] = :section_id # becomes foreign key
    end

    parsed = MarkusCsv.parse(user_list, skip_blanks: true, row_sep: :auto, encoding: encoding) do |row|
      next if row.empty?
      raise CsvInvalidLineError if user_names.include?(row[user_name_i])
      if row.size < user_columns.size
        row.fill(nil, row.size...user_columns.size)
      end
      if row.size > user_columns.size
        row = row[0...user_columns.size]
      end
      unless section_name_i.nil?
        section = Section.find_or_create_by(name: row[section_name_i])
        row[section_name_i] = if section.nil? then nil else section.id end
      end
      user_names << row[user_name_i]
      users << row
    end
    if parsed[:valid_lines].blank?
      # the csv was malformed (or empty, which is ok)
      # we should not trust the rows processed before finding it was malformed
      users.clear
    else
      parsed[:valid_lines] = '' # reset the value from MarkusCsv#parse, use import's return instead
    end

    user_columns.push(:display_name)
    user_columns.push(:time_zone)
    users.each { |u| u.push("#{u[first_name_i]} #{u[last_name_i]}") }
    users.each { |u| u.push(Time.zone.name) }

    existing_user_ids = user_class.all.pluck(:id)
    imported = nil
    parsed[:invalid_records] = ''
    begin
      User.transaction do
        imported = user_class.import user_columns, users, on_duplicate_key_update: {
          conflict_target: [:user_name],
          columns: [:last_name, :first_name, :section_id, :email, :id_number, :display_name, :time_zone]
        }
        User.where(id: imported.ids).each do |user|
          if user_class == Ta
            # This will only trigger before_create callback in ta model, not after_create callback
            user.run_callbacks(:create) { false }
          end
          user.validate!
        rescue ActiveRecord::RecordInvalid
          error_message = user.errors
                              .messages
                              .map { |k, v| "#{k} #{v.flatten.join ','}" }.flatten.join MarkusCsv::INVALID_LINE_SEP
          parsed[:invalid_records] += "#{user.user_name}: #{error_message}"
        end
        unless parsed[:invalid_records].empty?
          raise ActiveRecord::Rollback
        end
      end
      unless imported.failed_instances.empty?
        if parsed[:invalid_lines].blank?
          parsed[:invalid_lines] = I18n.t('upload_errors.invalid_rows')
        else
          parsed[:invalid_lines] += MarkusCsv::INVALID_LINE_SEP # concat to invalid_lines from MarkusCsv#parse
        end
        parsed[:invalid_lines] +=
          imported.failed_instances.map { |f| f[:user_name].to_s }.join(MarkusCsv::INVALID_LINE_SEP)
      end
      if !imported.ids.empty? && parsed[:invalid_records].empty?
        parsed[:valid_lines] = I18n.t('upload_success', count: imported.ids.size)
      end
    rescue ActiveRecord::RecordNotUnique => e
      # can trigger on uniqueness constraint validation for :user_name, will invalidate the entire import
      parsed[:invalid_lines] = I18n.t('csv_upload_user_duplicate', user_name: e.message)
    end
    if user_class == Student
      new_user_ids = (imported&.ids || []) - existing_user_ids
      # call create callbacks to make sure grade_entry_students get created
      user_class.where(id: new_user_ids).each(&:create_all_grade_entry_students)
    end
    parsed
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
