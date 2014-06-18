require 'rugged'
require 'gitolite'
require 'digest/md5'
require 'rubygems'
require 'byebug'

require File.join(File.dirname(__FILE__),'repository') # load repository module

def commit_options(repo, system_message)
  {
    author:  { email: "markus@markus.com", name: "Markus", time: Time.now },
    committer: { email: "markus@markus.com", name: "Markus", time: Time.now },
    message: system_message,
    tree: repo.index.write_tree(repo),
    parents: repo.empty? ? [] : [repo.head.target].compact,
    update_ref: "HEAD"
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
        raise IOError.new("Could not create a repository at #{connect_string}: some directory with same name exists already")
      end

      #Create it (we're not going to use a bare repository)
      repo = Rugged::Repository.init_at(connect_string)

      #Do an initial commit to create index.
      oid = repo.write("Initial commit.", :blob)
      repo.index.add(:path => "README.md", :oid => oid, :mode => 0100644)
      Rugged::Commit.create(repo, commit_options(repo, "Creation of initial file"))
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

    # Exports git repo to a new folder (clone repository)
    # If a filepath is given, the repo_dest_dir needs to point to a file, and
    # all the repository on that path need to exist, or the export will fail.
    # Exports git repo to a new folder (clone repository)
    # If a filepath is given, the repo_dest_dir needs to point to a file, and
    # all the repository on that path need to exist, or the export will fail.
    # if export means exporting repo as zip/tgz git-ruby library should be used
    def export(repo_dest_dir, filepath=nil)

      # Case 1: clone all the repo to repo_dest_dir
      if(filepath.nil?)
        # Raise an error if the destination repository already exists
        if (File.exists?(repo_dest_dir))
          raise(ExportRepositoryAlreadyExists,
                "Exported repository already exists")
        end

        repo = Rugged::Repository.clone_at(@repos_path, repo_dest_dir)
      else
        # Case 2: clone a file to a folder
        # Raise an error if the destination file already exists
        if (File.exists?(repo_dest_dir))
          raise(ExportRepositoryAlreadyExists,
                "Exported file already exists")
        end
        FileUtils.cp(get_repos_workdir + filepath, repo_dest_dir)
        return true
      end

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

    # Static method: Reports if a Git repository exists.
    # Done in a similarly hacky method as the git side.
    # TODO - find a better way to do this.
    def self.repository_exists?(repos_path)
      repos_meta_files_exist = false
      if File.exist?(File.join(repos_path, ".git/config"))
        if File.exist?(File.join(repos_path, ".git/description"))
          if File.exist?(File.join(repos_path, ".git/HEAD"))
            repos_meta_files_exist = true
          end
        end
      end
      return repos_meta_files_exist
    end

    # TODO: verify how markus use it
    def stringify_files(files)
      # Given a single object, or an array of objects of type
      # RevisionFile, try to find the file in question, and
      # return it as a string
      blob = @repos.lookup(files[:oid])
      return blob.content
    end
    alias download_as_string stringify_files # create alias

    # Returns a Repository::SubversionRevision instance
    # holding the latest Subversion repository revision
    # number
    def get_latest_revision
      return get_revision(latest_revision_number())
    end

    # Returns hash wrapped
    # as a Git instance
    def get_revision(revision_number)
      return Repository::GitRevision.new(revision_number, self)
    end

    def get_revision_by_timestamp(target_timestamp, path = nil)
      # returns a Git instance representing the revision at the
      # current timestamp, should be a ruby time stamp instance
      walker = Rugged::Walker.new(self.get_repos)
      walker.push(self.get_repos.head.target)
      walker.each do |c|
        if c.time <= target_timestamp
          return get_revision(c)
        end
      end
    end

    # Returns a Repository::TransAction object, to work with. Do operations,
    # like 'add', 'remove', etc. on the transaction instead of the repository
    def get_transaction(user_id, comment="")
      if user_id.nil?
        raise "Expected a user_id (Repository.get_transaction(user_id))"
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
            txn = add_file(txn, job[:path], job[:file_data], job[:mime_type])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :remove
          begin
            txn = remove_file(txn, job[:path], job[:expected_revision_number])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :replace
          begin
            txn = replace_file(txn, job[:path], job[:file_data], job[:mime_type], job[:expected_revision_number])
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
        if !File.exist?(Repository.conf[:REPOSITORY_PERMISSION_FILE] + "/conf/gitolite.conf")
          Gitolite::GitoliteAdmin.bootstrap(Repository.conf[:REPOSITORY_PERMISSION_FILE]) # create files if not existent
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
              raise UserAlreadyExistent.new(user_id + " already existent")
            end
          end
        end

        git_permission = self.class.__translate_to_git_perms(permissions)
        repo.add_permission(git_permission,"",user_id)
        ga_repo.save_and_apply
      else
        raise NotAuthorityError.new("Unable to modify permissions: Not in authoritative mode!")
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

    def self.add_user(user_id, permissions,repo_name)

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

      #check if gitolite admin repo exists
      #TODO paths should be in config file
      if !File.exist?(Repository.conf[:REPOSITORY_PERMISSION_FILE] + "conf/gitolite.conf")
        Gitolite::GitoliteAdmin.bootstrap(Repository.conf[:REPOSITORY_PERMISSION_FILE]) # create files if not existent
      end

      #gitolite admin repo
      #ga_repo = Gitolite::GitoliteAdmin.new("#{::Rails.root.to_s}/data/dev/repos/git_auth")
      ga_repo = Gitolite::GitoliteAdmin.new(Repository.conf[:REPOSITORY_PERMISSION_FILE])
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

      #else
      #  raise NotAuthorityError.new("Unable to modify permissions: Not in authoritative mode!")
      #end

    end

    def expand_path(file_name, dir_string = "/")
      # Converts a pathname to an absolute pathname and then return the path
      return File.expand_path(file_name, dir_string)
    end

    ####################################################################
    ##  The following stuff is semi-private. As a general rule don't use
    ##  it directly. The only reason it's public, is that
    ##  SubversionRevision needs to have access.
    ####################################################################

    def __path_exists?(path, revision=nil)
      # Not (!) part of the AbstractRepository API:
      # Check if given file or path exists in repository beeing member of
      # the provided revision
    end

    def __get_files(path="/", revision_number=nil)
      # Not (!) part of the AbstractRepository API:
      # Returns a hash of files/directories part of the requested
      # revision; Don't use it directly, use SubversionRevision's
      # 'files_at_path' instead
    end

    def __get_property(prop, rev=nil)
      # Not (!) part of the AbstractRepository API:
      # Returns
      #    prop
      # of Subversion repository
    end

    def __get_file_property(prop, path, revision_number)
      # Not (!) part of the AbstractRepository API:
      # Returns
      #    prop
      # of Subversion repository file
    end

    def __get_node_last_modified_date(path, commit)
      # Not (!) part of the AbstractRepository API:
      # Returns
      #    The last modified date
      # of a Subversion repository file or directory
    end

    def __get_history(paths, starting_revision=nil, ending_revision=nil)
      # Not (!) part of the AbstractRepository API:
      # This function is very similar to @repos.fs.history(); however, it's been altered a little
      # to return only an array of revision numbers. This function, in contrast to the original,
      # takes multiple paths and returns one large history for all paths given.
      # refer to Subversion_repository for implementation.
    end

    # Helper method to translate internal permissions to Subversion
    # permissions
    def self.__translate_to_git_perms(permissions)
      case (permissions)
      when Repository::Permission::READ
        return "R"
      when Repository::Permission::READ_WRITE
        return "RW+"
      else raise "Unknown permissions"
      end # end case
    end

    # Helper method to translate Subversion permissions to internal
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

    def setup_auth_baton(auth_baton)
      # Function necessary for exporting the git repository, may not be needed
    end

    # Returns the most recent revision of the repository. If a path is specified,
    # the youngest revision is returned for that path; if a revision is also specified,
    # the function will return the youngest revision that is equal to or older than the one passed.
    #
    # This will only work for paths that have not been deleted from the repository.
    # GIT NOTE: This will just return the latest hash for now
    def latest_revision_number(path = nil, revision_number = nil)
      return @repos.head
    end

    def get_revision_number_by_timestamp(target_timestamp, path = nil)
      # Gets the revision of the repo by time stamp
      # Assumes timestamp is a Time object (which is part of the Ruby
      # standard library)
      #
      # May not need this function
    end

    # adds a file to a transaction and eventually to repository
    def add_file(txn, path, file_data=nil, mime_type=nil)
      if __path_exists?(path)
        raise Repository::FileExistsConflict.new(path)
      end
      txn = write_file(txn, path, file_data, mime_type)
      return txn
    end

    # removes a file from a transaction and eventually from repository
    def remove_file(txn, path, expected_revision_number=0)
      @repos.index.remove(path);
      Rugged::Commit.create(@repos,commit_options(@repos,"Removing file"))
      return txn
    end

    # replaces file at provided path with file_data
    def replace_file(txn, path, file_data=nil, mime_type=nil, expected_revision_number=0)
      txn = write_file(txn, path, file_data, mime_type)
      return txn
    end

    def write_file(txn, path, file_data=nil, mime_type=nil)
      # writes to file using transaction, path, data, and mime
      # refer to Subversion_repo for implementation

      if (!__path_exists?(path))
        pieces = path.split("/").delete_if {|x| x == ""}
        dir_path = ""

        (0..pieces.length - 2).each do |index|
          dir_path += "/" + pieces[index]
          make_directory(txn, dir_path)
        end
        make_file(txn, path,file_data)
      end
    end

    # Make a file if it's not already present.
    def make_file(txn, path,file_data)
      repo = @repos
      oid = repo.write(file_data, :blob)
      repo.index.add(path: path, oid: oid, mode: 0100644)
      Rugged::Commit.create(repo, commit_options(repo,"Adding file"))
    end

    # Make a directory if it's not already present.
    def make_directory(path)

      # turn "path" into absolute path
      path = expand_path(path, "/")
      # do nothing if "path" is the root
      return if path == "/"

      # get the path of parent folder
      parent_path = File.dirname(path)
      # and create parent folder before the current folder (recursively)
      make_directory(parent_path)

      # now that the parent folder has been created,
      # create the current folder
      FileUtils.mkdir_p(path)

    end

    # Helper method to check file permissions of git auth file
    def git_auth_file_checks()
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
      begin
        # Get object using target of the reference (Object ID)
        if revision_number.type == :direct
          @commit = @repo.lookup(revision_number.target);
        else
          @commit = revision_number;
        end
        @timestamp = @commit.time
        if @timestamp.instance_of?(String)
          @timestamp = Time.parse(@timestamp).localtime
        elsif @timestamp.instance_of?(Time)
          @timestamp = @timestamp.localtime
        end
      rescue Exception
        raise RevisionDoesNotExist
      end
      super(@commit)
    end

    # Return all of the files in this repository at the root directory
    def files_at_path(commit)
      begin
        files = Hash.new(nil)

        @commit.tree.each do |c|
          files[c[:name]] = c
        end
        
        #exception should be cast if file is not found
      rescue Exception
        raise Repository::FileDoesNotExistConflict
        return nil
      end

      return files
    end

    # returns true if the file at the given path exists for the
    # class's revision_number (commit name)
    #
    # erros with this function can occur with files are incorrectly
    # added and the git config file is not updated
    def path_exists?(path)
      begin
        # if path exists in the git repository
        # discover should not give an error
        Rugged::Repository.discover(path)
        return true
        #exception should be cast if path is not found
      rescue Exception
        raise Repository::FileDoesNotExistConflict # I don't think raise an exception is needed
        return false
      end
    end

    def directories_at_path(path='/')
      result = Hash.new(nil)
      raw_contents = @repo.__get_files(path, @revision_number)
      raw_contents.each do |file_name, type|
        if type == :directory
          last_modified_revision = @repo.__get_history(File.join(path, file_name)).last
          last_modified_date = @repo.__get_node_last_modified_date(File.join(path, file_name), @revision_number)
          new_directory = Repository::RevisionDirectory.new(@revision_number, {
                                                              :name => file_name,
                                                              :path => path,
                                                              :last_modified_revision => last_modified_revision,
                                                              :last_modified_date => last_modified_date,
                                                              :changed => (last_modified_revision == @revision_number),
                                                              :user_id => @repo.__get_property(:author, last_modified_revision)
                                                            })
          result[file_name] = new_directory
        end
      end
      return result
    end

    # Return changed files at 'path' (recursively)
    def changed_files_at_path(path)
      return files_at_path_helper(path, true)
    end

    def last_modified_date()
      return self.timestamp
    end

    private

    def files_at_path_helper(path='/', only_changed=false)
      if path.nil?
        path = '/'
      end
      result = Hash.new(nil)
      raw_contents = @repo.__get_files(path, @revision_number)
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

  end

end
