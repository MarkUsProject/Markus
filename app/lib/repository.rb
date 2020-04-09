module Repository

  # Configuration for the repository library,
  # which is set via Repository.get_class
  # TODO: Get rid of Repository.conf
 # @CONF = {}
#  def Repository.conf
 #   return @CONF
#  end

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
  class ConnectionError < StandardError; end

  class Conflict < StandardError
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
  # Exception for folders
  class FolderExistsConflict < Conflict
    def to_s
      "#{@path} could not be added - it already exists"
    end
  end

  class FolderDoesNotExistConflict < Conflict
    def to_s
      "#{@path} could not be removed - it is not exist"
    end
  end
  # Exception for folders
  class FolderIsNotEmptyConflict < Conflict
    def to_s
      "#{@path} could not be removed - it is not empty"
    end
  end

  class FileOutOfSyncConflict < Conflict
    def to_s
      return "#{@path} has been updated since you last saw it, and could not be changed"
    end
  end

  class ExportRepositoryAlreadyExists < StandardError; end

  class RepositoryCollision < StandardError; end

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
    def self.create(connect_string, with_hooks: false)
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

    # Static method: returns the shell command to check out a repository or one of its folders
    def self.get_checkout_command(external_repo_url, revision_identifier, group_name, repo_folder=nil)
      raise NotImplementedError, "Repository::get_checkout_command Not yet implemented"
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
      raise NotImplementedError,
            'Repository.get_all_revisions: Not yet implemented'
    end

    # Return a Repository::AbstractRevision for a given revision_identifier
    # if it exists
    def get_revision(revision_identifier)
      raise NotImplementedError,  'Repository.get_revision: Not yet implemented'
    end

    # Return a RepositoryRevision for a given timestamp
    def get_revision_by_timestamp(at_or_earlier_than, path = nil, later_than = nil)
      raise NotImplementedError,  "Repository.get_revision_by_timestamp: Not yet implemented"
    end

    def self.get_full_access_users
      Admin.pluck(:user_name)
    end

    # Gets a list of users with permission to access the repo.
    # All permissions are rw for the time being
    def get_users
      unless Rails.configuration.x.repository.is_repository_admin # are we admin?
        raise NotAuthorityError.new('Unable to get permissions: Not in authoritative mode!')
      end
      repo_name = get_repo_name
      permissions = self.get_all_permissions
      permissions.fetch(repo_name, []) + self.get_full_access_users
    end

    # TODO All permissions are rw for the time being
    def get_permissions(user_name)
      unless Rails.configuration.x.repository.is_repository_admin # are we admin?
        raise NotAuthorityError.new('Unable to get permissions: Not in authoritative mode!')
      end
      unless get_users.include?(user_name)
        raise UserNotFound.new("User #{user_name} not found in this repo")
      end

      Repository::Permission::READ_WRITE
    end

    #Converts a pathname to an absolute pathname
    def expand_path(file_name, dir_string)
      raise NotImplementedError, "Repository.expand_path: Not yet implemented"
    end

    # Updates permissions file unless it is being called from within a
    # block passed to self.update_permissions_after or if it does not
    # read the most up to date data (using self.get_all_permissions)
    #
    # It may not have the most up to date data if another thread calls
    # makes some update to the database and calls self.get_all_permissions
    # while this thread is still processing self.get_all_permissions
    def self.update_permissions
      return unless Rails.configuration.x.repository.is_repository_admin
      Thread.current[:requested?] = true
      unless Thread.current[:permissions_lock].nil?
        # abort if this is being called in a block passed to
        # self.update_permissions_after
        return if Thread.current[:permissions_lock].owned?
      end
      # indicate that this thread is trying to update permissions
      redis = Redis::Namespace.new(Rails.root.to_s)
      redis.set('repo_permissions', Thread.current.object_id)
      # get permissions from the database
      permissions = self.get_all_permissions
      full_access_users = self.get_full_access_users
      # only continue if this was the last thread to get permissions from the database
      if redis.get('repo_permissions')&.to_i == Thread.current.object_id
        __update_permissions(permissions, full_access_users)
      end
      nil
    end

    # Executes a block of code and then updates the permissions file.
    # Also prevents any calls to self.update_permissions or
    # self.update_permissions_after within that block.
    #
    # If only_on_request is true then self.update_permissions will be
    # called after the block only if it would have been called in the
    # yielded block but was prevented
    #
    # This allows us to ensure that the permissions file will only be
    # updated a single time once all relevant changes have been made.
    def self.update_permissions_after(only_on_request: false)
      if Thread.current[:permissions_lock].nil?
        Thread.current[:permissions_lock] = Mutex.new
      end
      Thread.current[:requested?] = false
      if Thread.current[:permissions_lock].owned?
        # if owned by the current thread, yield the block without
        # trying to lock again (which would raise a ThreadError)
        yield
      else
        Thread.current[:permissions_lock].synchronize { yield }
      end
      if !only_on_request || Thread.current[:requested?]
        self.update_permissions
      end
      nil
    end

    # Builds a hash of all repositories and users allowed to access them (assumes all permissions are rw)
    def self.get_all_permissions
      permissions = Hash.new { |h,k| h[k]=[] }
      Assignment.get_repo_auth_records.each do |assignment|
        assignment.valid_groupings.each do |valid_grouping|
          repo_name = valid_grouping.group.repo_name
          accepted_students = valid_grouping.accepted_students.map(&:user_name)
          permissions[repo_name] = accepted_students
        end
      end
      # NOTE: this will allow graders to access the files in the entire repository
      # even if they are the grader for only a single assignment
      graders_info = TaMembership.joins(:user, grouping: :group).pluck(:repo_name, :user_name)
      graders_info.each do |repo_name, user_name|
        permissions[repo_name] << user_name
      end
      permissions
    end

    # '*' which is reserved to indicate all repos when setting permissions
    # TODO: add to this if needed
    def self.reserved_locations
      ['*']
    end

    # Generate and write the the authorization file for all repos.
    def self.__update_permissions(permissions, full_access_users)
      raise NotImplementedError, "Repository.update_permissions: Not yet implemented"
    end

    # Returns a set of file names that are used internally by the repository and are not part of any student submission.
    def self.internal_file_names
      []
    end

    # Exclusive blocking lock using a redis list to ensure that all threads and all processes respect
    # the lock.  If the resource defined by +resource_id+ is locked, the calling thread will wait +timeout+
    # milliseconds, while trying to acquire the lock every +interval+ milliseconds. If the calling thread
    # is able to acquire the lock it will yield, otherwise the passed block will not be executed
    # and a Timeout::Error will be raised.
    #
    # Access to the resource will be given in request order. So if threads a, b, and c all request access to the
    # same resource (in that order), access is guaranteed to be given to a then b then c (in that order).
    #
    # The +namespace+ argument can be given to ensure that two resources with the same resource_id can be treated
    # as separate resources as long as the +namespace+ value is distinct. By default the +namespace+ is the relative
    # root of the current MarkUs instance.
    def self.redis_exclusive_lock(resource_id, namespace: Rails.root.to_s, timeout: 5000, interval: 100)
      redis = Redis::Namespace.new(namespace)
      return yield if redis.lrange(resource_id, -1, -1).first&.to_i == Thread.current.object_id

      # clear any threads that are no longer alive from the queue
      redis.lrange(resource_id, 0, -1).each do |thread_id|
        begin
          thread_obj = ObjectSpace._id2ref(thread_id.to_i)
        rescue TypeError, RangeError
          redis.lrem(resource_id, 0, thread_id)
          next
        end
        unless thread_obj.is_a?(Thread) && thread_obj.alive?
          redis.lrem(resource_id, 0, thread_id)
        end
      end

      redis.lpush(resource_id, Thread.current.object_id) # assume thread ids are unique accross processes as well
      elapsed_time = 0
      begin
        loop do
          return yield if redis.lrange(resource_id, -1, -1).first&.to_i == Thread.current.object_id
          raise Timeout::Error, I18n.t('repo.timeout') if elapsed_time >= timeout

          sleep(interval / 1000.0) # interval is in milliseconds but sleep arg is in seconds
          elapsed_time += interval
        end
      ensure
        redis.lrem(resource_id, -1, Thread.current.object_id)
      end
    end

    private_class_method :__update_permissions

    # Given a subdirectory path, and an already created zip_file, fill the subdirectory
    # within the zip_file with all of its files.
    #
    # If a block is passed to this function, The block will receive a Repository::RevisionFile
    # object as a parameter.
    # The result of the block will be written to the zip file instead of the file content.
    #
    # This can be used to modify the file content before it is written to the zip file.
    def send_tree_to_zip(subdirectory_path, zip_file, zip_name, revision, &block)
      revision.tree_at_path(subdirectory_path, with_attrs: false).each do |path, obj|
        if obj.is_a? Repository::RevisionFile
          file_contents = block_given? ? block.call(obj) : download_as_string(obj)
          zip_file.get_output_stream(File.join(zip_name, path)) do |f|
            f.puts file_contents
          end
        end
      end
    end
  end


  # Exceptions for Revisions
  class RevisionDoesNotExist < StandardError; end
  class RevisionOutOfSyncConflict < Conflict; end

  class AbstractRevision
    attr_reader :revision_identifier, :revision_identifier_ui, :timestamp, :user_id, :comment
    attr_accessor :server_timestamp

    def initialize(revision_identifier)
      raise RevisionDoesNotExist if revision_identifier.nil?

      @revision_identifier = revision_identifier
      @revision_identifier_ui = @revision_identifier
    end

    # Checks if +path+ is a file or directory in this revision of the repository.
    def path_exists?(path)
      raise NotImplementedError, "Revision.path_exists? not yet implemented"
    end

    # Checks if there are changes under +path+ (subdirectories included) due to this revision.
    def changes_at_path?(path)
      raise NotImplementedError, "Revision.changes_at_path? not yet implemented"
    end

    # Returns all the files under +path+ (but not in subdirectories) in this revision of the repository.
    def files_at_path(_path, with_attrs: true)
      raise NotImplementedError, "Revision.files_at_path not yet implemented"
    end

    # Returns all the directories under +path+ (but not in subdirectories) in this revision of the repository.
    def directories_at_path(_path, with_attrs: true)
      raise NotImplementedError, "Revision.directories_at_path not yet implemented"
    end

    # Walks all files and subdirectories starting at +path+ and
    # returns an array of tuples containing [path, revision_object]
    # for every file and directory discovered in this way
    def tree_at_path(_path, with_attrs: true)
      raise NotImplementedError, 'Revision.tree_at_path not yet implemented'
    end
  end

  # Exceptions for Files
  class FileOutOfDate < StandardError; end
  class FileDoesNotExist < StandardError; end
  # Exceptions for Folders
  class FolderDoesNotExist < StandardError; end
  # Exceptions for repo user management
  class UserNotFound < StandardError; end
  class UserAlreadyExistent < StandardError; end
  # raised when trying to modify permissions and repo is not in authoritative mode
  class NotAuthorityError < StandardError; end
  # raised when configuration is wrong
  class ConfigurationError < StandardError; end


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
      @submitted_date = args[:submitted_date]
      @changed = args[:changed]
      @user_id = args[:user_id]
      @mime_type = args[:mime_type]
      @from_revision = from_revision
    end

    attr_accessor :name, :path, :last_modified_revision, :changed, :submitted_date
    attr_accessor :from_revision, :user_id, :mime_type, :last_modified_date

  end # end class File

  class RevisionDirectory

    def initialize(from_revision, args)
      @name = args[:name]
      @path = args[:path]
      @last_modified_revision = args[:last_modified_revision]
      @last_modified_date = args[:last_modified_date]
      @submitted_date = args[:submitted_date]
      @changed = args[:changed]
      @user_id = args[:user_id]
      @from_revision = from_revision
    end

    attr_accessor :name, :path, :last_modified_revision, :changed, :submitted_date
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

    def remove(path, expected_revision_identifier, keep_folder: true)
      @jobs.push(action: :remove, path: path, expected_revision_identifier: expected_revision_identifier,
                 keep_folder: keep_folder)
    end

    def remove_directory(path, expected_revision_identifier, keep_parent_dir: false)
      @jobs.push(action: :remove_directory, path: path, expected_revision_identifier: expected_revision_identifier,
                 keep_parent_dir: keep_parent_dir)
    end

    def replace(path, file_data, mime_type, expected_revision_identifier)
      @jobs.push(action: :replace, path: path, file_data: file_data, mime_type: mime_type, expected_revision_identifier: expected_revision_identifier)
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

  # Gets the configured repository implementation
  def self.get_class
    repo_type = Rails.configuration.x.repository.type
    case repo_type
    when 'git'
      return GitRepository
    when 'mem'
      return MemoryRepository
    when 'svn'
      return SubversionRepository
    else
      raise "Repository implementation not found: #{repo_type}"
    end
  end

end # end module Repository
