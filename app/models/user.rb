include CsvHelper
require 'iconv'
require 'digest' # required for {set,reset}_api_token
require 'base64' # required for {set,reset}_api_token
# required for repository actions
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'repo', 'repository')

# We always assume the following fields exists:
# => :user_name, :last_name, :first_name
# If there are added columns, add the default values to default_values
class User < ActiveRecord::Base
  before_validation :strip_name

  # Group relationships
  has_many :memberships
  has_many :groupings, :through => :memberships
  has_many :notes, :as => :noteable, :dependent => :destroy
  has_many :accepted_memberships, :class_name => 'Membership', :conditions => {:membership_status => [StudentMembership::STATUSES[:accepted], StudentMembership::STATUSES[:inviter]]}

  validates_presence_of     :user_name, :last_name, :first_name
  validates_uniqueness_of   :user_name

  validates_format_of       :type,          :with => /Student|Admin|Ta/
  # role constants
  STUDENT = 'Student'
  ADMIN = 'Admin'
  TA = 'Ta'

  # Authentication constants to be used as return values
  # see self.authenticated? and main_controller for details
  AUTHENTICATE_SUCCESS =      0   # valid username/password combination
  AUTHENTICATE_NO_SUCH_USER = 1   # user does not exist
  AUTHENTICATE_BAD_PASSWORD = 2   # wrong password
  AUTHENTICATE_ERROR =        3   # generic/unknown error
  AUTHENTICATE_BAD_CHAR =     4   # invalid character in username/password
  AUTHENTICATE_BAD_PLATFORM = 5   # external authentication works for *NIX platforms only

  # Verifies if user is allowed to enter MarkUs
  # Returns user object representing the user with the given login.
  def self.authorize(login)
    # fetch login in database to see if it is registered.
    find_by_user_name(login)
  end

  # Authenticates login against its password
  # through a script specified by config VALIDATE_FILE
  def self.authenticate(login, password)
    # Do not allow the following characters in usernames/passwords
    # Right now, this is \n and \0 only, since username and password
    # are delimited by \n and C programs use \0 to terminate strings
    not_allowed_regexp = Regexp.new(/[\n\0]+/)
    if not_allowed_regexp.match(login) || not_allowed_regexp.match(password)
      m_logger.log("User '#{login}' failed to log in. Username/password contained " +
                       'illegal characters', MarkusLogger::ERROR)
      AUTHENTICATE_BAD_CHAR
    else
      # Open a pipe and write to stdin of the program specified by config VALIDATE_FILE.
      # We could read something from the programs stdout, but there is no need
      # for that at the moment (you would do it by e.g. pipe.readlines)

      # External validation is supported on *NIX only
      if RUBY_PLATFORM =~ /(:?mswin|mingw)/ # should match for Windows only
        return AUTHENTICATE_BAD_PLATFORM
      end

      # In general, the external password validation program will return the
      # following codes (other than 0):
      #  1 means no such user
      #  2 means bad password
      #  3 is used for other error exits
      pipe = IO.popen(MarkusConfigurator.markus_config_validate_file, 'w+')
      pipe.puts("#{login}\n#{password}") # write to stdin of markus_config_validate
      pipe.close
      m_logger = MarkusLogger.instance
      case $?.exitstatus
        when 0
          m_logger.log("User '#{login}' logged in.", MarkusLogger::INFO)
          return AUTHENTICATE_SUCCESS
        when 1
          m_logger.log("Login failed. Reason: No such user '#{login}'.", MarkusLogger::ERROR)
          return AUTHENTICATE_NO_SUCH_USER
        when 2
          m_logger.log("Wrong username/password: User '#{login}'.", MarkusLogger::ERROR)
          return AUTHENTICATE_BAD_PASSWORD
        else
          m_logger.log("User '#{login}' failed to log in.", MarkusLogger::ERROR)
          return AUTHENTICATE_ERROR
      end
    end
  end


  #TODO: make these proper associations. They work fine for now but
  # they'll be slow in production
  def active_groupings
    self.groupings.all(:conditions => ['memberships.membership_status != :u',
                                       { :u => StudentMembership::STATUSES[:rejected]}])
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

  # Submission helper methods -------------------------------------------------

  def submission_for(aid)
    grouping = grouping_for(aid)
    if grouping.nil?
      return nil
    end
    grouping.current_submission_used
  end

  # Classlist parsing --------------------------------------------------------
  def self.generate_csv_list(user_list)
     file_out = CsvHelper::Csv.generate do |csv|
       user_list.each do |user|
         # csv format is user_name,last_name,first_name
         # We check for user's section
         # If the user has a section, we had it to the CSV
         if !user.student? or user.section.nil?
           user_array = [user.user_name,user.last_name,user.first_name]
         else
           user_array = [user.user_name,user.last_name,user.first_name, user.section.name]
         end
         csv << user_array
       end
     end
     file_out
  end

  def self.upload_user_list(user_class, user_list, encoding)
    num_update = 0
    result = {}
    result[:invalid_lines] = []  # store lines that were not processed
    # read each line of the file and update classlist
    begin
      if encoding != nil
        user_list = StringIO.new(Iconv.iconv('UTF-8',
                                            encoding,
                                            user_list.read).join)
      end
      User.transaction do
        processed_users = []
        CsvHelper::Csv.parse(user_list,
                             :skip_blanks => true,
                             :row_sep => :auto) do |row|
          # don't know how to fetch line so we concat given array
          next if CsvHelper::Csv.generate_line(row).strip.empty?
          if processed_users.include?(row[0])
            result[:invalid_lines] = I18n.t('csv_upload_user_duplicate',
                                            {:user_name => row[0]})
          else
            if User.add_user(user_class, row).nil?
              result[:invalid_lines] << row.join(',')
            else
              num_update += 1
              processed_users.push(row[0])
            end
          end
        end # end parse
      end
    rescue
        return false
    end
    result[:upload_notice] = "#{num_update} user(s) added/updated."
    result
  end

  def self.add_user(user_class, row)
    # convert each line to a hash with FIELDS as corresponding keys
    # and create or update a user with the hash values
    #return nil if values.length < UPLOAD_FIELDS.length
    user_attributes = {}
    # Loop through the resulting array as key, value pairs

    user_class::CSV_UPLOAD_ORDER.zip(row) do |key, val|
      # append them to the hash that is returned by User.get_default_ta/student_attrs
      # remove the section if the user has one
      if key == :section_name
        if val
          # check if the section already exist
          section = Section.find_or_create_by_name(val)
          user_attributes['section_id'] = section.id
        end
      else
        user_attributes[key] = val
      end
    end

    # Is there already a Student with this User number?
    current_user = user_class.find_or_create_by_user_name(user_attributes[:user_name])
    current_user.attributes = user_attributes

    unless current_user.save
      return nil
    end

    current_user
  end

  # Convenience method which returns a configuration Hash for the
  # repository lib
  def self.repo_config
    # create config
    conf = Hash.new
    conf['IS_REPOSITORY_ADMIN'] = MarkusConfigurator.markus_config_repository_admin?
    conf['REPOSITORY_PERMISSION_FILE'] = MarkusConfigurator.markus_config_repository_permission_file
    return conf
  end

  # Set API key for user model. The key is a
  # SHA2 512 bit long digest, which is in turn
  # MD5 digested and Base64 encoded so that it doesn't
  # include bad HTTP characters.
  #
  # TODO: If we end up
  # using this heavily we should probably let this token
  # expire every X days/hours/weeks. When it does, a new
  # token should be automatically generated.
  def set_api_key
    if self.api_key.nil?
      key = generate_api_key
      md5 = Digest::MD5.new
      md5.update(key)
      # base64 encode md5 hash
      self.api_key = Base64.encode64(md5.to_s).strip
      self.save
    else
      true
    end
  end

  # Resets the api key. Usually triggered, if the
  # old md5 hash has gotten into the wrong hands.
  def reset_api_key
    key = generate_api_key
    md5 = Digest::MD5.new
    md5.update(key)
    # base64 encode md5 hash
    self.api_key = Base64.encode64(md5.to_s).strip
    self.save
  end

  private
  # Create some random, hard to guess SHA2 512 bit long
  # digest.
  def generate_api_key
    digest = Digest::SHA2.new(bitlen=512)
    # generate a unique token
    unique_seed = SecureRandom.hex(20)
    digest.update("#{unique_seed} SECRET! #{Time.zone.now.to_f}").to_s
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
  end

  # Adds read and write permissions for each newly created Admin or Ta user
  def grant_repository_permissions
    # If we're not the repository admin, bail out
    return if(self.student? or !MarkusConfigurator.markus_config_repository_admin?)

    conf = User.repo_config
    repo = Repository.get_class(MarkusConfigurator.markus_config_repository_type,
                                conf)
    repo_names = Group.all.collect do |group|
                   File.join(MarkusConfigurator.markus_config_repository_storage,
                             group.repository_name)
                 end
    repo.set_bulk_permissions(repo_names, {self.user_name => Repository::Permission::READ_WRITE})
  end

  # Revokes read and write permissions for a deleted admin user
  def revoke_repository_permissions
    return if(self.student? or !MarkusConfigurator.markus_config_repository_admin?)

    conf = User.repo_config
    repo = Repository.get_class(MarkusConfigurator.markus_config_repository_type, conf)
    repo_names = Group.all.collect do |group| File.join(MarkusConfigurator.markus_config_repository_storage, group.repository_name) end
    repo.delete_bulk_permissions(repo_names, [self.user_name])
  end

  def maintain_repository_permissions
    return if(self.student? or !MarkusConfigurator.markus_config_repository_admin?)
    if self.user_name_changed?
      conf = User.repo_config
      repo = Repository.get_class(MarkusConfigurator.markus_config_repository_type, conf)
      repo_names = Group.all.collect do |group| File.join(MarkusConfigurator.markus_config_repository_storage, group.repository_name) end
      repo.delete_bulk_permissions(repo_names, [self.user_name_was])
      repo.set_bulk_permissions(repo_names, {self.user_name => Repository::Permission::READ_WRITE})
    end
  end
end
