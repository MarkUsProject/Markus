require "rugged"
require "gitolite"
require "digest/md5"
require File.join(File.dirname(__FILE__),'repository') # load repository module

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

      #Create it
      repo = Rugged::Repository.init_at(connect_string, :bare)

      #Do an initial commit to get master.
      #TODO. find a better way.
      index = Rugged::Index.new
      options = {}
      options[:tree] = index.write_tree(repo)
      options[:author] = { :email => "testuser@github.com", :name => 'Test Author', :time => Time.now }
      options[:committer] = { :email => "testuser@github.com", :name => 'Test Author', :time => Time.now }
      options[:message] ||= "Making a commit via Rugged!"
      options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
      options[:update_ref] = 'HEAD'

      Rugged::Commit.create(repo, options)

      #TODO checks.
      # .new does not exist for Rugged::Repository
      repo = Rugged::Repository.new(connect_string)

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
    def self.delete(repo_path)
      #does not acutally delete repo, just removes reference to master. This prevents any other git operations.
      ref = Rugged::Reference.lookup(repo, "refs/heads/master")
      ref.delete!
    end

    def export(repo_dest_dir, filepath=nil, revision_number=nil)
      # exports git repo to a new folder

      # If a filepath is given, the repo_dest_dir needs to point to a file, and
      # all the repository on that path need to exist, or the export will fail.

      # refer to Subversion_repository for implementation.
    end

    def self.closable?
      # return if the git library supports close, 
      # probably going to need to be a dumby method
    end

    def close
      # closes the git repo
    end

    def self.closed?
      # checks if the repo is closed
    end

    # Static method: Reports if a Git repository exists.
    # Done in a similarly hacky method as the git side.
    # TODO - find a better way to do this.
    def self.repository_exists?(repos_path)
      repos_meta_files_exist = false
      if File.exist?(File.join(repos_path, "config"))
        if File.exist?(File.join(repos_path, "description"))
          if File.exist?(File.join(repos_path, "HEAD"))
            repos_meta_files_exist = true
          end
        end
      end
      return repos_meta_files_exist
    end

    def stringify_files(files)
      # Given a single object, or an array of objects of type
      # RevisionFile, try to find the file in question, and
      # return it as a string
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
      # carries out the actions on a git repo stored in a 
      # transaction. Conflicts should are added to the transaction obejct

      # Carries out actions on a Git repository stored in
      # 'transaction'. In case of certain conflicts corresponding
      # Repositor::Conflict(s) are added to the transaction object

      debugger
      jobs = transaction.jobs
      txn = @repos.fs.transaction # transaction date is set implicitly
      txn.set_prop(Repository::SVN_CONSTANTS[:author], transaction.user_id)
      jobs.each do |job|
        case job[:action]
        when :add_path
          begin
            txn = make_directory(txn, job[:path])
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
      txn.commit
      return true
    end

    def add_user(user_id, permissions)
      # Adds a user with given permissions to the repository      
    end
    
    def get_users(permissions)
      # Gets a list of users with AT LEAST the provided permissions.
      # Returns nil if there aren't any.
    end

    def get_permissions(user_id)
      # Gets permissions of a particular user
    end

    def set_permissions(user_id, permissions)
      # Set permissions for a single given user
    end

    def remove_user(user_id)
      # Delete user from access list
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

      #gitolite admin repo
      ga_repo = Gitolite::GitoliteAdmin.new("#{::Rails.root.to_s}/data/dev/repos/git_auth")
      conf = ga_repo.config

      repo_names.each do |repo_name|
        repo_name = File.basename(repo_name)
        repo = Gitolite::Config::Repo.new(repo_name)
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
    end
    
    def expand_path(file_name, dir_string = "/")
      # Converts a pathname to an absolute pathname and then return the path
    end

    ####################################################################
    ##  Semi-private class methods (one should not use them from outside
    ##  this class).
    ####################################################################

    def self.__read_in_authz_file()
      # Semi-private class method: Reads in Repository.conf[:REPOSITORY_PERMISSION_FILE]
      # refer to Subversion_repository for implementation.
    end
    
    def self.__write_out_authz_file(authz_file_contents)
      # Semi-private class method: Writes out Repository.conf[:REPOSITORY_PERMISSION_FILE]
      # refer to Subversion_repository for implementation.
    end

    def self.__parse_authz_file(authz_string)
      # Semi-private class method: Parses a subversion authz file passed in as a string
      # refer to Subversion_repository for implementation.
    end

    def self.__prepare_authz_string(permissions)
      # Semi-private class method: Transforms passed in permissions into
      # subversion authz file syntax
      # refer to Subversion_repository for implementation.
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

    def __get_node_last_modified_date(path, revision_number)
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
      debugger
      
      #TODO This was using FS, specific to SVN. Need to look for git.

      @repos.head;

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
      if latest_revision_number(path).to_i != expected_revision_number.to_i
        raise Repository::FileOutOfSyncConflict.new(path)
      end
      if !__path_exists?(path)
        raise Repository::FileDoesNotExistConflict.new(path)
      end
      txn.root.delete(path)
      return txn
    end

    # replaces file at provided path with file_data
    def replace_file(txn, path, file_data=nil, mime_type=nil, expected_revision_number=0)
      if latest_revision_number(path).to_i != expected_revision_number.to_i
        raise Repository::FileOutOfSyncConflict.new(path)
      end
      txn = write_file(txn, path, file_data, mime_type)
      return txn
    end

    def write_file(txn, path, file_data=nil, mime_type=nil)
      # writes to file using transaction, path, data, and mime
      # refer to Subversion_repo for implementation
    end

    # Make a file if it's not already present.
    def make_file(txn, path)
      if (txn.root.check_path(path) == 0)
        txn.root.make_file(path)
      end
      return txn
    end

    # Make a directory if it's not already present.
    def make_directory(txn, path)
      # turn "path" into absolute path
      path = expand_path(path, "/")
      # do nothiing if "path" is the root
      return txn if path == "/"

      # get the path of parent folder
      parent_path = File.dirname(path)
      # and create parent folder before the current folder (recursively)
      txn = make_directory(txn, parent_path)

      # now that the parent folder has been created,
      # create the current folder
      if (txn.root.check_path(path) == 0)
        txn.root.make_dir(path)
      end

      return txn
    end

    # Parses repository permissions from provided auth_file
    def get_repo_permissions_from_file_string(auth_string)
      u_perm_mapping = {}
      repo_name = File.basename(@repos_path)
      if /\[#{repo_name}:\/\]([^\[]+)/.match(auth_string)
        perm_string = $1
        perm_string.strip().split("\n").each do |line|
          if /\s*(\w+)\s*=\s*(\w+)\s*/.match(line)
            u_perm_mapping[$1.to_s] = $2.to_s
          end
        end
        return u_perm_mapping
      else
        return {} # repo name not found
      end
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

    # Helper method to inject new permissions. Expects a hash representing
    # users <=> git permissions mapping and the current file contents of
    # the git authz file as a string
    def inject_permissions(users_permissions, auth_string)
      repo_name = File.basename(@repos_path)
      auth_string = auth_string.strip()
      map_string = perm_mapping_to_git_authz_string(users_permissions)
      if /\[#{repo_name}:\/\][^\[]+/.match(auth_string)
        auth_string = auth_string.sub(/\[#{repo_name}:\/\][^\[]+/, map_string)
      else
        # repo name not found so append at the end
        auth_string += "\n"+map_string
      end

      # format file_string a little
      auth_string = auth_string.strip() # get rid of leading/trailing white-space
      lines = auth_string.split("\n")
      tmp_filestring = ""
      is_extraneous_empty_line = false
      lines.each do |line|
        if (line == "")
          if (!is_extraneous_empty_line)
            tmp_filestring += "\n"
          end
          is_extraneous_empty_line = true
        else
          tmp_filestring += line+"\n"
          is_extraneous_empty_line = false
        end
      end
      auth_string = tmp_filestring

      return auth_string
    end

    # Translates a user <=> permissions mapping to a string corresponding
    # to Subversions authz file format
    def perm_mapping_to_git_authz_string(users_perms)
      if users_perms.empty?
        return ""
      end
      repo_name = File.basename(@repos_path)
      result_string = "\n[#{repo_name}:/]\n"
      users_perms.each do |user, permstr|
        result_string += "#{user} = #{permstr}\n"
      end
      return result_string
    end

  end

  # Convenience class, so that we can work on Revisions rather
  # than repositories
  class GitRevision < Repository::AbstractRevision

    # Constructor; Check if revision is actually present in
    # repository
    def initialize(revision_number, repo)
      @repo = repo
      begin
        @commit = repo.lookup(revision_number);
        @timestamp = commit.time
        if @timestamp.instance_of?(String)
          @timestamp = Time.parse(@timestamp).localtime
        elsif @timestamp.instance_of?(Time)
          @timestamp = @timestamp.localtime
        end
      rescue Exception
        raise RevisionDoesNotExist
      end 
      super(revision_number)
    end

    # Return all of the files in this repository at the root directory
    # *** Not sure if using path is best here, maybe use repo instead?
    #
    # method not thoroughly tested!!
    #
    # returns a index object, consult rugged docs for available methods
    def files_at_path(path)
      begin 
        return Rugged::Index.new(path)
        #exception should be cast if file is not found
      rescue Exception
        raise Repository::FileDoesNotExistConflict
      end
    end

    # returns true if the file at the given path exists for the
    # class's revision_number (commit name)
    #
    # method not thoroughly tested!!
    #
    # erros with this function can occur with files are incorrectly
    # added and the git config file is not updated
    def path_exists?(path)
      begin 
        file = Rugged::Index.new(path)
        return true
        #exception should be cast if file is not found
      rescue Exception
        # raise Repository::FileDoesNotExistConflict # I don't think raise an exception is needed
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