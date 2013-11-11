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
      if GitRepository.repository_exists?(connect_string)
        raise RepositoryCollision.new("There is already a repository at #{connect_string}")
      end
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


  end

end