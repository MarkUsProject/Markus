module Repository

  # Configuration for the repository library,
  # which is set via Repository.get_class
  @CONF = {}
  def Repository.conf
    return @CONF
  end

  # Permission constants for repositories
  class Permission
    if !defined? WRITE  # avoid constant already defined warnings
      WRITE      = 2
    end
    if !defined? READ
      READ       = 4
    end
    if !defined? READ_WRITE
      READ_WRITE = READ + WRITE
    end
    if !defined? ANY
      ANY        = READ # any permission means at least read permission
    end
  end

  # Exceptions for repositories
  class ConnectionError < Exception; end

  class Conflict < Exception
    attr_reader :path
    def initialize(path)
      super()
      @path = path
    end
    def to_s
      return 'There was an unspecified conflict with file ' + @path
    end
  end

  class FileExistsConflict < Conflict
    def to_s
      return "#{@path} could not be added - it already exists in the folder.  If you'd like to overwrite, try replacing the file instead."
    end
  end

  class FileDoesNotExistConflict < Conflict
    def to_s
      return "#{@path} could not be changed - it was deleted since you last saw it"
    end
  end

  class FileOutOfSyncConflict < Conflict
    def to_s
      return "#{@path} has been updated since you last saw it, and could not be changed"
    end
  end

  class ExportRepositoryAlreadyExists < Exception;  end

  class RepositoryCollision < Exception; end

  class AbstractRepository

    # Initializes Object, and verifies connection to the repository back end.
    # This should throw a ConnectionError if we're unable to connect.
    def initialize(connect_string)
      raise NotImplementedError, "Repository.initialize(connect_string): Not yet implemented"
    end

    # Static method: Should report if a repository exists at given location
    def self.repository_exists?(path)
      raise NotImplementedError, "Repository::repository_exists? Not yet implemented"
    end

    # Static method: Opens a repository at given location; returns an
    # AbstractRepository instance
    def self.open(connect_string)
      raise NotImplementedError, "Repository::open Not yet implemented"
    end

    # Static method: Creates a new repository at given location; returns
    # an AbstractRepository instance, with the repository opened.
    def self.create(connect_string)
      raise NotImplementedError, "Repository::create Not yet implemented"
    end

    #Static method: Yields an existing Repository and closes it afterwards
    def self.access(connect_string)
      raise NotImplementedError, "Repository::access Not yet implemented"
    end

    #Static method: Deletes an existing Subversion repository
    def self.delete(connect_string)
      raise NotImplementedError, "Repository::delete Not yet implemented"
    end

    #Closes the repository
    def close
      raise NotImplementedError, "Repository::close Not yet implemented"
    end

    #Tests if the repository is closed
    def closed?
      raise NotImplementedError, "Repository::closed Not yet implemented"
    end

    # Given either an array of, or a single object of class RevisionFile,
    # return a stream of data for the user to download as the file(s).
    def stringify_files(files)
      raise NotImplementedError,  "Repository.download: Not yet implemented"
    end
    alias download_as_string stringify_files

    # Returns a transaction for the provided user and uses comment as the commit message
    def get_transaction(user_id, comment)
      raise NotImplementedError,  "Repository.get_transaction: Not yet implemented"
    end

    # Commits a transaction associated with a repository
    def commit(transaction)
      raise NotImplementedError,  "Repository.commit: Not yet implemented"
    end

    # Returns the latest Repository::AbstractRevision
    def get_latest_revision
      raise NotImplementedError, "Repository.get_latest_revision: Not yet implemented"
    end

    # Returns all revisions
    def get_all_revisions
      raise NotImplementedError, "Repository.get_all_revision: Not yet implemented"
    end

    # Return a Repository::AbstractRevision for a given revision_number
    # if it exists
    def get_revision(revision_number)
      raise NotImplementedError,  "Repository.get_revision: Not yet implemented"
    end

    # Return a RepositoryRevision for a given timestamp
    def get_revision_by_timestamp(timestamp, path = nil)
      raise NotImplementedError,  "Repository.get_revision_by_timestamp: Not yet implemented"
    end

    # Adds a user with a given permission-set to the repository
    def add_user(user_id, permissions)
      raise NotImplementedError,  "Repository.add_user: Not yet implemented"
    end

    # Removes user permissions for read & write access to the repository
    def remove_user(user_id)
      raise NotImplementedError,  "Repository.remove_user: Not yet implemented"
    end

    # Gets a list of users with permissions in question on the repository
    #   use "Repository::Permission::ANY" to get a list of all users with any permissions
    #   i.e. all users with at least read permissions
    def get_users(permissions)
      raise NotImplementedError, "Repository.get_users: Not yet implemented"
    end

    # Gets permissions for a particular user
    def get_permissions(user_id)
      raise NotImplementedError, "Repository.get_permissions: Not yet implemented"
    end

    # Sets permissions for a particular user
    def set_permissions(user_id, permissions)
      raise NotImplementedError, "Repository.set_permissions: Not yet implemented"
    end

    #Converts a pathname to an absolute pathname
    def expand_path(file_name, dir_string)
      raise NotImplementedError, "Repository.expand_path: Not yet implemented"
    end

    # Static method on Repository to set permissions on a set of users across a series
    # of group repositories.
    # user_id_permissions_map is a hash in the form of:
    # {user_id => Repository::Permissions::READ, user_id =>....}
    #
    # set_bulk_permissions will clobber pre-existing permissions, and automatically
    # add_user to a repository permission set.
    #
    # set_bulk_permissions is commonly used when setting permissions for _many_
    # repositories
    #
    def self.set_bulk_permissions(groups, user_id_permissions_map)
      raise NotImplementedError, "Repository.set_bulk_permissions: Not yet implemented"
    end

    # Static method on Repository to remove permissions on an Array of users across
    # a series of group repositories
    # user_ids is an Array of user_ids
    #
    def self.delete_bulk_permissions(groups, user_ids)
      raise NotImplementedError, "Repository.delete_bulk_permissions: Not yet implemented"
    end

  end


  # Exceptions for Revisions
  class RevisionDoesNotExist < Exception; end
  class RevisionOutOfSyncConflict < Conflict; end

  class AbstractRevision
    attr_reader :revision_number, :timestamp, :user_id, :comment

    def initialize(revision_number)
      @revision_number = revision_number
    end

    def path_exists?(path)
      raise NotImplementedError, "Revision.path_exists? not yet implemented"
    end

    # Return all of the files in this repository at the root directory
    def files_at_path(path)
      raise NotImplementedError, "Revision.files_at_path not yet implemented"
    end

    def directories_at_path(path)
      raise NotImplementedError, "Revision.directories_at_path not yet implemented"
    end

    def changed_files_at_path(path)
      raise NotImplementedError, "Revision.changed_files_at_path not yet implemented"
    end

  end

  # Exceptions for Files
  class FileOutOfDate < Exception; end
  class FileDoesNotExist < Exception; end

  # Exceptions for repo user management
  class UserNotFound < Exception; end
  class UserAlreadyExistent < Exception; end
  # raised when trying to modify permissions and repo is not in authoritative mode
  class NotAuthorityError < Exception; end
  # raised when configuration is wrong
  class ConfigurationError < Exception; end


  #################################################
  #  Class File:
  #        Files stored in a Revision
  #################################################
  class RevisionFile

    def initialize(from_revision, args)
      @name = args[:name]
      @path = args[:path]
      @last_modified_revision = args[:last_modified_revision]
      @last_modified_date = args[:last_modified_date]
      @changed = args[:changed]
      @user_id = args[:user_id]
      @mime_type = args[:mime_type]
      @from_revision = from_revision
    end

    attr_accessor :name, :path, :last_modified_revision, :changed
    attr_accessor :from_revision, :user_id, :mime_type, :last_modified_date

  end # end class File

  class RevisionDirectory

    def initialize(from_revision, args)
      @name = args[:name]
      @path = args[:path]
      @last_modified_revision = args[:last_modified_revision]
      @last_modified_date = args[:last_modified_date]
      @changed = args[:changed]
      @user_id = args[:user_id]
      @from_revision = from_revision
    end

    attr_accessor :name, :path, :last_modified_revision, :changed
    attr_accessor :from_revision, :user_id, :last_modified_date

  end # end class File


  class Transaction

    attr_reader :user_id, :comment, :jobs, :conflicts

    def initialize(user_id, comment)
      @user_id = user_id
      @comment = comment
      @jobs = []
      @conflicts = []
    end

    def add_path(path)
      @jobs.push(action: :add_path, path: path)
    end

    def add(path, file_data=nil, mime_type=nil)
      @jobs.push(action: :add, path: path, file_data: file_data, mime_type: mime_type)
    end

    def remove(path, expected_revision_number)
      @jobs.push(action: :remove, path: path, expected_revision_number: expected_revision_number)
    end

    def replace(path, file_data, mime_type, expected_revision_number)
      @jobs.push(action: :replace, path: path, file_data: file_data, mime_type: mime_type, expected_revision_number: expected_revision_number)
    end

    def add_conflict(conflict)
      @conflicts.push(conflict)
    end

    def conflicts?
      @conflicts.size > 0
    end

    def has_jobs?
      @jobs.size > 0
    end

  end

  # A repository factory
  require_dependency File.join(File.dirname(__FILE__), 'memory_repository')
  require_dependency File.join(File.dirname(__FILE__), 'subversion_repository')
  require_dependency File.join(File.dirname(__FILE__), 'git_repository')
  # Returns a repository class of the requested type,
  # which implements AbstractRepository

  # get_class takes a hash as a second argument. This hash must contain the following
  # keys with corresponding values (other configuration is ignored):
  #  REPOSITORY_IS_ADMIN:  This flag indicates if we have admin privileges.
  #                        If set to false, the repository relies on a third party
  #                        to create repositories and manage its permissions.
  #  REPOSITORY_PERMISSION_FILE: This is the absolute path to the permission file
  #                              of repositories.
  def Repository.get_class(repo_type, conf_hash)
    if conf_hash.nil?
      raise ConfigurationError.new("Configuration must not be nil")
    end
    # configure Repository module first; as of now, we require the following constants
    # to be defined
    config_keys = ['REPOSITORY_PERMISSION_FILE', 'REPOSITORY_STORAGE', 'IS_REPOSITORY_ADMIN']
    @CONF = Hash.new # important(!) reset config
    conf_hash.each do |k,v|
      if config_keys.include?(k)
        @CONF[k.to_sym] = v
      end
    end
    # Check if configuration is in order
    config_keys.each do |c|
      if Repository.conf[c.to_sym].nil?
        raise ConfigurationError.new("Required config '#{c}' not set")
      end
    end

    case repo_type
      when "svn"
        return SubversionRepository
      when "memory"
        return MemoryRepository
      when "git"
        return GitRepository
      else
        raise "Repository implementation not found: #{repo_type}"
    end
  end

end # end module Repository
