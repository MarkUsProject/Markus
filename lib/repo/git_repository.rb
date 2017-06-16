require 'rugged'
require 'digest/md5'

require File.join(File.dirname(__FILE__),'repository') # load repository module

module Repository

  # Implements AbstractRepository for Git repositories
  # It implements the following paradigm:
  #   1. Repositories are created by using ???
  #   2. Existing repositories are opened by using either ???
  class GitRepository < Repository::AbstractRepository

    # Constructor: Connects to an existing Git
    # repository, using Ruby bindings; Note: A repository has to be
    # created using GitRepository.create(), if it is not yet existent
    def initialize(connect_string)

      # Check if configuration is in order
      if MarkusConfigurator.markus_config_repository_admin?.nil?
        raise ConfigurationError.new(
            "Required config 'IS_REPOSITORY_ADMIN' not set")
      end
      if MarkusConfigurator.markus_config_repository_storage.nil?
        raise ConfigurationError.new(
            "Required config 'REPOSITORY_STORAGE' not set")
      end
      if MarkusConfigurator.markus_config_repository_permission_file.nil?
        raise ConfigurationError.new(
            "Required config 'REPOSITORY_PERMISSION_FILE' not set")
      end
      begin
        super(connect_string) # dummy call to super
      rescue NotImplementedError; end
      @repos_path = connect_string
      @closed = false
      @repos_admin = MarkusConfigurator.markus_config_repository_admin?
      if GitRepository.repository_exists?(@repos_path)
        @repos = Rugged::Repository.new(@repos_path)
        # make sure working directory is up-to-date
        @repos.fetch('origin')
        @repos.reset('master', :hard) # TODO this shouldn't be necessary, but something is messing up the repo
        @repos.reset('origin/master', :hard) # align to whatever is in origin/master
      else
        raise "Repository does not exist at path \"#{@repos_path}\""
      end
    end

    def self.do_commit(repo, author, message)
      index = repo.index
      commit_tree = index.write_tree(repo)
      index.write
      commit_author = {email: 'markus@markus.com', name: author, time: Time.now}
      commit_options = {
          author: commit_author,
          committer: commit_author,
          message: message,
          tree: commit_tree,
          parents: repo.empty? ? [] : [repo.head.target].compact, # compact in case target returns nil? (suggested upstream)
          update_ref: 'HEAD'
      }
      Rugged::Commit.create(repo, commit_options)
    end

    def self.do_commit_and_push(repo, author, message)
      GitRepository.do_commit(repo, author, message)
      repo.push('origin', ['refs/heads/master'])
    end

    # Static method: Creates a new Git repository at
    # location 'connect_string'
    def self.create(connect_string)
      if GitRepository.repository_exists?(connect_string)
        raise RepositoryCollision.new(
                "There is already a repository at #{connect_string}")
      end
      if File.exists?(connect_string)
        raise IOError.new("Could not create a repository at #{connect_string}:
                          some directory with same name exists already")
      end

      # Repo is created bare, then clone it in the repository storage location
      repo_path, sep, repo_name = connect_string.rpartition(File::SEPARATOR)
      bare_path = File.join(repo_path, 'bare', "#{repo_name}.git")
      Rugged::Repository.init_at(bare_path, :bare)
      repo = Rugged::Repository.clone_at(bare_path, connect_string)

      # Do an initial commit with a README.md file.
      readme_path = File.join(connect_string, 'README.md')
      File.open(readme_path, 'w') do |readme|
        readme.write('Initial commit.')
      end
      oid = Rugged::Blob.from_workdir(repo, 'README.md')
      repo.index.add(path: 'README.md', oid: oid, mode: 0100644)
      GitRepository.do_commit_and_push(repo, 'Markus', 'Initial readme commit.')

      true
    end

    # Static method: Opens an existing Git repository
    # at location 'connect_string'
    def self.open(connect_string)
      repo = GitRepository.new(connect_string)
    end

    # static method that should yield to a git repo and then close it
    def self.access(connect_string)
      repo = self.open(connect_string)
      yield repo
    end

    # static method that deletes the git repo
    # rm everything? or only .git?
    def self.delete(repo_path)
      #repo = Rugged::Repository.new(repo_path)
      #ref = Rugged::Reference.lookup(repo, "refs/heads/master")
      #ref.delete!
      FileUtils.rm_rf(repo_path)
    end

    # Given a OID of a file from a Rugged::Repository lookup, return the blob
    # object of the file itself.
    def get_blob(oid)
      @repos.lookup(oid)
    end

    # Exports git repo to a new folder (clone repository)
    # If a filepath is given, the repo_dest_dir needs to point to a file, and
    # all the repository on that path need to exist, or the export will fail.
    # Exports git repo to a new folder (clone repository)
    # If a filepath is given, the repo_dest_dir needs to point to a file, and
    # all the repository on that path need to exist, or the export will fail.
    # if export means exporting repo as zip/tgz git-ruby library should be used
    def export(repo_dest_dir, filepath = nil)

      # Case 1: clone all the repo to repo_dest_dir
      if(filepath.nil?)
        # Raise an error if the destination repository already exists
        if (File.exists?(repo_dest_dir))
          raise(ExportRepositoryAlreadyExists,
                'Exported repository already exists')
        end

        repo = Rugged::Repository.clone_at(@repos_path, repo_dest_dir)
      else
        # Case 2: clone a file to a folder
        # Raise an error if the destination file already exists
        if (File.exists?(repo_dest_dir))
          raise(ExportRepositoryAlreadyExists,
                'Exported file already exists')
        end
        FileUtils.cp(get_repos_workdir + filepath, repo_dest_dir)
        return true
      end

    end

    #  Converts a pathname to an absolute pathname
    def expand_path(file_name, dir_string = '/')
      expanded = File.expand_path(file_name, dir_string)
      if RUBY_PLATFORM =~ /(:?mswin|mingw)/ #only if the platform is Windows
        expanded = expanded[2..-1]#remove the drive letter
      end
      expanded
    end

    def self.closable?
      # return if the git library supports close,
      # probably going to need to be a dumby method
    end

    def close
      # closes the git repo
      @repos.close
      @closed = true
    end

    def closed?
      # checks if the repo is closed
      return @closed
    end

    def get_repos
      # Get rugged repository from GitRepository
      return @repos
    end

    def get_repos_workdir
      # Get working directory of the repository
      # workdir = path/to/my/repository/
      return @repos.workdir
    end

    def get_repos_path
      # Get the repository's .git folder
      # path = path/to/my/repository/.git
      return @repos.path
    end

    # Gets the repository name
    def get_repo_name
      @repos_path.rpartition(File::SEPARATOR)[2]
    end

    # Given a File object, perform a lookup for the Rugged::Tree
    # object which contains the directory information for the
    # folder where this file resides, then return the specific
    # file contents that we are interested in.
    def stringify(file)
      revision = get_revision(file.from_revision)
      blob = revision.find_object_at_path(file.path)

      # From the returned Tree blob, find the file in the collection
      blob.entries.each do |file_entry|
        if file_entry[:name] == file.name
          return get_blob(file_entry[:oid]).content
        end
      end
    end
    alias download_as_string stringify # create alias

    # Static method: Reports if a Git repository exists.
    # Done in a similarly hacky method as the git side.
    # TODO - find a better way to do this.
    def self.repository_exists?(repos_path)
      repos_meta_files_exist = false
      if File.exist?(File.join(repos_path, '.git/config'))
        if File.exist?(File.join(repos_path, '.git/description'))
          if File.exist?(File.join(repos_path, '.git/HEAD'))
            repos_meta_files_exist = true
          end
        end
      end
      return repos_meta_files_exist
    end

    def get_revision_number(hash)
      # This functions walks down git log and counts the steps from beginning
      # to get the revision number.
      walker = Rugged::Walker.new(@repos)
      walker.sorting(Rugged::SORT_DATE | Rugged::SORT_REVERSE)
      walker.push(hash)
      start = 0
      walker.each do |commit|
        start += 1
        break if commit.oid == hash
      end
      return start
    end

    # Returns a Repository::SubversionRevision instance
    # holding the latest Subversion repository revision
    # number
    def get_latest_revision
      return get_revision(latest_revision_number)
    end

    # Returns hash wrapped
    # as a Git instance
    def get_revision(revision_number)
      return Repository::GitRevision.new(revision_number, self)
    end

    def get_all_revisions
      youngest_revision = latest_revision_number
      log = []
      (1..youngest_revision).each do |num|
        log.push(Repository::GitRevision.new(num, self))
      end
      return log
    end

    def get_revision_by_timestamp(target_timestamp, _path = nil)
      # returns a Git instance representing the revision at the
      # current timestamp, should be a ruby time stamp instance
      walker = Rugged::Walker.new(self.get_repos)
      walker.push(self.get_repos.head.target)
      walker.each do |c|
        if c.time <= target_timestamp
          @revision_number = get_revision_number(c)
          return get_revision(@revision_number)
        end
      end
      # If no revision number was found, display the latest revision
      # with an error message
      raise 'No revision found before supplied timestamp.'
    end

    # Returns a Repository::TransAction object, to work with. Do operations,
    # like 'add', 'remove', etc. on the transaction instead of the repository
    def get_transaction(user_id, comment = '')
      if user_id.nil?
        raise 'Expected a user_id (Repository.get_transaction(user_id))'
      end
      return Repository::Transaction.new(user_id, comment)
    end

    def commit(transaction)
      # Carries out actions on a Git repository stored in
      # 'transaction'. In case of certain conflicts corresponding
      # Repositor::Conflict(s) are added to the transaction object
      jobs = transaction.jobs

      jobs.each do |job|
        case job[:action]
        when :add_path
          begin
            make_directory(job[:path])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :add
          begin
            add_file(job[:path], job[:file_data], transaction.user_id)
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :remove
          begin
            remove_file(job[:path], transaction.user_id,
                        job[:expected_revision_number])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :replace
          begin
            replace_file(job[:path], job[:file_data], transaction.user_id,
                         job[:expected_revision_number])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        end
      end

      if transaction.conflicts?
        return false
      end
      return true
    end

    # Gets a list of users with AT LEAST the provided permissions.
    # Returns nil if there aren't any.
    # TODO All permissions are rw for the time being, so the provided permissions are not really used
    def get_users(permissions)

      unless @repos_admin # are we admin?
        raise NotAuthorityError.new('Unable to get permissions: Not in authoritative mode!')
      end
      repo_name = get_repo_name
      permissions = AbstractRepository.get_all_permissions
      users = permissions[repo_name]

      users
    end

    # TODO All permissions are rw for the time being
    def get_permissions(user_name)

      unless @repos_admin # are we admin?
        raise NotAuthorityError.new('Unable to get permissions: Not in authoritative mode!')
      end
      begin
        user = User.find_by(user_name: user_name)
      rescue RecordNotFound
        raise UserNotFound.new("User #{user_name} does not exist")
      end
      if user.admin? or user.ta?
        return Repository::Permission::READ_WRITE
      end
      unless get_users(Repository::Permission::ANY).include?(user_name)
        raise UserNotFound.new("User #{user_name} not found in this repo")
      end

      Repository::Permission::READ_WRITE
    end

    # Generate all the permissions for students for all groupings in all assignments.
    # This is done as a single operation to mirror the SVN repo code. We found
    # a substantial performance improvement by writing the auth file only once in the SVN case.
    def self.__set_all_permissions

      # Check if configuration is in order
      if MarkusConfigurator.markus_config_repository_admin?.nil?
        raise ConfigurationError.new(
            "Required config 'IS_REPOSITORY_ADMIN' not set")
      end
      if MarkusConfigurator.markus_config_repository_permission_file.nil?
        raise ConfigurationError.new(
            "Required config 'REPOSITORY_PERMISSION_FILE' not set")
      end
      # If we're not in authoritative mode, bail out
      unless MarkusConfigurator.markus_config_repository_admin? # Are we admin?
        raise NotAuthorityError.new(
            'Unable to set bulk permissions: Not in authoritative mode!')
      end

      # Create auth csv file
      sorted_permissions = AbstractRepository.get_all_permissions.sort.to_h
      CSV.open(MarkusConfigurator.markus_config_repository_permission_file, 'wb') do |csv|
        csv.flock(File::LOCK_EX)
        sorted_permissions.each do |repo_name, users|
          csv << [repo_name] + users
        end
        csv.flock(File::LOCK_UN)
      end
    end

    # TODO I don't think this is used anywhere
    # Set permissions for a single given user for a given repo_name
    def set_permissions(user_name, permissions)

      unless @repos_admin # are we admin?
        raise NotAuthorityError.new('Unable to modify permissions: Not in authoritative mode!')
      end
      get_permissions(user_name) # side effect if user does not exist: raise UserNotFound
      # TODO No-op until all permissions are rw
    end

    # Delete user from access list
    # TODO The user must have been removed from the appropriate db tables before invoking this, maybe it's better doing it all here
    def remove_user(user_name)

      unless @repos_admin # are we admin?
        raise NotAuthorityError.new('Unable to modify permissions: Not in authoritative mode!')
      end
      # TODO Can't check that user exists for repo or raise UserNotFound, if it has already been removed from the db
      GitRepository.__set_all_permissions
    end

    # TODO The user must have been added to the appropriate db tables before invoking this, maybe it's better doing it all here
    def add_user(user_name, permissions)

      unless @repos_admin # are we admin?
        raise NotAuthorityError.new('Unable to modify permissions: Not in authoritative mode!')
      end
      # TODO Can't check that user does not exists for repo or raise UserAlreadyExistent, if it has already been added to the db
      GitRepository.__set_all_permissions
    end

    # Sets permissions over several repositories. Use set_permissions to set
    # permissions on a single repository.
    def self.set_bulk_permissions(repo_names, user_id_permissions_map)

      GitRepository.__set_all_permissions
    end

    # Deletes permissions over several repositories. Use remove_user to remove
    # permissions of a single repository.
    def self.delete_bulk_permissions(repo_names, user_ids)

      GitRepository.__set_all_permissions
    end

    # Helper method to translate internal permissions to git
    # permissions
    # If we want the directory creation to have its own commit,
    # we have to add a dummy file in that directory to do it.
    def self.__translate_to_git_perms(permissions)
      case (permissions)
      when Repository::Permission::READ
        return "R"
      when Repository::Permission::READ_WRITE
        return "RW+"
      else raise "Unknown permissions"
      end # end case
    end

    # Helper method to translate git permissions to internal
    # permissions
    def self.__translate_perms_from_file(perm_string)
      case (perm_string)
      when "R"
        return Repository::Permission::READ
      when "RW"
        return Repository::Permission::READ_WRITE
      when "RW+"
        return Repository::Permission::READ_WRITE
      else raise "Unknown permissions"
      end # end case
    end

    ####################################################################
    ##  Private method definitions
    ####################################################################

    private
    def latest_revision_number(_path = nil, _revision_number = nil)
      return get_revision_number(@repos.head.target)
    end

    def path_exists_for_latest_revision?(path)
      get_latest_revision.path_exists?(path)
    end

    # Creates and commits a file to the repository
    def add_file(path, file_data = nil, author)
      if path_exists_for_latest_revision?(path)
        raise Repository::FileExistsConflict.new(path)
      end
      write_file(path, file_data, author)
    end

    # Removes a file from the repository
    def remove_file(path, author, expected_revision_number = 0)
      if latest_revision_number != expected_revision_number
        raise Repository::FileOutOfSyncConflict.new(path)
      end
      if !path_exists_for_latest_revision?(path)
        raise Repository::FileDoesNotExist.new(path)
      end

      File.unlink(File.join(@repos_path, path))
      @repos.index.remove(path)
      GitRepository.do_commit_and_push(@repos, author, 'Removing file')
    end

    # Replaces file at provided path with file_data
    def replace_file(path, file_data, author, expected_revision_number = 0)
      if latest_revision_number != expected_revision_number
        raise Repository::FileOutOfSyncConflict.new(path)
      end
      if !path_exists_for_latest_revision?(path)
        raise Repository::FileDoesNotExist.new(path)
      end
      write_file(path, file_data, author)
    end

    # Writes to file using path, file_data, and author
    def write_file(path, file_data = nil, author)

      # Get directory path of file (one level higher)
      dir = File.dirname(path)
      abs_path = File.join(@repos_path, dir)

      # Create the folder (if not present), creating parents folders if necessary.
      # This will not overwrite the folder if it's already present.
      FileUtils.mkdir_p(abs_path)

      # Create and commit the file
      make_file(path, file_data, author)
    end

    # Make a file and commit it. This will overwrite the
    # file on disk if it already exists, but will only make a
    # new commit if the file contents have changed.
    def make_file(path, file_data, author)
      # Get the file path to write to using the ruby File module.
      abs_path = File.join(@repos_path, path)
      # Actually create the file.
      File.open(abs_path, 'w') do |file|
        file.write file_data.force_encoding('UTF-8')
      end

      # Get the hash of the file we just created and added
      oid = Rugged::Blob.from_workdir(@repos, path)
      @repos.index.add(path: path, oid: oid, mode: 0100644)
      GitRepository.do_commit_and_push(@repos, author, 'Add file')
    end

    # Create and commit an empty directory, if it's not already present.
    # The dummy file is required so the directory gets committed.
    # path should be a directory
    def make_directory(path)
      gitkeep_filename = File.join(path, '.gitkeep')
      add_file(gitkeep_filename, '', 'markus')
    end

    # Helper method to check file permissions of git auth file
    def git_auth_file_checks
      if !@repos_admin # if we are not admin, check if files exist
        if !File.file?(@repos_auth_file)
          raise FileDoesNotExist.new("'#{@repos_auth_file}' not a file or not existent")
        end
        if !File.readable?(@repos_auth_file)
          raise "File '#{@repos_auth_file}' not readable"
        end
      end
      return true
    end
  end

  # Convenience class, so that we can work on Revisions rather
  # than repositories
  class GitRevision < Repository::AbstractRevision

    # Constructor; Check if revision is actually present in
    # repository
    def initialize(revision_number, repo)
      # Get rugged repository
      @repo = repo.get_repos
      @revision_number = revision_number
      @hash = get_hash_of_revision(revision_number)
      @commit = @repo.lookup(@hash)
      @author = @commit.author[:name]

      # TODO: get correct version of time
      @timestamp = @commit.time
      if @timestamp.instance_of?(String)
        @timestamp = Time.parse(@timestamp).localtime
      elsif @timestamp.instance_of?(Time)
        @timestamp = @timestamp.localtime
      end
    end

    def get_hash_of_revision(revision_number)
      walker = Rugged::Walker.new(@repo)
      walker.sorting(Rugged::SORT_DATE | Rugged::SORT_REVERSE)
      walker.push(@repo.head.target)
      return walker.take(revision_number).last.oid
    end

    # Returns all files (incl. folders) in this repository
    # at path `path` for the current revision file.
    def objects_at_path(path)
      current_tree = find_object_at_path(path)
      # current_tree is now at the path we were looking for
      objects = []
      current_tree.each do |obj|
        file_path = File.join(path, obj[:name])
        @last_modified_date_author = find_last_modified_date_author(file_path)
        if obj[:type] == :blob
          # This object is a file
          file = Repository::RevisionFile.new(
            @revision_number,
            name: obj[:name],
            # Is the path with or without filename?
            # -- Answer: The path is WITHOUT the filename to be consistent
            # with SVN implementation
            path: path,
            # The following is placeholder information.
            last_modified_revision: @revision_number,
            # Last modified date fix here
            last_modified_date: @last_modified_date_author[0],

            changed: true,
            user_id: @last_modified_date_author[1][:name],
            mime_type: 'text'
          )
          objects << file
        elsif obj[:type] == :tree
          # This object is a directory
          directory = Repository::RevisionDirectory.new(
            @revision_number,
            name: obj[:name],
            # Same comments as above in RevisionFile
            path: path,
            last_modified_revision: @revision_number,
            last_modified_date: @last_modified_date_author[0],
            changed: true,
            user_id: @last_modified_date_author[1][:name]
          )
          objects << directory
        else
          # raise unrecognized object
        end
      end

      objects
      # TODO: make a rescue to controller, when repo_browser moves to React
      # we can return a 400 with a message so react knows how to handle
    end

    # Takes in a path (that should be a dir) and returns the Rugged tree object
    # at that path.
    def find_object_at_path(path)
      # Get directory names for path in a nice array
      # like ['A1', 'src', 'core'] for '/A1/src/core'
      path = path.split('/')

      # Account for the files in the root directory with an extra '/' on end
      path.reject!(&:empty?)

      # current_tree is the current directory object we are going through
      # Look at rugged documentation for more info on tree objects
      current_object = @commit.tree
      # While there are still directories to go through to get to path,
      # find the dirname
      path.each do |level|
        # This loop finds the object we're currently looking
        # for in `level` and then looks it up to return
        # a Rugged object (either a tree or a blob)
        current_object = @repo.lookup(
          current_object.detect do |obj|
            obj[:name] == level
          end[:oid])
      end
      # This returns the actual object.
      current_object
    end

    # Return all of the files in this repository in a hash where
    # key: filename and value: RevisionFile object
    def files_at_path(path)
      # In order to deal with the empty assignment folder case we must check
      # to see if the lookup fails as the directory tree is traversed to the
      # very top
      begin
        file_array = objects_at_path(path).select do |obj|
          obj.instance_of?(Repository::RevisionFile)
        end
      rescue
        file_array = {}
      end

      files = Hash.new
      file_array.each do |file|
        files[file.name] = file
      end
      # exception should be cast if file is not found
      files
    end

    def directories_at_path(path)
      # In order to deal with the empty assignment folder case we must check
      # to see if the lookup fails as the directory tree is traversed to the
      # very top
      begin
        dir_array = objects_at_path(path).select do |obj|
          obj.instance_of?(Repository::RevisionDirectory)
        end
      rescue
        dir_array = {}
      end

      directories = Hash.new
      dir_array.each do |dir|
        directories[dir.name] = dir
      end

      directories
    end

    # Returns true if the path given to this function reflects an
    # actual file in the repository, false otherwise
    def path_exists?(path)
      # Chop the forward-slash off the end
      if path[-1] == '/'
        path = path[0..-2]
      end

      # Split the path into parts
      parts = path.split('/')

      tree_ptr = @commit.tree

      # Follow the 'tree-path' and return false if we cannot find
      # each part along the way
      parts.each do |path_part|
        found = false
        tree_ptr.each do |current_tree|
          # For each object in this tree check for our part
          if current_tree[:name] == path_part
            # Move to next part of path (next tree / subdirectory)
            tree_ptr = @repo.lookup(current_tree[:oid])
            found = true
            break
          end
        end
        if !found
          return found
        end
      end
      # If we made it this far, the path was traversed successfully
      true
    end

    # Return changed files at 'path'
    def changed_files_at_path(path)
      files = files_at_path(path)

      files.select do |_name, file|
        file.changed
      end
    end

    def changed_filenames_at_path(path)
      []
    end

    def last_modified_date()
      return self.timestamp
    end

    private

    # Returns the last modified date and author in an array given
    # the path to the file as a string
    def find_last_modified_date_author(path_to_file)
      # Remove starting forward slash, if present
      if path_to_file[0] == '/'
        path_to_file = path_to_file[1..-1]
      end

      # Create a walker to start looking the commit tree.
      walker = Rugged::Walker.new(@repo)
      # Since we are concerned with finding the last modified time,
      # need to sort by date
      walker.sorting(Rugged::SORT_DATE)
      walker.push(@repo.head.target)
      commit = walker.find do |current_commit|
        current_commit.parents.size == 1 && current_commit.diff(paths:
            [path_to_file]).size > 0
      end

      # Return the date of the last commit that affected this file
      # with the author details
      if commit.nil?
        # To let rspec tests pass - Placeholder code
        return Time.now, { name: nil }
      else
        return commit.time, commit.author
      end
    end
  end
end
