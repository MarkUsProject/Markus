# Implements AbstractRepository for memory repositories
# It implements the following paradigm:
#   1. Repositories are created by using MemoryRepository.create()
#   2. Existing repositories are opened by using either MemoryRepository.open()
#      or MemoryRepository.new()
class MemoryRepository < Repository::AbstractRepository
  # class variable which knows of all memory repositories
  #    key (location), value (reference to repo)
  @@repositories = {}

  # hash containing user permissions
  @@permissions = {}

  #############################################################
  #   A MemoryRepository instance holds the following variables
  #     - current_revision
  #     - revision_history
  #     - timestamps_revisions
  #############################################################

  # Constructor: Connects to an existing Memory
  # repository; Note: A repository has to be created using
  # MemoryRepository.create(), if it is not yet existent
  # Generally: Do not(!) call it with 2 parameters, use MemoryRepository.create() instead!
  def initialize(location)
    # variables
    @users = {}                                 # hash of users (key) with corresponding permissions (value)
    @current_revision = MemoryRevision.new(1)   # the latest revision (we start from 1)
    @revision_history = []                      # a list (array) of old revisions (i.e. < @current_revision)
    @repository_location = location
    @closed = false
    @@repositories[location] = self             # push new MemoryRepository onto repository list
  end

  # Checks if a memory repository exists at 'path'
  def self.repository_exists?(path)
    @@repositories.key?(path)
  end

  # Open repository at specified location
  def self.open(location)
    raise 'Repository does not exist' unless MemoryRepository.repository_exists? location
    @@repositories[location] # return reference in question
  end

  # Creates memory repository at "virtual" location (they are identifiable by location)
  def self.create(location, _course)
    MemoryRepository.new(location) # always overwrite a previous one, we don't care about collisions
    true
  end

  # Static method: Deletes an existing memory repository
  def self.delete(repo_path)
    @@repositories.delete(repo_path)
  end

  # Destroys all repositories
  def self.purge_all
    @@repositories = {}
  end

  def self.get_checkout_command(external_repo_url, revision_number, group_name, repo_folder = nil)
    unless repo_folder.nil?
      external_repo_url += "/#{repo_folder}"
    end
    "#{external_repo_url},#{revision_number},\"#{group_name}\""
  end

  # Given either an array of, or a single object of class RevisionFile,
  # return a stream of data for the user to download as the file(s).
  def stringify_files(files)
    is_array = files.is_a? Array
    unless is_array
      files = [files]
    end
    files.collect! do |file|
      unless file.is_a? Repository::RevisionFile
        raise TypeError, 'Expected a Repository::RevisionFile'
      end
      rev = get_revision(file.from_revision.to_s)
      content = rev.files_content[file.to_s]
      if content.nil?
        raise FileDoesNotExistConflict, File.join(file.path, file.name)
      end
      content # spews out content to be collected (Ruby collect!() magic) :-)
    end
    if !is_array
      files.first
    else
      files
    end
  end
  alias download_as_string stringify_files

  def get_transaction(user_id, comment = '')
    if user_id.nil?
      raise 'Expected a user_id (Repository.get_transaction(user_id))'
    end
    Repository::Transaction.new(user_id, comment)
  end

  def commit(transaction)
    jobs = transaction.jobs
    # make a deep copy of current revision
    new_rev = copy_revision(@current_revision)
    new_rev.user_id = transaction.user_id # set commit-user for new revision
    jobs.each do |job|
      case job[:action]
      when :add_path
        begin
          new_rev = make_directory(new_rev, job[:path])
        rescue Repository::Conflict => e
          transaction.add_conflict(e)
        end
      when :add
        begin
          new_rev = add_file(new_rev, job[:path], job[:file_data], job[:mime_type])
        rescue Repository::Conflict => e
          transaction.add_conflict(e)
        end
      when :remove
        begin
          new_rev = remove_file(new_rev, job[:path], job[:expected_revision_identifier])
        rescue Repository::Conflict => e
          transaction.add_conflict(e)
        end
      when :remove_directory
        begin
          new_rev = remove_directory(new_rev, job[:path], job[:expected_revision_identifier])
        rescue Repository::Conflict => e
          transaction.add_conflict(e)
        end
      when :replace
        begin
          new_rev = replace_file_content(new_rev, job[:path], job[:file_data], job[:mime_type],
                                         job[:expected_revision_identifier])
        rescue Repository::Conflict => e
          transaction.add_conflict(e)
        end
      end
    end

    if transaction.conflicts?
      return false
    end

    # everything went fine, so push old revision to history revisions and make new_rev the latest one
    timestamp = Time.current
    new_rev.timestamp = timestamp
    new_rev.server_timestamp = timestamp
    new_rev.__increment_revision_number
    @revision_history.push(@current_revision)
    @current_revision = new_rev
    @@repositories[@repository_location] = self
    true
  end

  # Returns the latest revision number (as a RepositoryRevision object)
  def get_latest_revision
    @current_revision
  end

  # Return a RepositoryRevision for a given rev_num (int)
  def get_revision(rev_num)
    if @current_revision.revision_identifier.to_s == rev_num
      return @current_revision
    end
    @revision_history.each do |revision|
      if revision.revision_identifier.to_s == rev_num
        return revision
      end
    end
    # revision with the specified revision number does not exist,
    # so raise error
    raise Repository::RevisionDoesNotExist
  end

  # Return a RepositoryRevision for a given timestamp
  def get_revision_by_timestamp(at_or_earlier_than, path = nil, later_than = nil)
    unless at_or_earlier_than.is_a?(Time)
      raise 'Was expecting a timestamp of type Time'
    end

    (@revision_history + [@current_revision]).reverse_each do |revision|
      return nil if !later_than.nil? && revision.server_timestamp <= later_than
      return revision if revision.server_timestamp <= at_or_earlier_than &&
                         (path.nil? || revision.changes_at_path?(path))
    end
    nil
  end

  def get_all_revisions
    @revision_history + [@current_revision]
  end

  # Static method: Yields an existing Memory repository and closes it afterwards
  def self.access(connect_string)
    self.redis_exclusive_lock(connect_string, namespace: :repo_lock) do
      repository = MemoryRepository.open(connect_string)
      yield repository
    ensure
      repository&.close
    end
  end

  # Closes the repository.
  # This does nothing except set a proper value for the closed? function
  # It is not important to close memory repositories (is it possible?)
  def close
    @closed = true
  end

  # Resturns whether or not the repository is closed.
  # This will return a value corresponding to whether the open or close functions
  # have been called but is otherwise meaningless in a MemoryRepository
  def closed?
    @closed
  end

  # Converts a pathname to an absolute pathname
  def expand_path(file_name, dir_string = '/')
    expanded = File.expand_path(file_name, dir_string)
    if RUBY_PLATFORM.match?(/(:?mswin|mingw)/) # only if the platform is Windows
      expanded = expanded[2..-1] # remove the drive letter ('D:')
    end
    expanded
  end

  def self.update_permissions_file(permissions)
    permissions.each do |repo_loc, users|
      @@permissions[repo_loc] = users
    end
  end

  def reload_non_bare_repo; end

  private

  # Creates a directory as part of the provided revision
  def make_directory(rev, full_path)
    if rev.path_exists?(full_path)
      raise Repository::FolderExistsConflict, full_path # raise conflict if path exists
    end
    creation_time = Time.current
    dir = Repository::RevisionDirectory.new(rev.revision_identifier, {
      name: File.basename(full_path),
      path: File.dirname(full_path),
      last_modified_revision: rev.revision_identifier,
      last_modified_date: creation_time,
      submitted_date: creation_time,
      changed: true,
      user_id: rev.user_id
    })
    rev.__add_directory(dir)
    rev
  end

  # Adds a file into the provided revision
  def add_file(rev, full_path, content, _mime_type = 'text/plain')
    if file_exists?(rev, full_path)
      raise Repository::FileExistsConflict, full_path
    end
    # file does not exist, so add it
    creation_time = Time.current
    file = Repository::RevisionFile.new(rev.revision_identifier, {
      name: File.basename(full_path),
      path: File.dirname(full_path),
      last_modified_revision: rev.revision_identifier,
      changed: true,
      user_id: rev.user_id,
      last_modified_date: creation_time,
      submitted_date: creation_time
    })
    rev.__add_file(file, content)
    rev
  end

  # Replaces file content of a file already existent in a revision
  def replace_file_content(rev, full_path, file_content, _mime_type, expected_revision_int)
    unless file_exists?(rev, full_path)
      raise Repository::FileDoesNotExistConflict, full_path
    end
    # replace content of file in question
    act_rev = get_latest_revision
    if act_rev.revision_identifier != expected_revision_int.to_i
      raise Repository::FileOutOfSyncConflict, full_path
    end
    files_list = rev.files_at_path(File.dirname(full_path))
    rev.__replace_file_content(files_list[File.basename(full_path)], file_content)
    rev
  end

  # Removes a file from the provided revision
  def remove_file(rev, full_path, expected_revision_int)
    unless file_exists?(rev, full_path)
      raise Repository::FileDoesNotExistConflict, full_path
    end
    act_rev = get_latest_revision
    if act_rev.revision_identifier != expected_revision_int.to_i
      raise Repository::FileOutOfSyncConflict, full_path
    end
    filename = File.basename(full_path)
    path = File.dirname(full_path)
    files_set = rev.files_at_path(path)
    rev.files.delete_at(rev.files.index(files_set[filename])) # delete file, but keep contents
    rev
  end

  def remove_directory(rev, full_path, _expected_revision_int)
    unless get_latest_revision.path_exists?(full_path)
      raise Repository::FolderDoesNotExistConflict, full_path
    end
    directory_name = File.basename(full_path)
    path = File.dirname(full_path)
    directory_set = rev.directories_at_path(path)
    rev.files.delete_at(rev.files.index(directory_set[directory_name]))
    rev
  end

  # Creates a deep copy of the provided revision, all files will have their changed property
  # set to false; does not create a deep copy the contents of files
  def copy_revision(original)
    # we only copy the RevisionFile/RevisionDirectory entries
    new_revision = MemoryRevision.new(original.revision_identifier)
    new_revision.user_id = original.user_id
    new_revision.comment = original.comment
    new_revision.files_content = {}
    new_revision.timestamp = original.timestamp
    new_revision.server_timestamp = original.server_timestamp
    # copy files objects
    original.files.each do |object|
      if object.instance_of?(Repository::RevisionFile)
        new_object = Repository::RevisionFile.new(object.from_revision.to_s, {
          name: object.name,
          path: object.path,
          last_modified_revision: object.last_modified_revision,
          changed: false, # for copies, set this to false
          user_id: object.user_id,
          last_modified_date: object.last_modified_date,
          submitted_date: object.last_modified_date
        })
        new_revision.files_content[new_object.to_s] = original.files_content[object.to_s]
      else
        new_object = Repository::RevisionDirectory.new(object.from_revision.to_s, {
          name: object.name,
          path: object.path,
          last_modified_revision: object.last_modified_revision,
          last_modified_date: object.last_modified_date,
          submitted_date: object.last_modified_date,
          changed: false, # for copies, set this to false
          user_id: object.user_id
        })
      end
      new_revision.files.push(new_object)
    end
    new_revision # return the copy
  end

  def file_exists?(rev, full_path)
    filename = File.basename(full_path)
    path = File.dirname(full_path)
    curr_files = rev.files_at_path(path)
    curr_files&.each_key do |f|
      if f == filename
        return true
      end
    end
    false
  end

  # gets the "closest matching" revision from the revision-timestamp
  # mapping
  def get_revision_number_by_timestamp(wanted_timestamp, path = nil)
    if @timestamps_revisions.empty?
      raise 'No revisions, so no timestamps.'
    end

    all_timestamps_list = []
    remaining_timestamps_list = []
    @timestamps_revisions.each_key do |time_dump|
      all_timestamps_list.push(Marshal.load(time_dump)) # rubocop:disable Security/MarshalLoad
      remaining_timestamps_list.push(Marshal.load(time_dump)) # rubocop:disable Security/MarshalLoad
    end

    # find closest matching timestamp
    mapping = {}
    first_timestamp_found = false
    old_diff = 0
    # find first valid revision
    all_timestamps_list.each do |best_match|
      remaining_timestamps_list.shift
      old_diff = wanted_timestamp - best_match
      mapping[old_diff.to_s] = best_match
      if path.nil? || (!path.nil? && @timestamps_revisions[Marshal.dump(best_match)].revision_at_path(path))
        first_timestamp_found = true
        break
      end
    end

    # find all other valid revision
    remaining_timestamps_list.each do |curr_timestamp|
      new_diff = wanted_timestamp - curr_timestamp
      mapping[new_diff.to_s] = curr_timestamp
      if path.nil? || (!path.nil? && @timestamps_revisions[Marshal.dump(curr_timestamp)].revision_at_path(path))
        if (old_diff <= 0 && new_diff <= 0) ||
          (old_diff <= 0 && new_diff > 0) ||
          (new_diff <= 0 && old_diff > 0)
          old_diff = [old_diff, new_diff].max
        else
          old_diff = [old_diff, new_diff].min
        end
      end
    end

    if first_timestamp_found
      wanted_timestamp = mapping[old_diff.to_s]
      @timestamps_revisions[Marshal.dump(wanted_timestamp)]
    else
      @current_revision
    end
  end
end
