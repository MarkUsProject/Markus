require 'rugged'

require File.join(File.dirname(__FILE__), 'repository') # load repository module

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
        raise ConfigurationError.new("Required config 'IS_REPOSITORY_ADMIN' not set")
      end
      if MarkusConfigurator.markus_config_repository_storage.nil?
        raise ConfigurationError.new("Required config 'REPOSITORY_STORAGE' not set")
      end
      if MarkusConfigurator.markus_config_repository_permission_file.nil?
        raise ConfigurationError.new("Required config 'REPOSITORY_PERMISSION_FILE' not set")
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
          parents: repo.empty? ? [] : [repo.head.target].compact, # compact if target returns nil (suggested upstream)
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
        raise RepositoryCollision.new("There is already a repository at #{connect_string}")
      end
      if File.exists?(connect_string)
        raise IOError.new("Could not create a repository at #{connect_string}: some directory with same name exists
                           already")
      end

      # Repo is created bare, then clone it in the repository storage location
      repo_path, _sep, repo_name = connect_string.rpartition(File::SEPARATOR)
      bare_path = File.join(repo_path, 'bare', "#{repo_name}.git")
      Rugged::Repository.init_at(bare_path, :bare)
      bare_config = Rugged::Config.new(File.join(bare_path, 'config'))
      bare_config['core.logAllRefUpdates'] = true # enable reflog to keep track of push dates
      bare_config['gc.reflogExpire'] = 'never' # never garbage collect the reflog
      repo = Rugged::Repository.clone_at(bare_path, connect_string)

      # Do an initial commit with the .required_files.json
      required = Assignment.get_required_files
      required_path = File.join(connect_string, '.required.json')
      File.open(required_path, 'w') do |req|
        req.write(required.to_json)
      end
      oid = Rugged::Blob.from_workdir(repo, '.required.json')
      repo.index.add(path: '.required.json', oid: oid, mode: 0100644)
      GitRepository.do_commit_and_push(repo, 'Markus', 'Initial commit.')

      # Set up hooks
      MarkusConfigurator.markus_config_repository_hooks.each do |hook_symbol, hook_script|
        FileUtils.ln_s(hook_script, File.join(bare_path, 'hooks', hook_symbol.to_s))
      end

      true
    end

    # Static method: Opens an existing Git repository
    # at location 'connect_string'
    def self.open(connect_string)
      GitRepository.new(connect_string)
    end

    # static method that should yield to a git repo and then close it
    def self.access(connect_string)
      yield GitRepository.open(connect_string)
    end

    # static method that deletes the git repo
    # rm everything? or only .git?
    def self.delete(repo_path)
      FileUtils.rm_rf(repo_path)
    end

    def get_revision(revision_hash)
      Repository::GitRevision.new(revision_hash, self)
    end

    def get_latest_revision
      get_revision(@repos.last_commit.oid)
    end

    # Gets the first revision before +target_timestamp+. If +path+ is not nil, then gets the first revision before
    # +target_timestamp+ with changes under +path+. The +target_timestamp+ is matched with push dates in the git reflog,
    # because a commit date can be arbitrarily crafted.
    def get_revision_by_timestamp(target_timestamp, path = nil)
      repo_path, _sep, repo_name = @repos_path.rpartition(File::SEPARATOR)
      bare_path = File.join(repo_path, 'bare', "#{repo_name}.git")
      # use the git reflog to get a list of pushes, then find first push_time <= target_timestamp
      bare_repo = Rugged::Repository.new(bare_path)
      reflog = bare_repo.ref('refs/heads/master').log.reverse
      push_info = nil
      reflog.each_with_index do |reflog_entry, i|
        push_time = reflog_entry[:committer][:time]
        if push_time <= target_timestamp.in_time_zone
          push_info = OpenStruct.new
          push_info.sha = reflog_entry[:id_new]
          push_info.time = push_time
          push_info.index = i
          break
        end
      end
      walker = Rugged::Walker.new(@repos)
      unless push_info.nil?
        # find first commit that changes path, topologically equal or before the tip of the push
        walker.sorting(Rugged::SORT_TOPO)
        walker.push(push_info.sha)
        walker.each do |commit|
          if reflog.length > push_info.index + 1 # walk the reflog while walking commits
            next_reflog_entry = reflog[push_info.index + 1]
            if commit.oid == next_reflog_entry[:id_new]
              push_info.sha = next_reflog_entry[:id_new]
              push_info.time = next_reflog_entry[:committer][:time]
              push_info.index += 1
            end
          end
          revision = get_revision(commit.oid)
          if path.nil? || revision.changes_at_path?(path)
            revision.timestamp = push_info.time
            return revision
          end
        end
      end

      # return the first revision as a backup plan
      walker.reset
      walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
      walker.push(@repos.last_commit)
      get_revision(walker.first.oid)
    end

    def get_all_revisions
      walker = Rugged::Walker.new(@repos)
      walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_DATE)
      walker.push(@repos.last_commit)
      walker.map do |commit|
        get_revision(commit.oid)
      end
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
      @repos
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

    # Given a RevisionFile object, returns its content as a string.
    def stringify(file)
      revision = get_revision(file.from_revision)
      blob = revision.get_entry(File.join(file.path, file.name))
      blob.content
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

    # Returns a Repository::TransAction object, to work with. Do operations,
    # like 'add', 'remove', etc. on the transaction instead of the repository
    def get_transaction(user_id, comment = '')
      if user_id.nil?
        raise 'Expected a user_id (Repository.get_transaction(user_id))'
      end
      Repository::Transaction.new(user_id, comment)
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
                        job[:expected_revision_identifier])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :replace
          begin
            replace_file(job[:path], job[:file_data], transaction.user_id,
                         job[:expected_revision_identifier])
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

    # Creates and commits a file to the repository
    def add_file(path, file_data = nil, author)
      if get_latest_revision.path_exists?(path)
        raise Repository::FileExistsConflict.new(path)
      end
      write_file(path, file_data, author)
    end

    # Removes a file from the repository
    def remove_file(path, author, expected_revision_identifier)
      if @repos.last_commit.oid != expected_revision_identifier
        raise Repository::FileOutOfSyncConflict.new(path)
      end
      unless get_latest_revision.path_exists?(path)
        raise Repository::FileDoesNotExist.new(path)
      end

      File.unlink(File.join(@repos_path, path))
      @repos.index.remove(path)
      GitRepository.do_commit_and_push(@repos, author, 'Removing file')
    end

    # Replaces file at provided path with file_data
    def replace_file(path, file_data, author, expected_revision_identifier)
      if @repos.last_commit.oid != expected_revision_identifier
        raise Repository::FileOutOfSyncConflict.new(path)
      end
      unless get_latest_revision.path_exists?(path)
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
      add_file(gitkeep_filename, '', 'Markus')
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

    # Constructor; checks if +revision_hash+ is actually present in +repo+.
    def initialize(revision_hash, repo)
      super(revision_hash)
      @revision_identifier_ui = @revision_identifier[0..6]
      @repo = repo.get_repos
      @commit = @repo.lookup(@revision_identifier)
      @author = @commit.author[:name]
      @timestamp = @commit.time.in_time_zone
    end

    # Gets a file or directory at +path+ from a +commit+ as a Rugged Hash.
    # The +path+ is relative to the repo root, the +commit+ can be omitted to default to this GitRevision.
    def get_entry_hash(path, commit=@commit)
      if path.start_with?(File::SEPARATOR) # transform from absolute to relative
        path = path[1..-1]
      end
      if path == '' # root Tree
        entry_hash = {name: path, oid: commit.tree_id, type: :tree, filemode: 0} # mimic Tree#path output
      else # Tree or Blob
        begin
          entry_hash = commit.tree.path(path)
        rescue Rugged::TreeError # path not valid
          entry_hash = nil
        end
      end
      entry_hash
    end

    # Gets a file or directory at +path+ from a +commit+ as a Rugged::Blob or Rugged::Tree respectively.
    # The +path+ is relative to the repo root, the +commit+ can be omitted to default to this GitRevision.
    def get_entry(path, commit=@commit)
      entry_hash = get_entry_hash(path, commit)
      if entry_hash.nil?
        entry = nil
      else
        entry = @repo.lookup(entry_hash[:oid])
      end
      entry
    end

    def path_exists?(path)
      !get_entry_hash(path).nil?
    end

    # Checks if a file or directory at +path+ (relative to the repo root) was changed by +commit+.
    # The +commit+ can be omitted to default to this revision.
    # (optimizations based on Rugged bug #343)
    def entry_changed?(path, commit=@commit)
      entry = get_entry_hash(path, commit)
      # if at a root commit, consider it changed if we have this file;
      # i.e. if we added it in the initial commit
      if commit.parents.empty?
        return entry != nil
      end
      # check each parent commit (a merge has 2+ parents)
      commit.parents.each do |parent|
        parent_entry = get_entry_hash(path, parent)
        # neither exists, no change
        if not entry and not parent_entry
          next
        # only in one of them, change
        elsif not entry or not parent_entry then
          return true
        # otherwise it's changed if their ids aren't the same
        elsif entry[:oid] != parent_entry[:oid]
          return true
        end
      end
      false
    end

    def changes_at_path?(path)
      entry_changed?(path)
    end

    # Gets all entries at directory +path+ of a specified +type+ (:blob, :tree, or nil for both), as
    # Repository::RevisionFile and Repository::RevisionDirectory.
    def entries_at_path(path, type=nil)
      # phase 1: collect all entries
      entries = {}
      path_tree = get_entry(path)
      if path_tree.nil?
        return entries
      end
      path_tree.each do |entry_hash|
        entry_type = entry_hash[:type]
        next unless type.nil? || type == entry_type
        entry_name = entry_hash[:name]
        # wrap in a RevisionFile or RevisionDirectory (paths without filename to be consistent with SVN)
        if entry_type == :blob
          mime_types = MIME::Types.type_for(entry_name)
          if mime_types.empty?
            mime_type = 'text'
          else
            mime_type = mime_types.first.content_type
          end
          entries[entry_name] = Repository::RevisionFile.new(@revision_identifier, name: entry_name, path: path,
                                                             mime_type: mime_type)
        elsif entry_type == :tree
          entries[entry_name] = Repository::RevisionDirectory.new(@revision_identifier, name: entry_name, path: path)
        end
      end
      if entries.empty?
        return entries
      end
      # phase 2: walk the git history once and collect the last commits that modified each entry
      walker_entries = entries.dup
      walker = Rugged::Walker.new(@repo)
      walker.sorting(Rugged::SORT_DATE)
      walker.push(@commit)
      walker.each do |commit|
        mod_keys = walker_entries.keys.select { |entry_name| entry_changed?(File.join(path, entry_name), commit) }
        mod_entries = walker_entries.extract!(*mod_keys)
        mod_entries.each do |_, mod_entry|
          mod_entry.last_modified_revision = commit.oid
          mod_entry.last_modified_date = commit.time.in_time_zone
          mod_entry.changed = commit.oid == @revision_identifier
          mod_entry.user_id = commit.author[:name]
        end
        break if walker_entries.empty?
      end
      entries
    end

    def files_at_path(path)
      entries_at_path(path, :blob)
    end

    def directories_at_path(path)
      entries_at_path(path, :tree)
    end

    def last_modified_date
      self.timestamp
    end
  end
end
