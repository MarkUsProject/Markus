require File.join(File.dirname(__FILE__), 'repository')
module Repository

  # Implements AbstractRepository for memory repositories
  # It implements the following paradigm:
  #   1. Repositories are created by using MemoryRepository.create()
  #   2. Existing repositories are opened by using either SubversionRepository.open()
  #      or SubversionRepository.new()
  class MemoryRepository < Repository::AbstractRepository

    # class variable which knows of all memory repositories
    #    key (location), value (reference to repo)
    @@repositories = {}

    #############################################################
    #   A MemoryRepository instance holds the following variables
    #     - current_revision
    #     - revision_history
    #     - timestamps_revisions
    #############################################################

    # Constructor: Connects to an existing Memory
    # repository; Note: A repository has to be created using
    # MemoryRepository.create(), if it is not yet existent
    # Generally: Do not(!) call it with 2 parameters, use MemoryRepository.create() instead!
    def initialize(location)

      # variables
      @users = {}                                 # hash of users (key) with corresponding permissions (value)
      @current_revision = MemoryRevision.new(0)   # the latest revision (we start from 0)
      @revision_history = []                      # a list (array) of old revisions (i.e. < @current_revision)
      # mapping (hash) of timestamps and revisions
      @timestamps_revisions = {}
      # push first timestamp-revision mapping
      @timestamps_revisions[Marshal.dump(
        Marshal.load(Marshal.dump(Time.now)))] = @current_revision
      @repository_location = location
      @opened = true


      if MemoryRepository.repository_exists?(location)
        raise RepositoryCollision.new("There is already a repository at #{location}")
      end
      @@repositories[location] = self             # push new MemoryRepository onto repository list

    end

    # Checks if a memory repository exists at 'path'
    def self.repository_exists?(path)
      @@repositories.each do |location, repo|
        if path == location
          return true
        end
      end
      return false
    end

    # Open repository at specified location
    def self.open(location)
      if !self.repository_exists?(location)
        raise "Could not open repository at location #{location}"
      end
      return @@repositories[location] # return reference in question
    end

    # Creates memory repository at "virtual" location (they are identifiable by location)
    def self.create(location)
      if !MemoryRepository.repository_exists?(location)
        MemoryRepository.new(location) # create a repository if it doesn't exist
      end
      return true
    end

    # Static method: Deletes an existing memory repository
    def self.delete(repo_path)
      @@repositories.delete(repo_path)
    end

    # Destroys all repositories
    def self.purge_all
      @@repositories = {}
    end

    # Given either an array of, or a single object of class RevisionFile,
    # return a stream of data for the user to download as the file(s).
    def stringify_files(files)
      is_array = files.kind_of? Array
      if (!is_array)
        files = [files]
      end
      files.collect! do |file|
        if (!file.kind_of? Repository::RevisionFile)
          raise TypeError.new("Expected a Repository::RevisionFile")
        end
        rev = get_revision(file.from_revision)
        content = rev.files_content[file.to_s]
        if content.nil?
          raise FileDoesNotExistConflict.new(File.join(file.path, file.name))
        end
        content # spews out content to be collected (Ruby collect!() magic) :-)
      end
      if (!is_array)
        return files.first
      else
        return files
      end
    end
    alias download_as_string stringify_files

    def get_transaction(user_id, comment="")
      if user_id.nil?
        raise "Expected a user_id (Repository.get_transaction(user_id))"
      end
      return Repository::Transaction.new(user_id, comment)
    end

    def commit(transaction)
      jobs = transaction.jobs
      # make a deep copy of current revision
      new_rev = copy_revision(@current_revision)
      new_rev.user_id = transaction.user_id # set commit-user for new revision
      jobs.each do |job|
        case job[:action]
        when :add_path
          begin
            new_rev = make_directory(new_rev, job[:path])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :add
          begin
            new_rev = add_file(new_rev, job[:path], job[:file_data], job[:mime_type])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :remove
          begin
            new_rev = remove_file(new_rev, job[:path], job[:expected_revision_number])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :replace
          begin
            new_rev = replace_file_content(new_rev, job[:path], job[:file_data], job[:mime_type], job[:expected_revision_number])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        end
      end

      if transaction.conflicts?
        return false
      end

      # everything went fine, so push old revision to history revisions,
      # make new_rev the latest one and create a mapping for timestamped
      # revisions
      timestamp = Time.now
      new_rev.timestamp = timestamp
      @revision_history.push(@current_revision)
      @current_revision = new_rev
      @current_revision.__increment_revision_number() # increment revision number
      @timestamps_revisions[Marshal.dump(
        Marshal.load(Marshal.dump(timestamp)))] = @current_revision
      @@repositories[@repository_location] = self
      return true
    end

    # Returns the latest revision number (as a RepositoryRevision object)
    def get_latest_revision
      return @current_revision
    end

    # Return a RepositoryRevision for a given rev_num (int)
    def get_revision(rev_num)
      if (@current_revision.revision_number == rev_num)
        return @current_revision
      end
      @revision_history.each do |revision|
        if (revision.revision_number == rev_num)
          return revision
        end
      end
      # revision with the specified revision number does not exist,
      # so raise error
      raise RevisionDoesNotExist
    end

    # Return a RepositoryRevision for a given timestamp
    def get_revision_by_timestamp(timestamp, path = nil)
      if !timestamp.kind_of?(Time)
        raise "Was expecting a timestamp of type Time"
      end
      return get_revision_number_by_timestamp(timestamp, path)
    end

    # Adds a user to the repository and grants him/her the provided permissions
    def add_user(user_id, permissions)
      if @users.key?(user_id)
        raise UserAlreadyExistent.new(user_id +" exists already")
      end
      @users[user_id] = permissions
    end

    # Semi-private - used by the bulk permissions assignments
    def has_user?(user_id)
      return @users.key?(user_id)
    end

    # Removes a user from from the repository
    def remove_user(user_id)
      if !@users.key?(user_id)
        raise UserNotFound.new(user_id + " not found")
      end
      @users.delete(user_id)
    end

    # Gets a list of users with AT LEAST the provided permissions.
    # Returns nil if there aren't any.
    def get_users(permissions)
      result_list = []
      @users.each do |user, perm|
        if perm >= permissions
          result_list.push(user)
        end
      end
      if !result_list.empty?
        return result_list
      else
        return nil
      end
    end

    # Sets permissions for the provided user
    def set_permissions(user_id, permissions)
      if !@users.key?(user_id)
        raise UserNotFound.new(user_id + " not found")
      end
      @users[user_id] = permissions
    end

    # Gets permissions for a given user
    def get_permissions(user_id)
      if !@users.key?(user_id)
        raise UserNotFound.new(user_id + " not found")
      end
      return @users[user_id]
    end

    # Set permissions for many repositories
    def self.set_bulk_permissions(repo_names, user_id_permissions_map)
      repo_names.each do |repo_name|
        repo = self.open(repo_name)
        user_id_permissions_map.each do |user_id, permissions|
          if(!repo.has_user?(user_id))
            repo.add_user(user_id, permissions)
          else
            repo.set_permissions(user_id, permissions)
          end
        end
      end
      return true
    end

    # Delete permissions for many repositories
    def self.delete_bulk_permissions(repo_names, user_ids)
      repo_names.each do |repo_name|
        repo = self.open(repo_name)
        user_ids.each do |user_id|
          if(repo.has_user?(user_id))
            repo.remove_user(user_id)
          end
        end
      end
      return true
    end

    # Static method: Yields an existing Memory repository and closes it afterwards
    def self.access(connect_string)
      repository = self.open(connect_string)
      yield repository
      repository.close
    end

    # Closes the repository.
    # This does nothing except set a proper value for the closed? function
    # It is not important to close memory repositories (is it possible?)
    def close
      @opened = false
    end

    # Resturns whether or not the repository is closed.
    # This will return a value corresponding to whether the open or close functions
    # have been called but is otherwise meaningless in a MemoryRepository
    def closed?
      return !@opened
    end

    # Converts a pathname to an absolute pathname
    def expand_path(file_name, dir_string = "/")
      expanded = File.expand_path(file_name, dir_string)
      if RUBY_PLATFORM =~ /(:?mswin|mingw)/ #only if the platform is Windows
        expanded = expanded[2..-1]#remove the drive letter ('D:')
      end
      return expanded
    end

    private
    # Creates a directory as part of the provided revision
    def make_directory(rev, full_path)
      if rev.path_exists?(full_path)
        raise FileExistsConflict # raise conflict if path exists
      end
      dir = RevisionDirectory.new(rev.revision_number, {
        name: File.basename(full_path),
        path: File.dirname(full_path),
        last_modified_revision: rev.revision_number,
        last_modified_date: Time.now,
        changed: true,
        user_id: rev.user_id
      })
      rev.__add_directory(dir)
      return rev
    end

    # Adds a file into the provided revision
    def add_file(rev, full_path, content, mime_type="text/plain")
      if file_exists?(rev, full_path)
        raise FileExistsConflict.new(full_path)
      end
      # file does not exist, so add it
      file = RevisionFile.new(rev.revision_number, {
        name: File.basename(full_path),
        path: File.dirname(full_path),
        last_modified_revision: rev.revision_number,
        changed: true,
        user_id: rev.user_id,
        last_modified_date: Time.now
      })
      rev.__add_file(file, content)
      return rev
    end

    # Replaces file content of a file already existent in a revision
    def replace_file_content(rev, full_path, file_content, mime_type, expected_revision_int)
      if !file_exists?(rev, full_path)
        raise Repository::FileDoesNotExistConflict.new(full_path)
      end
      # replace content of file in question
      act_rev = get_latest_revision()
      if (act_rev.revision_number != expected_revision_int)
        raise Repository::FileOutOfSyncConflict.new(full_path)
      end
      files_list = rev.files_at_path(File.dirname(full_path))
      rev.__replace_file_content(files_list[File.basename(full_path)], file_content)
      return rev
    end

    # Removes a file from the provided revision
    def remove_file(rev, full_path, expected_revision_int)
      if !file_exists?(rev, full_path)
        raise Repostiory::FileDoesNotExistConflict.new(full_path)
      end
      act_rev = get_latest_revision()
      if (act_rev.revision_number != expected_revision_int)
        raise Repository::FileOutOfSyncConflict.new(full_path)
      end
      filename = File.basename(full_path)
      path = File.dirname(full_path)
      files_set = rev.files_at_path(path)
      rev.files.delete_at(rev.files.index(files_set[filename])) # delete file, but keep contents
      return rev
    end

    # Creates a deep copy of the provided revision, all files will have their changed property
    # set to false; does not create a deep copy the contents of files
    def copy_revision(original)
      # we only copy the RevisionFile/RevisionDirectory entries
      new_revision = MemoryRevision.new(original.revision_number)
      new_revision.user_id = original.user_id
      new_revision.comment = original.comment
      new_revision.files_content = {}
      new_revision.timestamp = original.timestamp
      # copy files objects
      original.files.each do |object|
        if object.instance_of?(RevisionFile)
          new_object = RevisionFile.new(object.from_revision, {
            name: object.name,
            path: object.path,
            last_modified_revision: object.last_modified_revision,
            changed: false, # for copies, set this to false
            user_id: object.user_id,
            last_modified_date: object.last_modified_date
          })
          new_revision.files_content[new_object.to_s] = original.files_content[object.to_s]
        else
          new_object = RevisionDirectory.new(object.from_revision, {
            name: object.name,
            path: object.path,
            last_modified_revision: object.last_modified_revision,
            last_modified_date: object.last_modified_date,
            changed: false, # for copies, set this to false
            user_id: object.user_id
          })
        end
        new_revision.files.push(new_object)
      end
      return new_revision # return the copy
    end

    def file_exists?(rev, full_path)
      filename = File.basename(full_path)
      path = File.dirname(full_path)
      curr_files = rev.files_at_path(path)
      if !curr_files.nil?
        curr_files.each do |f, object|
          if f == filename
            return true
          end
        end
      end
      return false
    end

    # gets the "closest matching" revision from the revision-timestamp
    # mapping
    def get_revision_number_by_timestamp(wanted_timestamp, path = nil)
      if @timestamps_revisions.empty?
        raise "No revisions, so no timestamps."
      end

      all_timestamps_list = []
      remaining_timestamps_list = []
      @timestamps_revisions.keys().each do |time_dump|
        all_timestamps_list.push(Marshal.load(time_dump))
        remaining_timestamps_list.push(Marshal.load(time_dump))
      end

      # find closest matching timestamp
      mapping = {}
      first_timestamp_found = false
      old_diff = 0
      # find first valid revision
      all_timestamps_list.each do |best_match|
        remaining_timestamps_list.shift()
        old_diff = wanted_timestamp - best_match
        mapping[old_diff.to_s] = best_match
        if path.nil? || (!path.nil? && @timestamps_revisions[Marshal.dump(best_match)].revision_at_path(path))
          first_timestamp_found = true
          break
        end
      end

      # find all other valid revision
      remaining_timestamps_list.each do |curr_timestamp|
        new_diff = wanted_timestamp - curr_timestamp
        mapping[new_diff.to_s] = curr_timestamp
        if path.nil? || (!path.nil? && @timestamps_revisions[Marshal.dump(curr_timestamp)].revision_at_path(path))
          if(old_diff <= 0 && new_diff <= 0) ||
            (old_diff <= 0 && new_diff > 0) ||
            (new_diff <= 0 && old_diff > 0)
            old_diff = [old_diff, new_diff].max
          else
            old_diff = [old_diff, new_diff].min
          end
        end
      end

      if first_timestamp_found
        wanted_timestamp = mapping[old_diff.to_s]
        return @timestamps_revisions[Marshal.dump(wanted_timestamp)]
      else
        return @current_revision
      end
    end

  end # end class MemoryRepository

  # Class responsible for storing files in and retrieving files
  # from memory
  class MemoryRevision < Repository::AbstractRevision

    # getter/setters for instance variables
    attr_accessor :files, :changed_files, :files_content, :user_id, :comment, :timestamp

    # Constructor
    def initialize(revision_number)
      super(revision_number)
      @files = []           # files in this revision (<filename> <RevisionDirectory/RevisionFile>)
      @files_content = {}   # hash: keys => RevisionFile object, value => content
      @user_id = "dummy_user_id"     # user_id, who created this revision
      @comment = "commit_message" # commit-message for this revision
    end

    # Returns true if and only if path exists in files and path is a directory
    def path_exists?(path)
      if path == "/"
        return true # the root in a repository always exists
      end
      @files.each do |object|
        object_fqpn = File.join(object.path, object.name) # fqpn is: fully qualified pathname :-)
        if object_fqpn == path
          return true
        end
      end
      return false
    end

    # Return all of the files in this repository at the root directory
    def files_at_path(path="/")
      return Hash.new if @files.empty?
      return files_at_path_helper(path)
    end

    # Return true if there was files submitted at the desired path for the revision
    def revision_at_path(path)
      return false if @files.empty?
      return revision_at_path_helper(path)
    end

    def directories_at_path(path="/")
      return Hash.new if @files.empty?
      return files_at_path_helper(path, false, RevisionDirectory)
    end

    def changed_files_at_path(path)
      return files_at_path_helper(path, true)
    end

    # Not (!) part of the AbstractRepository API:
    # A simple helper method to be used to add files to this
    # revision
    def __add_file(file, content="")
      @files.push(file)
      if file.instance_of?(RevisionFile)
        @files_content[file.to_s] = content
      end
    end

    # Not (!) part of the AbstractRepository API:
    # A simple helper method to be used to replace the
    # content of a file
    def __replace_file_content(file, new_content)
      if file.instance_of?(RevisionFile)
        @files_content[file.to_s] = new_content
      else
        raise "Expected file to be of type RevisionFile"
      end
    end

    # Not (!) part of the AbstractRepository API:
    # A simple helper method to be used to add directories to this
    # revision
    def __add_directory(dir)
      __add_file(dir)
    end

    # Not (!) part of the AbstractRepository API:
    # A simple helper method to be used to increment the revision number
    def __increment_revision_number
      @revision_number += 1
    end

    private


    def files_at_path_helper(path="/", only_changed=false, type=RevisionFile)
      # Automatically append a root slash if not supplied
      result = Hash.new(nil)
      @files.each do |object|
        alt_path = ""
        if object.path == '.'
          alt_path = '/'
        elsif object.path != '/'
          alt_path = '/' + object.path
        end
        git_path = object.path + '/'
        if object.instance_of?(type) && (object.path == path ||
            alt_path == path || git_path == path)
          if (!only_changed)
            object.from_revision = @revision_number # set revision number
            result[object.name] = object
          else
            if object.changed
              object.from_revision = @revision_number # reset revision number
              result[object.name] = object
            end
          end
        end
      end
      return result
    end

    # Find if the revision contains files at the path
    def revision_at_path_helper(path)
      # Automatically append a root slash if not supplied
      @files.each do |object|
        alt_path = ""
        if object.path != '/'
          alt_path = object.path + '/'
        end
        if (object.path == path || alt_path == path)
          if (object.from_revision + 1) == @revision_number
            return true
          end
        end
      end
      return false
    end

  end # end class MemoryRevision

end # end Repository module
