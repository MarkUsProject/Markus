require "svn/repos" # load SVN Ruby bindings
require "svn/client"
require "digest/md5"
require File.join(File.dirname(__FILE__),'repository') # load repository module

module Repository

  # subversion specific module constants
  if !defined? SVN_CONSTANTS # avoid constants already defined warnings
    SVN_CONSTANTS = {
      author: Svn::Core::PROP_REVISION_AUTHOR,
      date: Svn::Core::PROP_REVISION_DATE,
      mime_type: Svn::Core::PROP_MIME_TYPE
    }
  end
  if !defined? SVN_FS_TYPES
    SVN_FS_TYPES = {fsfs: Svn::Fs::TYPE_FSFS, bdb: Svn::Fs::TYPE_BDB}
  end

  class InvalidSubversionRepository < Repository::ConnectionError; end

  # Implements AbstractRepository for Subversion repositories
  # It implements the following paradigm:
  #   1. Repositories are created by using SubversionRepository.create()
  #   2. Existing repositories are opened by using either SubversionRepository.open()
  #      or SubversionRepository.new()
  class SubversionRepository < Repository::AbstractRepository

    if !defined? CLOSEABLE_VERSION
      CLOSEABLE_VERSION = "1.6.5"
    end

    # Constructor: Connects to an existing Subversion
    # repository, using Ruby bindings; Note: A repository has to be
    # created using SubversionRepository.create(), it it is not yet existent
    def initialize(connect_string)
      # Check if configuration is in order
      unless MarkusConfigurator.markus_config_repository_admin?
        raise ConfigurationError.new('Init: Required config ' \
                                     "'IS_REPOSITORY_ADMIN' not set")
      end
      if MarkusConfigurator.markus_config_repository_permission_file.nil?
        raise ConfigurationError.new('Required config ' \
                                     "'REPOSITORY_PERMISSION_FILE' not set")
      end
      begin
        super(connect_string) # dummy call to super
      rescue NotImplementedError; end
      @repos_path = connect_string
      @closed = false
      @repos_auth_file = MarkusConfigurator
                         .markus_config_repository_permission_file ||
                         File.dirname(connect_string) + '/svn_authz'
      @repos_admin = MarkusConfigurator.markus_config_repository_admin?
      if (SubversionRepository.repository_exists?(@repos_path))
        @repos = Svn::Repos.open(@repos_path)
      else
        raise "Repository does not exist at path \"" + @repos_path + "\""
      end
    end

    # Static method: Creates a new Subversion repository at
    # location 'connect_string'
    def self.create(connect_string)
      if SubversionRepository.repository_exists?(connect_string)
        raise RepositoryCollision.new("There is already a repository at #{connect_string}")
      end
      if File.exists?(connect_string)
        raise IOError.new("Could not create a repository at #{connect_string}: some directory with same name exists already")
      end

      # create the repository using the ruby bindings
      fs_config = {Svn::Fs::CONFIG_FS_TYPE => Repository::SVN_FS_TYPES[:fsfs]}
      repository = Svn::Repos.create(connect_string, {}, fs_config) #raises exception if not successful

      if SubversionRepository.closeable?
        repository.close
      end

      return true
    end

    # Static method: Opens an existing Subversion repository
    # at location 'connect_string'
    def self.open(connect_string)
      return SubversionRepository.new(connect_string)
    end

    # Static method: Yields an existing Subversion repository and closes it afterwards
    def self.access(connect_string)
      repository = self.open(connect_string)
      yield repository
      repository.close
    end

    # Static method: Deletes an existing Subversion repository
    def self.delete(repo_path)
      Svn::Repos::delete(repo_path)
    end

    # method : Export an existing Subversion repository to a new folder
    #
    # If a filepath is given, the repo_dest_dir needs to point to a file, and
    # all the repository on that path need to exist, or the export will fail.
    def export(repo_dest_dir, filepath=nil, revision_number=nil)
      # Modify the path of the repository
      # If libsvn-ruby raise a segfault, check the first argument of
      # Svn::Client::export which must be an URI (ex : file:///home/...)

      if !filepath.nil?
        repo_path_dir = "file://" + File.join(expand_path(@repos_path),
                                              filepath)
      else
        repo_path_dir = "file://" + expand_path(@repos_path)
      end

      ctx = Svn::Client::Context.new

      # don't fail on non CA signed ssl server
      ctx.add_ssl_server_trust_file_provider
      setup_auth_baton(ctx.auth_baton)
      ctx.add_username_provider

      # username and password
      ctx.add_simple_prompt_provider(0) do |cred, realm, username, may_save|
        cred.username = "markus"
        cred.password = "markus"
        cred.may_save = false
      end

      # Raise an error if the destination repository already exists
      if (File.exists?(repo_dest_dir))
        raise(ExportRepositoryAlreadyExists,
              "Exported repository already exists")
      end

      begin
        result = ctx.export(repo_path_dir, repo_dest_dir, revision_number, nil)
      end

      return result
    end

    # Static method:  Returns whether or not the available Svn library supports
    # closing
    def self.closeable?
      return Svn::Client.version.to_s >= CLOSEABLE_VERSION
    end

    # Closes the repository
    def close
      if self.class.closeable?
        @repos.close
      end
      @closed = true
    end

    # Returns whether or not repository is closed
    def closed?
      if self.class.closeable?
        return @repos.closed?
      end
      return @closed
    end


    # Static method: Reports if a Subversion repository exists
    # It's in fact a pretty hacky method checking for files typical
    # for Subversion repositories
    def self.repository_exists?(repos_path)
      repos_meta_files_exist = false
      if File.exist?(File.join(repos_path, "conf"))
        if File.exist?(File.join(repos_path, "conf/svnserve.conf"))
          if File.exist?(File.join(repos_path, "format"))
            repos_meta_files_exist = true
          end
        end
      end
      return repos_meta_files_exist
    end

    # Given a single object, or an array of objects of type
    # RevisionFile, try to find the file in question, and
    # return it as a string
    def stringify_files(files)
      expects_array = files.kind_of? Array
      if (!expects_array)
        files = [files]
      end
      files.collect! {|file|
        if (!file.kind_of? Repository::RevisionFile)
          raise TypeError.new("Expected a Repository::RevisionFile")
        end
        begin
          @repos.fs.root(file.from_revision).file_contents(File.join(file.path, file.name)){|f| f.read}
        rescue Svn::Error::FS_NOT_FOUND
          raise FileDoesNotExistConflict.new(File.join(file.path, file.name))
        end
      }
      if (!expects_array)
        return files.first
      else
        return files
      end
    end
    alias download_as_string stringify_files # create alias

    # Generate and write the SVN authorization file for the repo.
    def self.__set_all_permissions
      return true if !MarkusConfigurator.markus_config_repository_admin?
      valid_groupings_and_members = {}
      assignments = Assignment.all
      assignments.each do |assignment|
        valid_groupings = assignment.valid_groupings
        valid_groupings.each do |gr|
          accepted_students = gr.accepted_students
          accepted_students = accepted_students.map(&:user_name)
          valid_groupings_and_members[gr.group.repo_name] = accepted_students
        end
      end
      tas = Ta.all
      tas = tas.map(&:user_name)
      admins = Admin.all
      admins = admins.map(&:user_name)
      tas_and_admins = tas + admins
      invalid_groups = Group.all
      invalid_groups = invalid_groups.map(&:repository_name)
      authz_string = ''
      valid_groupings_and_members.each do |repo_name, students|
        authz_string += "[#{repo_name}:/]\n"
        students.each do |user_name|
          authz_string += "#{user_name} = rw\n"
        end
        tas_and_admins.each do |admin_user|
          authz_string += "#{admin_user} = rw\n"
        end
        authz_string += "\n"
        invalid_groups.delete(repo_name)
      end
      invalid_groups.each do |repo_name|
        authz_string += "[#{repo_name}:/]\n"
        tas_and_admins.each do |admin_user|
          authz_string += "#{admin_user} = rw\n"
        end
        authz_string += "\n"
      end
      __write_out_authz_file(authz_string)
    end

    # Returns a Repository::SubversionRevision instance
    # holding the latest Subversion repository revision
    # number
    def get_latest_revision
      return get_revision(latest_revision_number())
    end

    # Returns revision_number wrapped
    # as a SubversionRevision instance
    def get_revision(revision_number)
      return Repository::SubversionRevision.new(revision_number, self)
    end

    # Returns a SubversionRevision instance representing
    # a revision at a current timestamp
    #    target_timestamp
    # should be a Ruby Time instance
    def get_revision_by_timestamp(target_timestamp, path = nil)
      if !target_timestamp.kind_of?(Time)
        raise "Was expecting a timestamp of type Time"
      end
      target_timestamp = target_timestamp.utc
      if !path.nil?
        # latest_revision_number will fail if the path does not exist at the given revision number or less than
        # the revision number.  The begin and ensure statement is to ensure that there is a revision return.
        # Default is set to revision 0.
        revision_number = 0
        begin
          revision_number = latest_revision_number(path, get_revision_number_by_timestamp(target_timestamp))
        ensure
          return get_revision(revision_number)
        end
      else
        return get_revision(get_revision_number_by_timestamp(target_timestamp))
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

    # Carries out actions on a Subversion repository stored in
    # 'transaction'. In case of certain conflicts corresponding
    # Repositor::Conflict(s) are added to the transaction object
    def commit(transaction)
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

    # Adds a user with given permissions to the repository
    def add_user(user_id, permissions)
      if @repos_admin # Are we admin?
        if !File.exist?(@repos_auth_file)
          File.open(@repos_auth_file, "w").close() # create file if not existent
        end

        retval = false
        repo_permissions = {}
        File.open(@repos_auth_file, "r+") do |auth_file|
          auth_file.flock(File::LOCK_EX)
          # get current permissions from file
          file_content = auth_file.read()
          if (file_content.length != 0)
            repo_permissions = get_repo_permissions_from_file_string(file_content)
          end
          if repo_permissions.key?(user_id)
            raise UserAlreadyExistent.new(user_id + " already existent")
          end
          svn_permissions = self.class.__translate_to_svn_perms(permissions)
          repo_permissions[user_id] = svn_permissions
          # inject new permissions into file string
          write_string = inject_permissions(repo_permissions, defined?(file_content)? file_content: "")
          # rewind, so that mime-type is preserved
          auth_file.rewind
          auth_file.truncate(0) # truncate file
          retval = (auth_file.write(write_string) == write_string.length)
          auth_file.flock(File::LOCK_UN) # release lock
        end
        return retval
      else
        raise NotAuthorityError.new("Unable to modify permissions: Not in authoritative mode!")
      end
    end

    # Gets a list of users with AT LEAST the provided permissions.
    # Returns nil if there aren't any.
    def get_users(permissions)
      if svn_auth_file_checks() # do basic file checks
        repo_permissions = {}
        File.open(@repos_auth_file) do |auth_file|
          auth_file.flock(File::LOCK_EX)
          file_content = auth_file.read()
          if (file_content.length != 0)
            repo_permissions = get_repo_permissions_from_file_string(file_content)
          end
          auth_file.flock(File::LOCK_UN) # release lock
        end
        result_list = []
        repo_permissions.each do |user, perm|
          if self.class.__translate_perms_from_file(perm) >= permissions
            result_list.push(user)
          end
        end
        if !result_list.empty?
          return result_list
        else
          return nil
        end
      end
    end

    # Gets permissions of a particular user
    def get_permissions(user_id)
      if svn_auth_file_checks() # do basic file checks
        repo_permissions = {}
        File.open(@repos_auth_file) do |auth_file|

          auth_file.flock(File::LOCK_EX)
          file_content = auth_file.read()
          if (file_content.length != 0)
            repo_permissions = get_repo_permissions_from_file_string(file_content)
          end
          auth_file.flock(File::LOCK_UN) # release lock
        end
        if !repo_permissions.key?(user_id)
          raise UserNotFound.new(user_id + " not found")
        end
        return self.class.__translate_perms_from_file(repo_permissions[user_id])
      end
    end

    # Set permissions for a given user
    def set_permissions(user_id, permissions)
      if @repos_admin # Are we admin?
        if !File.exist?(@repos_auth_file)
          File.open(@repos_auth_file, "w").close() # create file if not existent
        end

        retval = false
        repo_permissions = {}
        File.open(@repos_auth_file, "r+") do |auth_file|
          auth_file.flock(File::LOCK_EX)
          # get current permissions from file
          file_content = auth_file.read()
          if (file_content.length != 0)
            repo_permissions = get_repo_permissions_from_file_string(file_content)
          end
          if !repo_permissions.key?(user_id)
            raise UserNotFound.new(user_id + " not found")
          end
          svn_permissions = self.class.__translate_to_svn_perms(permissions)
          repo_permissions[user_id] = svn_permissions
          # inject new permissions into file string
          write_string = inject_permissions(repo_permissions, defined?(file_content)? file_content: "")
          # rewind, so that mime-type is preserved
          auth_file.rewind
          auth_file.truncate(0) # truncate file
          retval = (auth_file.write(write_string) == write_string.length)
          auth_file.flock(File::LOCK_UN) # release lock
        end
        return retval
      else
        raise NotAuthorityError.new("Unable to modify permissions: Not in authoritative mode!")
      end
    end

    # Delete user from access list
    def remove_user(user_id)
      if @repos_admin # Are we admin?
        if !File.exist?(@repos_auth_file)
          File.open(@repos_auth_file, "w").close() # create file if not existent
        end

        retval = false
        File.open(@repos_auth_file, "r+") do |auth_file|
          auth_file.flock(File::LOCK_EX)
          # get current permissions from file
          file_content = auth_file.read()
          if (file_content.length != 0)
            repo_permissions = get_repo_permissions_from_file_string(file_content)
          end
          if !repo_permissions.key?(user_id)
            raise UserNotFound.new(user_id + " not found")
          end
          repo_permissions.delete(user_id) # delete user_id
          # inject new permissions into file string
          write_string = inject_permissions(repo_permissions, defined?(file_content)? file_content: "")
          # rewind, so that mime-type is preserved
          auth_file.rewind
          auth_file.truncate(0) # truncate file
          retval = (auth_file.write(write_string) == write_string.length)
          auth_file.flock(File::LOCK_UN) # release lock
        end
        return retval
      else
        raise NotAuthorityError.new("Unable to modify permissions: Not in authoritative mode!")
      end
    end

    # Sets permissions over several repositories. Use set_permissions to set
    # permissions on a single repository.
    def self.set_bulk_permissions(repo_names, user_id_permissions_map)
      # Check if configuration is in order
      unless MarkusConfigurator.markus_config_repository_admin?
        raise NotAuthorityError.new("Unable to set bulk permissions:  Not in authoritative mode!");
      end

      # Read in the authz file
      authz_file_contents = self.__read_in_authz_file()

      # Parse the file contents into to something we can work with
      repo_permissions = self.__parse_authz_file(authz_file_contents)
      # Set / clobber permissions on each group for this user
      repo_names.each do |repo_name|
        repo_name = File.basename(repo_name)
        user_id_permissions_map.each do |user_id, permissions|
          if repo_permissions[repo_name].nil?
            repo_permissions[repo_name] = {}
          end
          repo_permissions[repo_name][user_id] = permissions
        end
      end

      # Translate the hash into the svn authz file format
      authz_file_contents = self.__prepare_authz_string(repo_permissions)

      # Write out the authz file
      return self.__write_out_authz_file(authz_file_contents)
    end

    # Deletes permissions over several repositories. Use remove_user to remove
    # permissions of a single repository.
    def self.delete_bulk_permissions(repo_names, user_ids)
      # Check if configuration is in order
      if !MarkusConfigurator.markus_config_repository_admin?
        raise NotAuthorityError.new("Unable to delete bulk permissions:  Not in authoritative mode!");
      end

      # Read in the authz file
      authz_file_contents = self.__read_in_authz_file()

      # Parse the file contents into to something we can work with
      repo_permissions = self.__parse_authz_file(authz_file_contents)

      # Delete the user_id for each repository
      repo_names.each do |repo_name|
        repo_name = File.basename(repo_name)
        user_ids.each do |user_id|
          repo_permissions[repo_name].delete(user_id)
        end
      end

      # Translate the hash into the svn authz file format
      authz_file_contents = self.__prepare_authz_string(repo_permissions)

      # Write out the authz file
      return self.__write_out_authz_file(authz_file_contents)
    end

    # Converts a pathname to an absolute pathname
    def expand_path(file_name, dir_string = "/")
      expanded = File.expand_path(file_name, dir_string)
      if RUBY_PLATFORM =~ /(:?mswin|mingw)/ #only if the platform is Windows
        expanded = expanded[2..-1]#remove the drive letter
      end
      return expanded
    end

    ####################################################################
    ##  Semi-private class methods (one should not use them from outside
    ##  this class).
    ####################################################################

    # Semi-private class method
    def self.__read_in_authz_file
      # Check if configuration is in order
      unless MarkusConfigurator.markus_config_repository_admin?
        raise NotAuthorityError.new('Unable to read authsz file: ' \
                                    'Not in authoritative mode!')
      end
      if MarkusConfigurator.markus_config_repository_permission_file.nil?
        raise ConfigurationError.new('Required config ' \
                                     "'REPOSITORY_PERMISSION_FILE' not set")
      end
      unless File.exist?(MarkusConfigurator
                         .markus_config_repository_permission_file)
        # create file if it doesn't exist
        File.open(MarkusConfigurator
                    .markus_config_repository_permission_file, 'w').close
      end
      # Load up the Permissions:
      file_content = ""
      File.open(MarkusConfigurator.markus_config_repository_permission_file,
                'r+') do |auth_file|
        auth_file.flock(File::LOCK_EX)
        file_content = auth_file.read()
        auth_file.flock(File::LOCK_UN) # release lock
      end
      return file_content
    end

    # Semi-private class method
    def self.__write_out_authz_file(authz_file_contents)
      # Check if configuration is in order
      unless MarkusConfigurator.markus_config_repository_admin?
        raise NotAuthorityError.new(
          'Unable to write authsz file: Not in authoritative mode!')
      end

      if MarkusConfigurator.markus_config_repository_permission_file.nil?
        raise ConfigurationError.new('Required config ' \
                                     "'REPOSITORY_PERMISSION_FILE' not set")
      end

      unless File.exist?(MarkusConfigurator
                         .markus_config_repository_permission_file)
        # create file if not existent
        File.open(MarkusConfigurator.markus_config_repository_permission_file,
                  'w').close
      end
      result = false
      File.open(MarkusConfigurator.markus_config_repository_permission_file,
                'w+') do |auth_file|
        auth_file.flock(File::LOCK_EX)
        # Blast out the string to the file
        result = (auth_file.write(authz_file_contents) == authz_file_contents.length)
        auth_file.flock(File::LOCK_UN) # release lock
      end
      return result
    end

    # Semi-private class method: Parses a subversion authz file passed in as a string
    def self.__parse_authz_file(authz_string)
      permissions_mapping = {}

      permissions_array = authz_string.scan(/\[(.+):\/\]\n([\w\s=]+)/)
      permissions_array.each do |permissions_group|
        # The first match is the group repository name
        user_permissions = {}
        raw_users_permissions = permissions_group[1].scan(/\s*(\w+)\s*=\s*(\w+)\s*/)
        raw_users_permissions.each do |raw_user_permissions|
          user_permissions[raw_user_permissions[0]] = self.__translate_perms_from_file(raw_user_permissions[1])
        end
        permissions_mapping[permissions_group[0]] = user_permissions
      end
      return permissions_mapping
    end

    # Semi-private class method: Transforms passed in permissions into
    # subversion authz file syntax
    def self.__prepare_authz_string(permissions)
      result = ""
      permissions.each do |repository_name, users_permissions|
        result += "[#{repository_name}:/]\n"
        users_permissions.each do |user_id, user_permissions|
          user_permissions_string = self.__translate_to_svn_perms(user_permissions)
          result += "#{user_id} = #{user_permissions_string}\n"
        end
        result += "\n"
      end
      return result
    end

    ####################################################################
    ##  The following stuff is semi-private. As a general rule don't use
    ##  it directly. The only reason it's public, is that
    ##  SubversionRevision needs to have access.
    ####################################################################

    # Not (!) part of the AbstractRepository API:
    # Check if given file or path exists in repository beeing member of
    # the provided revision
    def __path_exists?(path, revision=nil)
      return @repos.fs.root(revision).check_path(path) != 0
    end

    # Not (!) part of the AbstractRepository API:
    # Returns a hash of files/directories part of the requested
    # revision; Don't use it directly, use SubversionRevision's
    # 'files_at_path' instead
    def __get_files(path="/", revision_number=nil)
      begin
        entries = @repos.fs.root(revision_number).dir_entries(path)
      rescue Exception
        raise FileDoesNotExist.new("#{path} does not exist in the repository for revision #{revision_number}")
      end
      entries.each do |key, value|
        entries[key] = (value.kind == 1) ? :file : :directory
      end
      return entries
    end

    # Not (!) part of the AbstractRepository API:
    # Returns
    #    prop
    # of Subversion repository
    def __get_property(prop, rev=nil)
      return @repos.prop(Repository::SVN_CONSTANTS[prop] || prop.to_s, rev)
    end

    # Not (!) part of the AbstractRepository API:
    # Returns
    #    prop
    # of Subversion repository file

    def __get_file_property(prop, path, revision_number)
      return @repos.fs.root(revision_number).node_prop(path, Repository::SVN_CONSTANTS[prop])
    end

    # Not (!) part of the AbstractRepository API:
    # Returns
    #    The last modified date
    # of a Subversion repository file or directory

    def __get_node_last_modified_date(path, revision_number)
      return @repos.fs.root(revision_number).stat(path).time2
    end

    # Not (!) part of the AbstractRepository API:
    # This function is very similar to @repos.fs.history(); however, it's been altered a little
    # to return only an array of revision numbers. This function, in contrast to the original,
    # takes multiple paths and returns one large history for all paths given.
    def __get_history(paths, starting_revision=nil, ending_revision=nil)
      # We do the to_i's because we want to leave the value nil if it is.
      if (starting_revision.to_i < 0)
        raise "Invalid starting revision " + starting_revision.to_i.to_s + "."
      end
      revision_numbers = []
      paths = [paths].flatten
      paths.each do |path|
        hist = []
        history_function = Proc.new do |path, revision|
          yield(path, revision) if block_given?
          hist << revision
        end
        begin
          Svn::Repos.history2(@repos.fs, path, history_function, nil, starting_revision || 0,
                              ending_revision || @repos.fs.youngest_rev, true)
        rescue Svn::Error::FS_NOT_FOUND
          raise Repository::FileDoesNotExistConflict.new(path)
        rescue Svn::Error::FS_NO_SUCH_REVISION
          raise "Ending revision " + ending_revision.to_s + " does not exist."
        end
        revision_numbers.concat hist
      end
      return revision_numbers.sort.uniq
    end

    # Helper method to translate internal permissions to Subversion
    # permissions
    def self.__translate_to_svn_perms(permissions)
      case (permissions)
      when Repository::Permission::READ
        return "r"
      when Repository::Permission::READ_WRITE
        return "rw"
      else raise "Unknown permissions"
      end # end case
    end

    # Helper method to translate Subversion permissions to internal
    # permissions
    def self.__translate_perms_from_file(perm_string)
      case (perm_string)
      when "r"
        return Repository::Permission::READ
      when "rw"
        return Repository::Permission::READ_WRITE
      else raise "Unknown permissions"
      end # end case
    end

    # Returns a list of paths changed at a particular revision.
    # This seems to include deleted files, while the above methods don't.
    def __get_file_paths(revision_number)
      rev = @repos.fs.root(revision_number)
      rev.paths_changed.keys
    end

    ####################################################################
    ##  Private method definitions
    ####################################################################

    private

    # Function necessary for exporting the svn repository
    def setup_auth_baton(auth_baton)
      auth_baton[Svn::Core::AUTH_PARAM_CONFIG_DIR] = nil
      auth_baton[Svn::Core::AUTH_PARAM_DEFAULT_USERNAME] = nil
    end

    # Returns the most recent revision of the repository. If a path is specified,
    # the youngest revision is returned for that path; if a revision is also specified,
    # the function will return the youngest revision that is equal to or older than the one passed.
    #
    # This will only work for paths that have not been deleted from the repository.
    def latest_revision_number(path = nil, revision_number = nil)
      if (!path.nil?)
        begin
          data = Svn::Repos.get_committed_info(@repos.fs.root(revision_number || @repos.fs.youngest_rev), path)
          return data[0]
        rescue Svn::Error::FS_NOT_FOUND
          raise Repository::FileDoesNotExistConflict.new(path)
        rescue Svn::Error::FS_NO_SUCH_REVISION
          raise "Revision " + revision_number.to_s + " does not exist."
        end
      else
        return @repos.fs.youngest_rev
      end
    end

    # Assumes timestamp is a Time object (which is part of the Ruby
    # standard library)
    def get_revision_number_by_timestamp(target_timestamp, path = nil)
      if !target_timestamp.kind_of?(Time)
        raise "Was expecting a timestamp of type Time"
      end
      @repos.dated_revision(target_timestamp)
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
      # Note: this check is inconsistent with the MemoryRepository
      if latest_revision_number(path).to_i > expected_revision_number.to_i
        raise Repository::FileOutOfSyncConflict.new(path)
      end
      txn = write_file(txn, path, file_data, mime_type)
      return txn
    end

    def write_file(txn, path, file_data=nil, mime_type=nil)
      if (!__path_exists?(path))
        pieces = path.split("/").delete_if {|x| x == ""}
        dir_path = ""

        (0..pieces.length - 2).each do |index|
          dir_path += "/" + pieces[index]
          txn = make_directory(txn, dir_path)
        end
        txn = make_file(txn, path)
      end
      stream = txn.root.apply_text(path)
      stream.write(file_data)
      stream.close
      # Set the mime type...
      txn.root.set_node_prop(path, SVN_CONSTANTS[:mime_type], mime_type)
      return txn
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

    # Helper method to check file permissions of svn auth file
    def svn_auth_file_checks
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
    # users <=> svn permissions mapping and the current file contents of
    # the svn authz file as a string
    def inject_permissions(users_permissions, auth_string)
      repo_name = File.basename(@repos_path)
      auth_string = auth_string.strip()
      map_string = perm_mapping_to_svn_authz_string(users_permissions)
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
    def perm_mapping_to_svn_authz_string(users_perms)
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

  end # end class SubversionRepository

  # Convenience class, so that we can work on Revisions rather
  # than repositories
  class SubversionRevision < Repository::AbstractRevision

    # Constructor; Check if revision is actually present in
    # repository
    def initialize(revision_number, repo)
      @repo = repo
      begin
        @timestamp = @repo.__get_property(:date, revision_number)
        if @timestamp.instance_of?(String)
          @timestamp = Time.parse(@timestamp).localtime
        elsif @timestamp.instance_of?(Time)
          @timestamp = @timestamp.localtime
        end
      rescue Svn::Error::FsNoSuchRevision
        raise RevisionDoesNotExist
      end
      super(revision_number)
    end

    # Return all of the files in this repository at the root directory
    def files_at_path(path)
      return files_at_path_helper(path)
    end

    def path_exists?(path)
      @repo.__path_exists?(path, @revision_number)
    end

    # Return all directories at 'path' (including subfolders?!)
    def directories_at_path(path='/')
      result = Hash.new(nil)
      raw_contents = @repo.__get_files(path, @revision_number)
      raw_contents.each do |file_name, type|
        if type == :directory
          last_modified_revision = @repo.__get_history(File.join(path, file_name)).last
          last_modified_date = @repo.__get_node_last_modified_date(File.join(path, file_name), @revision_number)
          new_directory = Repository::RevisionDirectory.new(@revision_number, {
            name: file_name,
            path: path,
            last_modified_revision: last_modified_revision,
            last_modified_date: last_modified_date,
            changed: (last_modified_revision == @revision_number),
            user_id: @repo.__get_property(:author, @revision_number)
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

    # Return the names of changed files at this revision at 'path'
    def changed_filenames_at_path(path)
      paths = @repo.__get_file_paths(@revision_number)
      paths.select { |p| p.start_with? ('/' + path) }
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
              name: file_name,
              path: path,
              last_modified_revision: last_modified_revision,
              changed: (last_modified_revision == @revision_number),
              user_id: @repo.__get_property(:author, last_modified_revision),
              mime_type: @repo.__get_file_property(:mime_type, File.join(path, file_name), last_modified_revision),
              last_modified_date: last_modified_date
            })
            result[file_name] = new_file
          end
        end
      end
      return result
    end
  end

end
