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


<<<<<<< HEAD
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

    # Static method: Opens an existing Git repository
    # at location 'connect_string'
    def self.open(connect_string)
      repo = GitRepository.new(connect_string)
    end

=======
>>>>>>> 38a7a7a571c732051a2d592c5d99ad93e617a2ae
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

<<<<<<< HEAD
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

=======
>>>>>>> 38a7a7a571c732051a2d592c5d99ad93e617a2ae
      #TODO checks.
      repo = Rugged::Repository.new(connect_string)

      return true
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
<<<<<<< HEAD
    end

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
=======

    end

>>>>>>> 38a7a7a571c732051a2d592c5d99ad93e617a2ae

    # Static method: Reports if a Git repository exists.
    # Done in a similarly hacky method as the SVN side.
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


<<<<<<< HEAD


=======
>>>>>>> 38a7a7a571c732051a2d592c5d99ad93e617a2ae
    ####################################################################
    ##  Semi-private class methods (one should not use them from outside
    ##  this class).
    ####################################################################

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


<<<<<<< HEAD
    ####################################################################
    ##  Private method definitions
    ####################################################################

    private


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

     # Returns a Repository::TransAction object, to work with. Do operations,
    # like 'add', 'remove', etc. on the transaction instead of the repository
    def get_transaction(user_id, comment="")
      if user_id.nil?
        raise "Expected a user_id (Repository.get_transaction(user_id))"
      end
      return Repository::Transaction.new(user_id, comment)
    end


    # Carries out actions on a Git repository stored in
    # 'transaction'. In case of certain conflicts corresponding
    # Repositor::Conflict(s) are added to the transaction object
    def commit(transaction)
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


  end

       # Convenience class, so that we can work on Revisions rather
  # than repositories
  class GitRevision < Repository::AbstractRevision

    # Constructor; Check if revision is actually present in
    # repository
    def initialize(revision_number, repo)
      @repo = repo
      begin

        #TODO we proably dont need this method...
        @revision = revision_number.target

      end
      super(revision_number)
    end

     def path_exists?(path)
      debugger
      @repo #todo
    end

=======
>>>>>>> 38a7a7a571c732051a2d592c5d99ad93e617a2ae
  end

end