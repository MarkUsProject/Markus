# Implements AbstractRepository for Git repositories
# It implements the following paradigm:
#   1. Repositories are created by using ???
#   2. Existing repositories are opened by using either ???
class GitRepository < Repository::AbstractRepository

  DUMMY_FILE_NAME = '.gitkeep'.freeze

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
    if GitRepository.repository_exists?(@repos_path)
      begin
        @repos = Rugged::Repository.new(@repos_path)
        # make sure working directory is up-to-date
        @repos.fetch('origin')
        begin
          @repos.reset('master', :hard) # TODO this shouldn't be necessary, but something is messing up the repo.
        rescue Rugged::ReferenceError   # It seems the master branch might not be correctly setup at first.
        end
        @repos.reset('origin/master', :hard) # align to whatever is in origin/master
      rescue StandardError # TODO this shouldn't be necessary. It catches the case when a local repo is corrupted,
                           #      we need to prevent the corruption instead/as well
        bad_repo_path = "#{connect_string}.bad"
        FileUtils.rm_rf(bad_repo_path)
        FileUtils.mv(connect_string, bad_repo_path)
        repo_path, _sep, repo_name = connect_string.rpartition(File::SEPARATOR)
        bare_path = File.join(repo_path, 'bare', "#{repo_name}.git")
        @repos = Rugged::Repository.clone_at(bare_path, connect_string)
        m_logger = MarkusLogger.instance
        m_logger.log "Recloned corrupted git repo: #{connect_string}"
      end
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
  def self.create(connect_string, with_hooks: true)
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
    repo.index.add('.required.json')

    # Add client-side hooks
    if with_hooks && !MarkusConfigurator.markus_config_repository_client_hooks.empty?
      client_hooks_path = MarkusConfigurator.markus_config_repository_client_hooks
      FileUtils.copy_entry client_hooks_path, File.join(connect_string, 'markus-hooks')
      FileUtils.chmod 0755, File.join(connect_string, 'markus-hooks', 'pre-commit')
      repo.index.add_all('markus-hooks')
    end

    GitRepository.do_commit_and_push(repo, 'Markus', I18n.t('repo.commits.initial'))

    # Set up server-side hooks
    if with_hooks
      MarkusConfigurator.markus_config_repository_hooks.each do |hook_symbol, hook_script|
        FileUtils.ln_s(hook_script, File.join(bare_path, 'hooks', hook_symbol.to_s))
      end
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
    repo = GitRepository.open(connect_string)
    yield repo
  ensure
    repo&.close
  end

  # static method that deletes the git repo
  # rm everything? or only .git?
  def self.delete(repo_path)
    FileUtils.rm_rf(repo_path)
  end

  def self.get_checkout_command(external_repo_url, revision_hash, group_name, repo_folder=nil)
    "git clone \"#{external_repo_url}\" \"#{group_name}\" && "\
    "cd \"#{group_name}\" && "\
    "git reset --hard #{revision_hash} && "\
    "cd .."
  end

  def get_revision(revision_hash)
    GitRevision.new(revision_hash, self)
  end

  def get_latest_revision
    get_revision(@repos.last_commit.oid)
  end

  # Checks whether the next +reflog+ entry corresponds to the +commit+ id, and advances the reflog if it is.
  # Returns information about the current reflog entry.
  # In order to correctly handle merges, the reflog is navigated separately for each merge path. +reflog_entries+
  # contains the status of each of them.
  def self.try_advance_reflog!(reflog, reflog_entries, commit)
    current_reflog_entry = reflog_entries[commit.oid]
    next_index = current_reflog_entry[:index] + 1
    return current_reflog_entry if reflog.length <= next_index
    next_reflog_entry = reflog[next_index]
    return current_reflog_entry if commit.oid != next_reflog_entry[:id_new]
    current_reflog_entry[:id] = next_reflog_entry[:id_new]
    current_reflog_entry[:time] = next_reflog_entry[:committer][:time].in_time_zone
    current_reflog_entry[:index] = next_index
    current_reflog_entry
  ensure
    # update +reflog_entries+ with next commits (possibly multiple merge paths)
    commit.parent_ids.each do |parent_id|
      merge_reflog_entry = reflog_entries[parent_id]
      # if +merge_reflog_entry+ is not nil, two merge paths are reuniting: pick the earliest push time
      if merge_reflog_entry.nil? || merge_reflog_entry[:time] > current_reflog_entry[:time]
        reflog_entries[parent_id] = current_reflog_entry.clone
      end
    end
    # remove the current commit
    reflog_entries.delete(commit.oid)
  end

  # Gets the first revision +at_or_earlier_than+ some timestamp and +later_than+ some other timestamp (can be nil).
  # If +path+ is not nil, then gets only a revision with changes under +path+.
  # Push dates in the git reflog are used to compare timestamps, because a commit date can be arbitrarily crafted.
  def get_revision_by_timestamp(at_or_earlier_than, path = nil, later_than = nil)
    repo_path, _sep, repo_name = @repos_path.rpartition(File::SEPARATOR)
    bare_path = File.join(repo_path, 'bare', "#{repo_name}.git")
    # use the git reflog to get a list of pushes: find first push_time <= at_or_earlier_than && > later_than
    bare_repo = Rugged::Repository.new(bare_path)
    reflog = bare_repo.ref('refs/heads/master').log.reverse
    current_reflog_entry = {}
    reflog.each_with_index do |reflog_entry, i|
      push_time = reflog_entry[:committer][:time].in_time_zone
      return nil if !later_than.nil? && push_time <= later_than.in_time_zone
      if push_time <= at_or_earlier_than.in_time_zone
        current_reflog_entry[:id] = reflog_entry[:id_new]
        current_reflog_entry[:time] = push_time
        current_reflog_entry[:index] = i
        break
      end
    end
    return nil if current_reflog_entry.empty?
    # find first commit that changes path, topologically equal or before the push
    reflog_entries = {}
    reflog_entries[current_reflog_entry[:id]] = current_reflog_entry
    walker = Rugged::Walker.new(@repos)
    walker.sorting(Rugged::SORT_TOPO)
    walker.push(current_reflog_entry[:id])
    walker.each do |commit|
      current_reflog_entry = GitRepository.try_advance_reflog!(reflog, reflog_entries, commit)
      return nil if !later_than.nil? && current_reflog_entry[:time] <= later_than.in_time_zone
      revision = get_revision(commit.oid)
      if path.nil? || revision.changes_at_path?(path)
        revision.server_timestamp = current_reflog_entry[:time]
        return revision
      end
    end
    # no revision found
    nil
  ensure
    bare_repo.close
  end

  def get_all_revisions
    # use the git reflog to get a list of pushes
    repo_path, _sep, repo_name = @repos_path.rpartition(File::SEPARATOR)
    bare_path = File.join(repo_path, 'bare', "#{repo_name}.git")
    bare_repo = Rugged::Repository.new(bare_path)
    reflog = bare_repo.ref('refs/heads/master').log.reverse
    last_commit = @repos.last_commit
    reflog_entries = {}
    reflog_entries[last_commit.oid] = { index: -1 }
    # walk through the commits and get revisions
    walker = Rugged::Walker.new(@repos)
    walker.sorting(Rugged::SORT_TOPO)
    walker.push(last_commit)
    walker.map do |commit|
      current_reflog_entry = GitRepository.try_advance_reflog!(reflog, reflog_entries, commit)
      revision = get_revision(commit.oid)
      revision.server_timestamp = current_reflog_entry[:time]
      revision
    end
  ensure
    bare_repo.close
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
    if blob.binary?
      blob.content
    else
      blob.text
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

  # Returns a Repository::TransAction object, to work with. Do operations,
  # like 'add', 'remove', etc. on the transaction instead of the repository
  def get_transaction(user_id, comment=I18n.t('repo.commits.default'))
    if user_id.nil?
      raise 'Expected a user_id (Repository.get_transaction(user_id))'
    end
    Repository::Transaction.new(user_id, comment)
  end

  # Carries out actions on a Git repository stored in
  # 'transaction'. In case of certain conflicts corresponding
  # Repositor::Conflict(s) are added to the transaction object
  def commit(transaction)
    transaction.jobs.each do |job|
      case job[:action]
      when :add_path
        begin
          add_directory(job[:path])
        rescue Repository::Conflict => e
          transaction.add_conflict(e)
        end
      when :add
        begin
          add_file(job[:path], job[:file_data])
        rescue Repository::Conflict => e
          transaction.add_conflict(e)
        end
      when :remove
        begin
          remove_file(job[:path], job[:expected_revision_identifier])
        rescue Repository::Conflict => e
          transaction.add_conflict(e)
        end
      when :replace
        begin
          replace_file(job[:path], job[:file_data], job[:expected_revision_identifier])
        rescue Repository::Conflict => e
          transaction.add_conflict(e)
        end
      end
    end

    if transaction.conflicts?
      @repos.reset('master', :hard)
      false
    else
      GitRepository.do_commit_and_push(@repos, transaction.user_id, transaction.comment)
      true
    end
  end

  def self.internal_file_names
    [DUMMY_FILE_NAME]
  end

  ####################################################################
  ##  Private method definitions
  ####################################################################


  # Helper method to generate all the permissions for students for all groupings in all assignments.
  # This is done as a single operation to mirror the SVN repo code. We found
  # a substantial performance improvement by writing the auth file only once in the SVN case.
  def self.__update_permissions(permissions, full_access_users)

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
    sorted_permissions = permissions.sort.to_h
    CSV.open(MarkusConfigurator.markus_config_repository_permission_file, 'wb') do |csv|
      csv.flock(File::LOCK_EX)
      csv << ['*'] + full_access_users
      sorted_permissions.each do |repo_name, users|
        csv << [repo_name] + users
      end
      csv.flock(File::LOCK_UN)
    end
  end

  private_class_method :__update_permissions

  private

  # Creates a file into the repository.
  def add_file(path, file_data)
    if get_latest_revision.path_exists?(path)
      raise Repository::FileExistsConflict.new(path)
    end
    write_file(path, file_data)
  end

  # Creates an empty directory into the repository.
  # The dummy file is required so the directory gets committed.
  def add_directory(path)
    gitkeep_filename = File.join(path, DUMMY_FILE_NAME)
    add_file(gitkeep_filename, '')
  end

  # Removes a file from the repository.
  def remove_file(path, expected_revision_identifier)
    if @repos.last_commit.oid != expected_revision_identifier
      raise Repository::FileOutOfSyncConflict.new(path)
    end
    unless get_latest_revision.path_exists?(path)
      raise Repository::FileDoesNotExist.new(path)
    end
    File.unlink(File.join(@repos_path, path))
    @repos.index.remove(path)
  end

  # Replaces a file in the repository with new content.
  def replace_file(path, file_data, expected_revision_identifier)
    if @repos.last_commit.oid != expected_revision_identifier
      raise Repository::FileOutOfSyncConflict.new(path)
    end
    unless get_latest_revision.path_exists?(path)
      raise Repository::FileDoesNotExist.new(path)
    end
    write_file(path, file_data)
  end

  # Writes +file_data+ to the file at +path+.
  def write_file(path, file_data)
    # Get directory path of file (one level higher)
    dir = File.dirname(path)
    abs_path = File.join(@repos_path, dir)
    # Create the folder (if not present), creating parents folders if necessary.
    # This will not overwrite the folder if it's already present.
    FileUtils.mkdir_p(abs_path)
    # Create a file and commit it. This will overwrite the
    # file on disk if it already exists, but will only make a
    # new commit if the file contents have changed.
    abs_path = File.join(@repos_path, path)
    File.open(abs_path, 'w') do |file|
      file.write file_data.force_encoding('UTF-8')
    end
    @repos.index.add(path)
  end

end

# Convenience class, so that we can work on Revisions rather
# than repositories
class GitRevision < Repository::AbstractRevision

  # Constructor; checks if +revision_hash+ is actually present in +repo+.
  def initialize(revision_hash, repo)
    @repo = repo.get_repos
    begin
      @commit = @repo.lookup(revision_hash)
    rescue Rugged::OdbError
      raise RevisionDoesNotExist
    end
    super(revision_hash)
    @revision_identifier_ui = @revision_identifier[0..6]
    @author = @commit.author[:name]
    @timestamp = @commit.time.in_time_zone
    @server_timestamp = @timestamp
  end

  def last_modified_date
    self.timestamp
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
    parents = commit.parents
    if parents.empty?
      return entry != nil
    end
    # check each parent commit (a merge has 2+ parents)
    parents.each do |parent|
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

  # Get all entries at directory +path+ of a specified +type+ (:blob, :tree, or nil for both), as
  # Repository::RevisionFile and Repository::RevisionDirectory.
  # If +recursive+ is true, get all entries in subdirectories too.
  def entries_at_path(path, type: nil, recursive: false)
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
        mime_type = MiniMime.lookup_by_filename(entry_name)
        if mime_type.nil?
          mime_type = 'text'
        else
          mime_type = mime_type.content_type
        end
        entries[entry_name] = Repository::RevisionFile.new(@revision_identifier, name: entry_name, path: path,
                                                           mime_type: mime_type)
      elsif entry_type == :tree
        entries[entry_name] = Repository::RevisionDirectory.new(@revision_identifier, name: entry_name, path: path)
        if recursive
          entries.merge!(entries_at_path(File.join(path, entry_name), type: type, recursive: recursive)
                           .transform_keys! { |sub_name| File.join(entry_name, sub_name) })
        end
      end
    end
    entries
  end

  # Walk the git history once and collect the last commits and pushes that modified the +entries+ found at +path+.
  def add_entries_info(entries, path)
    # use the git reflog to get a list of pushes
    repo_path, _sep, repo_name = @repo.workdir[0..-2].rpartition(File::SEPARATOR)
    bare_path = File.join(repo_path, 'bare', "#{repo_name}.git")
    bare_repo = Rugged::Repository.new(bare_path)
    reflog = bare_repo.ref('refs/heads/master').log.reverse
    # walk through all the commits until this revision's +@commit+ is found
    # (this is needed to advance the reflog to the right point, since +@commit+ may be between two pushes)
    walker_entries = entries.dup
    last_commit = @repo.last_commit
    reflog_entries = {}
    reflog_entries[last_commit.oid] = { index: -1 }
    found = false
    walker = Rugged::Walker.new(@repo)
    walker.sorting(Rugged::SORT_TOPO)
    walker.push(last_commit)
    walker.each do |commit|
      current_reflog_entry = GitRepository.try_advance_reflog!(reflog, reflog_entries, commit)
      found = true if @commit.oid == commit.oid
      next unless found
      # check entries that were modified
      mod_keys = walker_entries.keys.select { |entry_name| entry_changed?(File.join(path, entry_name), commit) }
      mod_entries = walker_entries.extract!(*mod_keys)
      mod_entries.each do |_, mod_entry|
        mod_entry.last_modified_revision = commit.oid
        mod_entry.last_modified_date = commit.time.in_time_zone
        mod_entry.submitted_date = current_reflog_entry[:time]
        mod_entry.changed = commit.oid == @revision_identifier
        mod_entry.user_id = commit.author[:name]
      end
      break if walker_entries.empty?
    end
  ensure
    bare_repo.close
  end

  def files_at_path(path, with_attrs: true)
    entries = entries_at_path(path, type: :blob)
    if with_attrs && !entries.empty?
      add_entries_info(entries, path)
    end
    entries
  end

  def directories_at_path(path, with_attrs: true)
    entries = entries_at_path(path, type: :tree)
    if with_attrs && !entries.empty?
      add_entries_info(entries, path)
    end
    entries
  end

  def tree_at_path(path, with_attrs: true)
    entries = entries_at_path(path, recursive: true)
    if with_attrs && !entries.empty?
      add_entries_info(entries, path)
    end
    entries
  end
end
