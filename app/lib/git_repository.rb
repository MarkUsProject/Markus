require 'csv'

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
    @connect_string = connect_string
    @closed = false
    @repos = Rugged::Repository.new(bare_path)
  end

  def self.do_commit_and_push(repo, author, message)
    index = repo.index
    commit_tree = index.write_tree(repo)
    index.write
    commit_author = { email: 'markus@markus.com', name: author, time: Time.current.to_time }
    commit_options = {
      author: commit_author,
      committer: commit_author,
      message: message,
      tree: commit_tree,
      parents: repo.empty? ? [] : [repo.head.target].compact, # compact if target returns nil (suggested upstream)
      update_ref: 'HEAD'
    }
    Rugged::Commit.create(repo, commit_options)
    repo.push('origin', ['refs/heads/master'])
  end

  def self.server_hooks
    Rails.root.join('lib/repo/git_hooks/server')
  end

  def self.client_hooks
    Rails.root.join('lib/repo/git_hooks/client')
  end

  # Static method: Creates a new Git repository at
  # location 'connect_string'
  def self.create(connect_string, course)
    if GitRepository.repository_exists?(connect_string)
      raise RepositoryCollision, "There is already a repository at #{connect_string}"
    end
    if File.exist?(connect_string)
      raise IOError, "Could not create a repository at #{connect_string}: some directory with same name exists
                         already"
    end
    # Repo is created bare, then clone it in the repository storage location
    barepath = bare_path(connect_string)
    self.redis_exclusive_lock(connect_string, namespace: :repo_lock) do
      FileUtils.mkdir_p(File.dirname(barepath))
      Rugged::Repository.init_at(barepath, :bare)
      bare_config = Rugged::Config.new(File.join(barepath, 'config'))
      bare_config['core.logAllRefUpdates'] = true # enable reflog to keep track of push dates
      bare_config['gc.reflogExpire'] = 'never' # never garbage collect the reflog
      tmp_repo_path = tmp_repo(connect_string)
      FileUtils.rm_rf(tmp_repo_path)
      repo = Rugged::Repository.clone_at(barepath, tmp_repo_path)

      # Do an initial commit with the .required file
      required = course.get_required_files
      required_path = File.join(tmp_repo_path, '.required')
      File.write(required_path, required)
      repo.index.add('.required')

      # Do an initial commit with the .max_file_size file
      max_file_size_path = File.join(tmp_repo_path, '.max_file_size')
      File.write(max_file_size_path, course.max_file_size.to_s)
      repo.index.add('.max_file_size')

      # Add client-side hooks
      dest = File.join(tmp_repo_path, 'markus-hooks')
      FileUtils.copy_entry client_hooks, dest

      FileUtils.chmod(0o755, Dir.glob(File.join(tmp_repo_path, 'markus-hooks', '**', '*')).select { |f| File.file?(f) })
      repo.index.add_all('markus-hooks')

      # Set up server-side hooks
      dest = File.join(barepath, 'hooks')
      FileUtils.rm_rf dest
      FileUtils.copy_entry server_hooks, dest
      FileUtils.chmod(0o755, Dir.glob(File.join(dest, '**', '*')).select { |f| File.file?(f) })

      GitRepository.do_commit_and_push(repo, 'Markus', I18n.t('repo.commits.initial'))
    rescue StandardError
      FileUtils.rm_rf(barepath)
      raise
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

  def self.get_checkout_command(external_repo_url, revision_hash, group_name, _repo_folder = nil)
    "git clone \"#{external_repo_url}\" \"#{group_name}\" && " \
      "cd \"#{group_name}\" && " \
      "git reset --hard #{revision_hash} && " \
      'cd ..'
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
    # use the git reflog to get a list of pushes: find first push_time <= at_or_earlier_than && > later_than
    reflog = @repos.ref('refs/heads/master').log.reverse
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
    return if current_reflog_entry.empty?
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
  end

  def get_all_revisions
    # use the git reflog to get a list of pushes
    reflog = @repos.ref('refs/heads/master').log.reverse
    last_commit = @repos.last_commit
    reflog_entries = {}
    reflog_entries[last_commit.oid] = { index: -1 }
    # walk through the commits and get revisions
    walker = Rugged::Walker.new(@repos)
    walker.sorting(Rugged::SORT_TOPO)
    walker.push(last_commit.oid)
    walker.map do |commit|
      current_reflog_entry = GitRepository.try_advance_reflog!(reflog, reflog_entries, commit)
      revision = get_revision(commit.oid)
      revision.server_timestamp = current_reflog_entry[:time]
      revision
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
    if filepath.nil?
      # Raise an error if the destination repository already exists
      if File.exist?(repo_dest_dir)
        raise(ExportRepositoryAlreadyExists,
              'Exported repository already exists')
      end

      Rugged::Repository.clone_at(@connect_string, repo_dest_dir)
    else
      # Case 2: clone a file to a folder
      # Raise an error if the destination file already exists
      if File.exist?(repo_dest_dir)
        raise(ExportRepositoryAlreadyExists,
              'Exported file already exists')
      end
      FileUtils.cp(get_repos_workdir + filepath, repo_dest_dir)
      true
    end
  end

  #  Converts a pathname to an absolute pathname
  def expand_path(file_name, dir_string = '/')
    expanded = File.expand_path(file_name, dir_string)
    if RUBY_PLATFORM.match?(/(:?mswin|mingw)/)  # only if the platform is Windows
      expanded = expanded[2..-1] # remove the drive letter
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
    @closed
  end

  def get_repos
    # Get rugged repository from GitRepository
    @repos
  end

  def get_repos_workdir
    # Get working directory of the repository
    # workdir = path/to/my/repository/
    @repos.workdir
  end

  def get_repos_path
    # Get the repository's .git folder
    # path = path/to/my/repository/.git
    @repos.path
  end

  # Gets the repository name
  def get_repo_name
    @connect_string.rpartition(File::SEPARATOR)[2]
  end

  # Gets the repository connection string
  attr_reader :connect_string

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
    if File.exist?(File.join(repos_path, '.git/config')) &&
        File.exist?(File.join(repos_path, '.git/description')) &&
        File.exist?(File.join(repos_path, '.git/HEAD'))
      repos_meta_files_exist = true
    end
    repos_meta_files_exist
  end

  # Returns a Repository::TransAction object, to work with. Do operations,
  # like 'add', 'remove', etc. on the transaction instead of the repository
  def get_transaction(user_id, comment = I18n.t('repo.commits.default'))
    if user_id.nil?
      raise 'Expected a user_id (Repository.get_transaction(user_id))'
    end
    Repository::Transaction.new(user_id, comment)
  end

  # Carries out actions on a Git repository stored in
  # 'transaction'. In case of certain conflicts corresponding
  # Repositor::Conflict(s) are added to the transaction object
  def commit(transaction)
    return true unless transaction.has_jobs?

    self.class.redis_exclusive_lock(@connect_string, namespace: :repo_lock) do
      non_bare_repo  # Ensure non-bare repo exists

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
            remove_file(job[:path], job[:expected_revision_identifier], keep_folder: job[:keep_folder])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :remove_directory
          begin
            remove_directory(job[:path], job[:expected_revision_identifier], keep_parent_dir: job[:keep_parent_dir])
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
        non_bare_repo.reset('master', :hard)
        false
      else
        GitRepository.do_commit_and_push(non_bare_repo, transaction.user_id, transaction.comment)
        true
      end
    ensure
      non_bare_repo&.close
    end
  end

  def self.internal_file_names
    [DUMMY_FILE_NAME]
  end

  def self.bare_path(connect_string)
    repo_path, _sep, repo_name = connect_string.rpartition(File::SEPARATOR)
    File.join(repo_path, "#{repo_name}.git")
  end

  def tmp_repo
    @tmp_repo ||= GitRepository.tmp_repo(@connect_string)
  end

  def self.tmp_repo(connect_string)
    Rails.root.join("tmp/git_repo_#{connect_string.gsub(File::Separator, '_')}")
  end

  # Helper method to generate all the permissions for students for all groupings in all assignments.
  # This is done as a single operation to mirror the SVN repo code.
  def self.update_permissions_file(permissions)
    # If we're not in authoritative mode, bail out
    unless Settings.repository.is_repository_admin
      raise NotAuthorityError, 'Unable to set bulk permissions: Not in authoritative mode!'
    end

    # Create auth csv file
    FileUtils.mkdir_p(File.dirname(Repository::PERMISSION_FILE))
    CSV.open(Repository::PERMISSION_FILE, 'wb') do |csv|
      csv.flock(File::LOCK_EX)
      begin
        permissions.each do |repo_name, users|
          csv << [repo_name] + users
        end
      ensure
        csv.flock(File::LOCK_UN)
      end
    end
  end

  # This function allows a cached value of non_bare_repo to be cleared.
  def reload_non_bare_repo
    @non_bare_repo = nil
    non_bare_repo
  end

  ####################################################################
  ##  Private method definitions
  ####################################################################

  private

  def non_bare_repo
    return @non_bare_repo unless @non_bare_repo.nil?

    if GitRepository.repository_exists?(tmp_repo)
      begin
        @non_bare_repo = Rugged::Repository.new(tmp_repo)
        # make sure working directory is up-to-date
        @non_bare_repo.fetch('origin')
        begin
          # TODO: this shouldn't be necessary, but something is messing up the repo.
          @non_bare_repo.reset('master', :hard)
        rescue Rugged::ReferenceError
          # It seems the master branch might not be correctly setup at first.
        end
        @non_bare_repo.reset('origin/master', :hard) # align to whatever is in origin/master
      rescue Rugged::Error, Rugged::OSError => e
        m_logger = MarkusLogger.instance
        m_logger.log "Error accessing repository #{tmp_repo}: #{e.message}"
        @non_bare_repo = reclone_repo(tmp_repo)
      end
    else
      m_logger = MarkusLogger.instance
      m_logger.log "Error accessing repository #{tmp_repo}: repository missing"
      @non_bare_repo = reclone_repo(tmp_repo)
    end
    @non_bare_repo
  end

  def reclone_repo(tmp_repo)
    raise 'Repository does not exist' unless Dir.exist?(bare_path)
    if Dir.exist?(tmp_repo)
      bad_repo_path = "#{tmp_repo}.bad"
      FileUtils.rm_rf(bad_repo_path)
      FileUtils.mv(tmp_repo, bad_repo_path)
    end
    repo = Rugged::Repository.clone_at(bare_path, tmp_repo)
    m_logger = MarkusLogger.instance
    m_logger.log "Recloned corrupted or missing git repo: #{tmp_repo}"
    repo
  rescue StandardError
    msg = "Failed to clone corrupted or missing git repo: #{tmp_repo}"
    m_logger = MarkusLogger.instance
    m_logger.log msg
    raise
  end

  def bare_path
    @bare_path ||= GitRepository.bare_path(@connect_string)
  end

  # Creates a file into the repository.
  def add_file(path, file_data)
    if get_latest_revision.path_exists?(path)
      raise Repository::FileExistsConflict, path
    end
    write_file(path, file_data)
  end

  # Creates an empty directory into the repository.
  # The dummy file is required so the directory gets committed.
  def add_directory(path)
    if get_latest_revision.path_exists?(path)
      raise Repository::FolderExistsConflict, path
    end
    gitkeep_filename = File.join(path, DUMMY_FILE_NAME)
    add_file(gitkeep_filename, '')
  end

  # Removes a file from the repository.
  # If +keep_folder+ is true, the files will be deleted and .gitkeep file will be added to its parent folder if it
  # is not exists in order to keep the folder.
  # If +keep_folder+ is false, all the files will be deleted and .gitkeep file will not be added.
  def remove_file(path, expected_revision_identifier, keep_folder: true)
    if non_bare_repo.last_commit.oid != expected_revision_identifier
      raise Repository::FileOutOfSyncConflict, path
    end
    unless get_latest_revision.path_exists?(path)
      raise Repository::FileDoesNotExistConflict, path
    end
    absolute_path = Pathname.new(File.join(tmp_repo, path))
    relative_path = Pathname.new(path)
    File.unlink(File.join(tmp_repo, path))
    non_bare_repo.index.remove(path)
    return unless keep_folder
    return if File.exist?(File.join(absolute_path.dirname, DUMMY_FILE_NAME))
    gitkeep_filename = File.join(relative_path.dirname, DUMMY_FILE_NAME)
    add_file(gitkeep_filename, '')
  end

  def remove_directory(path, _expected_revision_identifier, keep_parent_dir: false)
    unless get_latest_revision.path_exists?(path)
      raise Repository::FolderDoesNotExistConflict, path
    end
    absolute_path = Pathname.new(File.join(tmp_repo, path))
    relative_path = Pathname.new(path)
    unless Dir.empty?(absolute_path)
      raise Repository::FolderIsNotEmptyConflict, path
    end
    FileUtils.remove_dir(absolute_path)
    return unless keep_parent_dir
    return if File.exist?(File.join(absolute_path.dirname, DUMMY_FILE_NAME))
    gitkeep_filename = File.join(relative_path.dirname, DUMMY_FILE_NAME)
    add_file(gitkeep_filename, '')
  end

  # Replaces a file in the repository with new content.
  def replace_file(path, file_data, expected_revision_identifier)
    if non_bare_repo.last_commit.oid != expected_revision_identifier
      raise Repository::FileOutOfSyncConflict, path
    end
    unless get_latest_revision.path_exists?(path)
      raise Repository::FileDoesNotExist, path
    end
    write_file(path, file_data)
  end

  # Writes +file_data+ to the file at +path+.
  def write_file(path, file_data)
    # Get directory path of file (one level higher)
    dir = File.dirname(path)
    abs_path = File.join(tmp_repo, dir)
    # Create the folder (if not present), creating parents folders if necessary.
    # This will not overwrite the folder if it's already present.
    FileUtils.mkdir_p(abs_path)
    # Create a file and commit it. This will overwrite the
    # file on disk if it already exists, but will only make a
    # new commit if the file contents have changed.
    abs_path = File.join(tmp_repo, path)
    File.write(abs_path, file_data.force_encoding('UTF-8'))
    non_bare_repo.index.add(path)
  end
end
