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


    # Static method: Creates a new Git repository at
    # location 'connect_string'
    def self.create(connect_string)
      
      #Check if repo exists
      if File.exists?(connect_string)
        raise IOError.new("Could not create a repository at #{connect_string}: some directory with same name exists already")
      end

      #Create it
      repo = Rugged::Repository.init_at(connect_string, :bare)

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

    end


       ####################################################################
    ##  Semi-private class methods (one should not use them from outside
    ##  this class).
    ####################################################################

    # Semi-private class method: Reads in Repository.conf[:REPOSITORY_PERMISSION_FILE]
    def self.__read_in_authz_file()
      # Check if configuration is in order
      if Repository.conf[:REPOSITORY_PERMISSION_FILE].nil?
        raise ConfigurationError.new("Required config 'REPOSITORY_PERMISSION_FILE' not set")
      end
      if !File.exist?(Repository.conf[:REPOSITORY_PERMISSION_FILE])
        File.open(Repository.conf[:REPOSITORY_PERMISSION_FILE], "w").close() # create file if not existent
      end
      # Load up the Permissions:
      file_content = ""
      File.open(Repository.conf[:REPOSITORY_PERMISSION_FILE], "r+") do |auth_file|
        auth_file.flock(File::LOCK_EX)
        file_content = auth_file.read()
        auth_file.flock(File::LOCK_UN) # release lock
      end
      return file_content
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


  end

end