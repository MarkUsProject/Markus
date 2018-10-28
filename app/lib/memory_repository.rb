# Implements AbstractRepository for memory repositories
# It implements the following paradigm:
#   1. Repositories are created by using MemoryRepository.create()
#   2. Existing repositories are opened by using either SubversionRepository.open()
#      or SubversionRepository.new()
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
    unless MemoryRepository.repository_exists?(location)
      raise "Could not open repository at location #{location}"
    end
    return @@repositories[location] # return reference in question
  end

  # Creates memory repository at "virtual" location (they are identifiable by location)
  def self.create(location)
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

  def self.get_checkout_command(external_repo_url, revision_number, group_name, repo_folder=nil)
    unless repo_folder.nil?
      external_repo_url += "/#{repo_folder}"
    end
    "#{external_repo_url},#{revision_number},\"#{group_name}\""
  end

  # Given either an array of, or a single object of class RevisionFile,
  # return a stream of data for the user to download as the file(s).
  def stringify_files(files)
    is_array = files.kind_of? Array
    if (!is_array)
      files = [files]
    end
    files.collect! do |file|
      if (!file.kind_of? Repository::RevisionFile)
        raise TypeError.new("Expected a Repository::RevisionFile")
      end
      rev = get_revision(file.from_revision.to_s)
      content = rev.files_content[file.to_s]
      if content.nil?
        raise FileDoesNotExistConflict.new(File.join(file.path, file.name))
      end
      content # spews out content to be collected (Ruby collect!() magic) :-)
    end
    if (!is_array)
      return files.first
    else
      return files
    end
  end
  alias download_as_string stringify_files

  def get_transaction(user_id, comment="")
    if user_id.nil?
      raise "Expected a user_id (Repository.get_transaction(user_id))"
    end
    return Repository::Transaction.new(user_id, comment)
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
      when :replace
        begin
          new_rev = replace_file_content(new_rev, job[:path], job[:file_data], job[:mime_type], job[:expected_revision_identifier])
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
    return @current_revision
  end

  # Return a RepositoryRevision for a given rev_num (int)
  def get_revision(rev_num)
    if (@current_revision.revision_identifier.to_s == rev_num)
      return @current_revision
    end
    @revision_history.each do |revision|
      if (revision.revision_identifier.to_s == rev_num)
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
      raise "Was expecting a timestamp of type Time"
    end

    (@revision_history + [@current_revision]).reverse_each do |revision|
      return nil if !later_than.nil? && revision.server_timestamp <= later_than
      return revision if revision.server_timestamp <= at_or_earlier_than &&
                         (path.nil? || revision.revision_at_path(path))
    end
    nil
  end

  def get_all_revisions
    @revision_history + [@current_revision]
  end

  # Static method: Yields an existing Memory repository and closes it afterwards
  def self.access(connect_string)
    repository = MemoryRepository.open(connect_string)
    yield repository
  ensure
    repository.close
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
  def expand_path(file_name, dir_string = "/")
    expanded = File.expand_path(file_name, dir_string)
    if RUBY_PLATFORM =~ /(:?mswin|mingw)/ #only if the platform is Windows
      expanded = expanded[2..-1]#remove the drive letter ('D:')
    end
    return expanded
  end

  private
  # Creates a directory as part of the provided revision
  def make_directory(rev, full_path)
    if rev.path_exists?(full_path)
      raise FileExistsConflict # raise conflict if path exists
    end
    dir = Repository::RevisionDirectory.new(rev.revision_identifier, {
      name: File.basename(full_path),
      path: File.dirname(full_path),
      last_modified_revision: rev.revision_identifier,
      last_modified_date: Time.now,
      changed: true,
      user_id: rev.user_id
    })
    rev.__add_directory(dir)
    return rev
  end

  # Adds a file into the provided revision
  def add_file(rev, full_path, content, mime_type="text/plain")
    if file_exists?(rev, full_path)
      raise FileExistsConflict.new(full_path)
    end
    # file does not exist, so add it
    file = Repository::RevisionFile.new(rev.revision_identifier, {
      name: File.basename(full_path),
      path: File.dirname(full_path),
      last_modified_revision: rev.revision_identifier,
      changed: true,
      user_id: rev.user_id,
      last_modified_date: Time.now
    })
    rev.__add_file(file, content)
    return rev
  end

  # Replaces file content of a file already existent in a revision
  def replace_file_content(rev, full_path, file_content, mime_type, expected_revision_int)
    if !file_exists?(rev, full_path)
      raise Repository::FileDoesNotExistConflict.new(full_path)
    end
    # replace content of file in question
    act_rev = get_latest_revision()
    if (act_rev.revision_identifier != expected_revision_int.to_i)
      raise Repository::FileOutOfSyncConflict.new(full_path)
    end
    files_list = rev.files_at_path(File.dirname(full_path))
    rev.__replace_file_content(files_list[File.basename(full_path)], file_content)
    return rev
  end

  # Removes a file from the provided revision
  def remove_file(rev, full_path, expected_revision_int)
    if !file_exists?(rev, full_path)
      raise Repostiory::FileDoesNotExistConflict.new(full_path)
    end
    act_rev = get_latest_revision()
    if (act_rev.revision_identifier != expected_revision_int.to_i)
      raise Repository::FileOutOfSyncConflict.new(full_path)
    end
    filename = File.basename(full_path)
    path = File.dirname(full_path)
    files_set = rev.files_at_path(path)
    rev.files.delete_at(rev.files.index(files_set[filename])) # delete file, but keep contents
    return rev
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
          last_modified_date: object.last_modified_date
        })
        new_revision.files_content[new_object.to_s] = original.files_content[object.to_s]
      else
        new_object = Repository::RevisionDirectory.new(object.from_revision.to_s, {
          name: object.name,
          path: object.path,
          last_modified_revision: object.last_modified_revision,
          last_modified_date: object.last_modified_date,
          changed: false, # for copies, set this to false
          user_id: object.user_id
        })
      end
      new_revision.files.push(new_object)
    end
    return new_revision # return the copy
  end

  def file_exists?(rev, full_path)
    filename = File.basename(full_path)
    path = File.dirname(full_path)
    curr_files = rev.files_at_path(path)
    if !curr_files.nil?
      curr_files.each do |f, object|
        if f == filename
          return true
        end
      end
    end
    return false
  end

  # gets the "closest matching" revision from the revision-timestamp
  # mapping
  def get_revision_number_by_timestamp(wanted_timestamp, path = nil)
    if @timestamps_revisions.empty?
      raise "No revisions, so no timestamps."
    end

    all_timestamps_list = []
    remaining_timestamps_list = []
    @timestamps_revisions.keys().each do |time_dump|
      all_timestamps_list.push(Marshal.load(time_dump))
      remaining_timestamps_list.push(Marshal.load(time_dump))
    end

    # find closest matching timestamp
    mapping = {}
    first_timestamp_found = false
    old_diff = 0
    # find first valid revision
    all_timestamps_list.each do |best_match|
      remaining_timestamps_list.shift()
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
        if(old_diff <= 0 && new_diff <= 0) ||
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
      return @timestamps_revisions[Marshal.dump(wanted_timestamp)]
    else
      return @current_revision
    end
  end

  def self.__update_permissions(permissions, full_access_users)
    @@permissions = {'*' => full_access_users}
    permissions.each do |repo_loc, users|
      @@permissions[repo_loc] = users
    end
  end

  private_class_method :__update_permissions

end # end class MemoryRepository

# Class responsible for storing files in and retrieving files
# from memory
class MemoryRevision < Repository::AbstractRevision

  # getter/setters for instance variables
  attr_accessor :files, :changed_files, :files_content, :user_id, :comment, :timestamp

  # Constructor
  def initialize(revision_number)
    super(revision_number)
    @files = []           # files in this revision (<filename> <RevisionDirectory/RevisionFile>)
    @files_content = {}   # hash: keys => RevisionFile object, value => content
    @user_id = "dummy_user_id"     # user_id, who created this revision
    @comment = "commit_message" # commit-message for this revision
  end

  # Returns true if and only if path exists in files and path is a directory
  def path_exists?(path)
    if path == "/"
      return true # the root in a repository always exists
    end
    @files.each do |object|
      object_fqpn = File.join(object.path, object.name) # fqpn is: fully qualified pathname :-)
      if object_fqpn == path
        return true
      end
    end
    return false
  end

  # Return all of the files in this repository at the root directory
  def files_at_path(path="/")
    return Hash.new if @files.empty?
    return files_at_path_helper(path)
  end

  # Return true if there was files submitted at the desired path for the revision
  def revision_at_path(path)
    return false if @files.empty?
    revision_at_path_helper(path)
  end

  def directories_at_path(path = '/')
    return Hash.new if @files.empty?
    return files_at_path_helper(path, false, Repository::RevisionDirectory)
  end

  # Walks all files and subdirectories starting at +path+ and
  # returns an array of tuples containing [path, revision_object]
  # for every file and directory discovered in this way
  #
  # It returns an array to ensure ordering, so that a directory
  # will always appear before any of the files or subdirectories
  # contained within it
  def tree_at_path(path)
    result = files_at_path(path).to_a
    dirs = directories_at_path(path)
    result.push(*dirs.to_a)
    dirs.each do |dir_path, _|
      result.push(*(tree_at_path(File.join(path, dir_path)).map { |sub_pth, obj| [File.join(dir_path, sub_pth), obj] }))
    end
    result
  end

  def changes_at_path?(path)
    !files_at_path_helper(path, true).empty?
  end

  # Not (!) part of the AbstractRepository API:
  # A simple helper method to be used to add files to this
  # revision
  def __add_file(file, content = '')
    @files.push(file)
    if file.instance_of?(Repository::RevisionFile)
      @files_content[file.to_s] = content
    end
  end

  # Not (!) part of the AbstractRepository API:
  # A simple helper method to be used to replace the
  # content of a file
  def __replace_file_content(file, new_content)
    if file.instance_of?(Repository::RevisionFile)
      @files_content[file.to_s] = new_content
    else
      raise 'Expected file to be of type Repository::RevisionFile'
    end
  end

  # Not (!) part of the AbstractRepository API:
  # A simple helper method to be used to add directories to this
  # revision
  def __add_directory(dir)
    __add_file(dir)
  end

  # Not (!) part of the AbstractRepository API:
  # A simple helper method to be used to increment the revision number
  def __increment_revision_number
    @revision_identifier += 1
  end

  private

  def files_at_path_helper(path = '/', only_changed = false, type = Repository::RevisionFile)
    # Automatically append a root slash if not supplied
    result = Hash.new(nil)
    @files.each do |object|
      alt_path = ''
      if object.path == '.'
        alt_path = '/'
      elsif object.path != '/'
        alt_path = '/' + object.path
      end
      git_path = object.path + '/'
      if object.instance_of?(type) && (object.path == path ||
          alt_path == path || git_path == path)
        if !only_changed
          object.from_revision = @revision_identifier # set revision number
          result[object.name] = object
        elsif object.changed
          object.from_revision = @revision_identifier # reset revision number
          result[object.name] = object
        end
      end
    end
    result
  end

  # Find if the revision contains files at the path
  def revision_at_path_helper(path)
    # Automatically append a root slash if not supplied
    @files.each do |object|
      alt_path = ''
      if object.path != '/'
        alt_path = object.path + '/'
      end
      if object.path == path || alt_path == path
        if (object.from_revision.to_i + 1) == @revision_identifier
          return true
        end
      end
    end
    false
  end
end
