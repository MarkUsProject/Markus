require 'rugged'
require 'gitolite'
require 'digest/md5'
require 'rubygems'

require File.join(File.dirname(__FILE__),'repository') # load repository module

def commit_options(repo, author, message)
  {
    author:  { email: 'markus@markus.com', name: author, time: Time.now },
    committer: { email: 'markus@markus.com', name: author, time: Time.now },
    message: message,
    tree: repo.index.write_tree(repo),
    parents: repo.empty? ? [] : [repo.head.target].compact,
    update_ref: 'HEAD'
  }
end

module Repository

  # Implements AbstractRepository for Git repositories
  # It implements the following paradigm:
  #   1. Repositories are created by using ???
  #   2. Existing repositories are opened by using either ???
  class GitRepository < Repository::AbstractRepository

    # Constructor: Connects to an existing Git
    # repository, using Ruby bindings; Note: A repository has to be
    # created using GitRespository.create(), it it is not yet existent
    def initialize(connect_string)
      # Check if configuration is in order
      if Repository.conf[:IS_REPOSITORY_ADMIN].nil?
        raise ConfigurationError.new("Required config 'IS_REPOSITORY_ADMIN' not set")
      end
      if Repository.conf[:REPOSITORY_STORAGE].nil?
        raise ConfigurationError.new("Required config 'REPOSITORY_STORAGE' not set")
      end
      if Repository.conf[:REPOSITORY_PERMISSION_FILE].nil?
        raise ConfigurationError.new("Required config 'REPOSITORY_PERMISSION_FILE' not set")
      end
      begin
        super(connect_string) # dummy call to super
      rescue NotImplementedError; end
      @repos_path = connect_string
      @closed = false
      @repos_admin = Repository.conf[:IS_REPOSITORY_ADMIN]
      if (GitRepository.repository_exists?(@repos_path))
        @repos = Rugged::Repository.new(@repos_path)
      else
        raise "Repository does not exist at path \"" + @repos_path + "\""
      end
    end

    # Static method: Creates a new Git repository at
    # location 'connect_string'
    def self.create(connect_string)
      if GitRepository.repository_exists?(connect_string)
        raise RepositoryCollision.new("There is already a repository at #{connect_string}")
      end
      if File.exists?(connect_string)
        raise IOError.new("Could not create a repository at #{connect_string}:
                          some directory with same name exists already")
      end

      #Create it (we're not going to use a bare repository)
      repo = Rugged::Repository.init_at(connect_string)

      # Do an initial commit with a README to create index.
      file_path_for_readme = File.join(repo.workdir, 'README.md')
      File.open(file_path_for_readme, 'w+') do |readme|
        readme.write('Initial commit.')
      end
      oid = Rugged::Blob.from_workdir(repo, 'README.md')
      index = repo.index
      index.add(path: 'README.md', oid: oid, mode: 0100644)
      index.write
      Rugged::Commit.create(repo,
                            commit_options(repo, 'Markus',
                                           'Initial commit and add readme.'))
      return true
    end

    # Static method: Opens an existing Git repository
    # at location 'connect_string'
    def self.open(connect_string)
      repo = GitRepository.new(connect_string)
    end

    # static method that should yeild to a git repo and then close it
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
      # Get work directory from GitRepository
      # workdir = path/to/my/repository/
      return @repos.workdir
    end

    def get_repos_path
      # Get Rugged repository from GitRepository
      # workdir = path/to/my/repository/.git
      return @repos.path
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
    
    def get_revision_by_timestamp(target_timestamp, path = nil)
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
      # If no revision number was found, display the latest revision with an error message
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
            txn =
                remove_file(txn,
                            job[:path], transaction.user_id,
                            job[:expected_revision_number])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :replace
          begin
            txn = replace_file(txn,
                               job[:path], job[:file_data], job[:mime_type],
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

    # Adds a user with given permissions to the repository
    def add_user(user_id, permissions)

      if @repos_admin # Are we admin?
        if !Gitolite::GitoliteAdmin.is_gitolite_admin_repo?(Repository.conf[:REPOSITORY_STORAGE])
          Gitolite::GitoliteAdmin.bootstrap(Repository.conf[:REPOSITORY_STORAGE])
        end


        ga_repo = Gitolite::GitoliteAdmin.new(Repository.conf[:REPOSITORY_PERMISSION_FILE])
        repo_name = self.get_repos.workdir.split('/').last
        repo = ga_repo.config.get_repo(repo_name)

        if repo.nil?
          repo = Gitolite::Config::Repo.new(repo_name)
          ga_repo.config.add_repo(repo)
        else
          repo.permissions[0].each do |perm|
            if(repo.permissions[0][perm[0]][""].include? user_id)
              raise UserAlreadyExistent.new(user_id + ' already existent')
            end
          end
        end

        git_permission = self.class.__translate_to_git_perms(permissions)
        repo.add_permission(git_permission, '', user_id)
        ga_repo.save_and_apply
      else
        raise NotAuthorityError.new('Unable to modify permissions:
                                     Not in authoritative mode!')
      end

    end

    def get_users(permissions)
      # Gets a list of users with AT LEAST the provided permissions.
      # Returns nil if there aren't any.

      # Permissions provided
      # http://gitolite.com/gitolite/write-types.html

      result_list = []

      ga_repo = Gitolite::GitoliteAdmin.new(Repository.conf[:REPOSITORY_PERMISSION_FILE])
      repo = ga_repo.config.get_repo(self.get_repos.workdir.split('/').last)

      if !repo.nil?
        repo.permissions[0].each do |perm|
          if self.class.__translate_perms_from_file(perm[0]) >= permissions
            repo.permissions[0][perm[0]][""].each do |user|
              result_list.push(user)
            end
          end
        end
      end

      if !result_list.empty?
        return result_list
      else
        return nil
      end
    end

    def get_permissions(user_id)

      #if @repos_admin # Are we admin?
      # Adds a user with given permissions to the repository

      ga_repo = Gitolite::GitoliteAdmin.new(Repository.conf[:REPOSITORY_PERMISSION_FILE])
      repo = ga_repo.config.get_repo(self.get_repos.workdir.split('/').last)

      # Gets permissions of a particular user
      repo.permissions[0].each do |perm|
        if(repo.permissions[0][perm[0]][""].include? user_id)
          return self.class.__translate_perms_from_file(perm[0])
        end
      end

      raise UserNotFound.new(user_id + " not found")

      #else
      #  raise NotAuthorityError.new("Unable to modify permissions: Not in authoritative mode!")
      #end
    end

    def set_permissions(user_id, permissions)
      # Set permissions for a single given user
      if @repos_admin # Are we admin?

        #TODO: remove permissions should be done before reseting it
        # in case he already has a permission
        remove_user(user_id)

        # Adds a user with given permissions to the repository
        ga_repo = Gitolite::GitoliteAdmin.new(Repository.conf[:REPOSITORY_PERMISSION_FILE])
        repo_name = self.get_repos.workdir.split('/').last
        repo = ga_repo.config.get_repo(repo_name)

        if repo.nil?
          repo = Gitolite::Config::Repo.new(repo_name)
        end

        git_permission = self.class.__translate_to_git_perms(permissions)
        repo.add_permission(git_permission, "", user_id)
        ga_repo.config.add_repo(repo)
        ga_repo.save_and_apply
      else
        raise NotAuthorityError.new("Unable to modify permissions: Not in authoritative mode!")
      end
    end

    def remove_user(user_id)
      # Delete user from access list
      # There is no user remove support from gitolite ruby library
      # Work-around:
      # - copy permissions from repo
      # - remove repo from config and save and apply
      # - add again permissions not removed

      if @repos_admin # Are we admin?
        # Adds a user with given permissions to the repository
        ga_repo = Gitolite::GitoliteAdmin.new(Repository.conf[:REPOSITORY_PERMISSION_FILE])
        repo_name = self.get_repos.workdir.split('/').last

        repo = ga_repo.config.get_repo(repo_name)
        rw_list = []
        r_list  = []
        found = false
        if !repo.nil?
          repo.permissions[0]["RW+"][""].each do |user|
            if(user != user_id)
              rw_list.push(user)
            else
              found = true
            end
          end

          repo.permissions[0]["R"][""].each do |user|
            if(user != user_id)
              r_list.push(user)
            else
              found = true
            end
          end

          if found==true
            ga_repo.config.rm_repo(repo)
            ga_repo.save_and_apply
            rw_list.each do |user|
              add_user(user,Repository::Permission::READ_WRITE)
            end

            r_list.each do |user|
              add_user(user,Repository::Permission::READ)
            end
          else
            raise UserNotFound.new(user_id + " not found")
          end
        else
          raise UserNotFound.new(user_id + " not found")
        end
      else
        raise NotAuthorityError.new("Unable to modify permissions: Not in authoritative mode!")
      end
    end

    def self.add_user(user_id, permissions, repo_name)

      # Adds a user with given permissions to the repository
      if !File.exist?(Repository.conf[:REPOSITORY_PERMISSION_FILE])
        File.open(Repository.conf[:REPOSITORY_PERMISSION_FILE], "w").close() # create file if not existent
      end

      ga_repo = Gitolite::GitoliteAdmin.new(Repository.conf[:REPOSITORY_PERMISSION_FILE])
      repo = ga_repo.config.get_repo(repo_name)

      if repo.nil?
        repo = Gitolite::Config::Repo.new(repo_name)
        ga_repo.config.add_repo(repo)
      else
        repo.permissions[0].each do |perm|
          if(repo.permissions[0][perm[0]][""].include? user_id)
            raise UserAlreadyExistent.new(user_id + " already existent")
          end
        end
      end

      git_permission = GitRepository.__translate_to_git_perms(permissions)
      repo.add_permission(git_permission,"",user_id)
      ga_repo.save_and_apply
    end

    # Sets permissions over several repositories. Use set_permissions to set
    # permissions on a single repository.
    def self.set_bulk_permissions(repo_names, user_id_permissions_map)
      # Check if configuration is in order
      if Repository.conf[:IS_REPOSITORY_ADMIN].nil?
        raise ConfigurationError.new("Required config 'IS_REPOSITORY_ADMIN' not set")
      end
      # If we're not in authoritative mode, bail out
      if !Repository.conf[:IS_REPOSITORY_ADMIN] # Are we admin?
        raise NotAuthorityError.new("Unable to set bulk permissions:  Not in authoritative mode!");
      end

      # Check if gitolite admin repo exists, create it if not
      if !Gitolite::GitoliteAdmin.is_gitolite_admin_repo?(Repository.conf[:REPOSITORY_STORAGE])
        Gitolite::GitoliteAdmin.bootstrap(Repository.conf[:REPOSITORY_STORAGE])
      end

      #gitolite admin repo
      ga_repo = Gitolite::GitoliteAdmin.new(Repository.conf[:REPOSITORY_STORAGE])
      conf = ga_repo.config

      repo_names.each do |repo_name|
        repo_name = File.basename(repo_name)
        repo = ga_repo.config.get_repo(repo_name)
        if repo.nil?
          repo = Gitolite::Config::Repo.new(repo_name)
        end
        user_id_permissions_map.each do |user_id, permissions|
          perm_string = __translate_to_git_perms(permissions)
          repo.add_permission(perm_string, "", user_id)
        end
        conf.add_repo(repo)
      end

      #update gitolite
      ga_repo.save_and_apply
    end

    def self.delete_bulk_permissions(repo_names, user_ids)
      # Deletes permissions over several repositories. Use remove_user to remove
      # permissions of a single repository.
      # There is no user remove support from gitolite ruby library
      # Work-around:
      # - copy permissions from repo
      # - remove repo from config and save and apply
      # - add again permissions not removed

      #if @repos_admin # Are we admin?
      # Adds a user with given permissions to the repository
      ga_repo = Gitolite::GitoliteAdmin.new(Repository.conf[:REPOSITORY_PERMISSION_FILE])

      repo_names.each do |repo_name|
        repo_name = File.basename(repo_name)
        repo = ga_repo.config.get_repo(repo_name)
        rw_list = []
        r_list  = []
        found = false
        if !repo.nil?

          repo.permissions[0]["RW+"][""].each do |user|
            if(!user_ids.include? user)
              rw_list.push(user)
            else
              found = true
            end
          end

          repo.permissions[0]["R"][""].each do |user|
            if(!user_ids.include? user)
              r_list.push(user)
            else
              found = true
            end
          end
          if found==true
            ga_repo.reload!
            ga_repo.config.rm_repo(repo)
            ga_repo.save_and_apply
            rw_list.each do |user|
              add_user(user,Repository::Permission::READ_WRITE,repo_name)
            end

            r_list.each do |user|
              add_user(user,Repository::Permission::READ,repo_name)
            end
          else
            raise UserNotFound.new(user_id + " not found")
          end
        else
          raise UserNotFound.new(user_id + " not found")
        end
      end
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
    def latest_revision_number(path = nil, revision_number = nil)
      return get_revision_number(@repos.head.target)
    end

    def get_revision_number_by_timestamp(target_timestamp, path = nil)
      # Gets the revision of the repo by time stamp
      # Assumes timestamp is a Time object (which is part of the Ruby
      # standard library)
      #
      # May not need this function
    end

    def path_exists_for_latest_revision?(path)
      get_latest_revision.path_exists?(path)
    end

    # adds a file to a transaction and eventually to repository
    def add_file(path, file_data = nil, author)
      if path_exists_for_latest_revision?(path)
        raise Repository::FileExistsConflict.new(path)
      end
      write_file(path, file_data, author)
    end

    # removes a file from a transaction and eventually from repository
    def remove_file(txn, path, author, _expected_revision_number = 0)
      repo = @repos
      @repos.index.remove(path);
      File.unlink File.join(repo.workdir, path)
      @repos.index.write_tree repo
      @repos.index.write
      Rugged::Commit.create(@repos, commit_options(@repos, author,
                                                   'Removing file'))

      return txn
    end

    # replaces file at provided path with file_data
    def replace_file(txn, path, file_data = nil,
                     mime_type = nil, _expected_revision_number = 0)
      txn = write_file(path, file_data, mime_type)
      return txn
    end

    def write_file(path, file_data = nil, author)
      # writes to file using transaction, path, data, and mime
      # refer to Subversion_repo for implementation
      # Get directory path of file (one level higher)
      dir = path.split('/')[0..-2].join('/')
      # make_directory to path, if it already exists make_directory
      # won't do anything so no harm no foul.
      make_directory(dir)
      make_file(path, file_data, author)
    end

    # Make a file if it's not already present.
    def make_file(path, file_data, author)
      repo = @repos
      # Get the file path to write to using the ruby File module.
      file_path = File.join(repo.workdir, path)
      # Actually create the file.
      File.open(file_path, 'w+') do |file|
        file.write file_data.force_encoding('UTF-8')
      end

      # Get the hash of the file we just created and added
      oid = Rugged::Blob.from_workdir(repo, path)
      index = repo.index
      index.add(path: path, oid: oid, mode: 0100644)
      index.write
      Rugged::Commit.create(repo, commit_options(repo, author, 'Add file'))
    end

    # Make a directory if it's not already present.
    # If we want the directory creation to have its own commit,
    # we have to add a dummy file in that directory to do it.
    def make_directory(path)
      # Turn "path" into absolute path for repo
      path = File.expand_path(path, @repos_path)

      # Do nothing if folder already exists
      return if File.exist?(path)

      # Recursively create parent folders (if doesn't exist)
      parent_path = File.dirname(path)
      make_directory(parent_path)

      # Now that the parent folder has been created,
      # create the current folder
      FileUtils.mkdir_p(path)
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
      walker.sorting(Rugged::SORT_DATE| Rugged::SORT_REVERSE) 
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
        file_path = path + obj[:name]
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
      parts.each { |path_part|
        found = false
        current_tree = nil
        tree_ptr.each { |current_tree|
          # For each object in this tree check for our part
          if current_tree[:name] == path_part
            # Move to next part of path (next tree / subdirectory)
            found = true
            break
          end
        }
        if !found
          return found
        end
      }
      # If we made it this far, the path was traversed successfully
      true
    end

    # Return changed files at 'path' (recursively)
    def changed_files_at_path(path)
      return files_at_path_helper(path, true)
    end

    def last_modified_date()
      return self.timestamp
    end

    private

    def files_at_path_helper(path = '/', only_changed = false)
      if path.nil?
        path = '/'
      end
      result = Hash.new(nil)
      raw_contents = self.__get_files(path, @revision_number)
      raw_contents.each do |file_name, type|
        if type == :file
          last_modified_date = @repo.__get_node_last_modified_date(File.join(path, file_name), @revision_number)
          last_modified_revision = @repo.__get_history(File.join(path, file_name), nil, @revision_number).last

          if(!only_changed || (last_modified_revision == @revision_number))
            new_file = Repository::RevisionFile.new(@revision_number, {
                                                      :name => file_name,
                                                      :path => path,
                                                      :last_modified_revision => last_modified_revision,
                                                      :changed => (last_modified_revision == @revision_number),
                                                      :user_id => @repo.__get_property(:author, last_modified_revision),
                                                      :mime_type => @repo.__get_file_property(:mime_type, File.join(path, file_name), last_modified_revision),
                                                      :last_modified_date => last_modified_date
                                                    })
            result[file_name] = new_file
          end
        end
      end
      return result
    end

    # Returns the last modified date and author in an array given
    # the relative path to file as a string
    def find_last_modified_date_author(relative_path_to_file)
      # Create a walker to start looking the commit tree.
      walker = Rugged::Walker.new(@repo)
      # Since we are concerned with finding the last modified time,
      # need to sort by date
      walker.sorting(Rugged::SORT_DATE)
      walker.push(@repo.head.target)
      commit = walker.find do |current_commit|
        current_commit.parents.size == 1 && current_commit.diff(paths:
            [relative_path_to_file]).size > 0
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
