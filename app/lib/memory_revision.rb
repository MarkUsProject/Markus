# Class responsible for storing files in and retrieving files
# from memory
class MemoryRevision < Repository::AbstractRevision
  # getter/setters for instance variables
  attr_accessor :files, :changed_files, :files_content, :user_id, :comment, :timestamp, :server_timestamp

  # Constructor
  def initialize(revision_number)
    super(revision_number)
    @files = []           # files in this revision (<filename> <RevisionDirectory/RevisionFile>)
    @files_content = {}   # hash: keys => RevisionFile object, value => content
    @user_id = 'dummy_user_id'     # user_id, who created this revision
    @comment = 'commit_message' # commit-message for this revision
    timestamp = Time.current
    @timestamp = timestamp
    @server_timestamp = timestamp
  end

  # Returns true if and only if path exists in files and path is a directory
  def path_exists?(path)
    if path == '/'
      return true # the root in a repository always exists
    end
    @files.each do |object|
      object_fqpn = Pathname.new(object.path) + object.name # fqpn is: fully qualified pathname :-)
      if object_fqpn == Pathname.new(path)
        return true
      end
    end
    false
  end

  # Return all of the files in this repository at the root directory
  def files_at_path(path = '/', with_attrs: true)
    return {} if @files.empty?
    files_at_path_helper(path, only_changed: false)
  end

  # Return true if there was files submitted at the desired path for the revision
  def revision_at_path(path)
    return false if @files.empty?
    revision_at_path_helper(path)
  end

  def directories_at_path(path = '/', with_attrs: true)
    return {} if @files.empty?
    files_at_path_helper(path, only_changed: false, type: Repository::RevisionDirectory)
  end

  def tree_at_path(path, with_attrs: true)
    result = files_at_path(path, with_attrs: with_attrs)
    dirs = directories_at_path(path, with_attrs: with_attrs)
    result.merge!(dirs)
    dirs.each_key do |dir_path|
      result.merge!(tree_at_path(File.join(path, dir_path), with_attrs: with_attrs)
                      .transform_keys! { |sub_path| File.join(dir_path, sub_path) })
    end
    result
  end

  def changes_at_path?(path)
    !files_at_path_helper(path, only_changed: true).empty?
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

  def files_at_path_helper(path = '/', only_changed: false, type: Repository::RevisionFile)
    # Automatically append a root slash if not supplied
    result = Hash.new(nil)
    @files.each do |object|
      alt_path = ''
      if object.path == '.'
        alt_path = '/'
      elsif object.path != '/'
        alt_path = "/#{object.path}"
      end
      git_path = object.path + '/'
      if object.instance_of?(type) &&
          (object.path == path || alt_path == path || git_path == path) &&
          (!only_changed || object.changed)
        object.from_revision = @revision_identifier # set/reset revision number
        result[object.name] = object
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
      if (object.path == path || alt_path == path) && ((object.from_revision.to_i + 1) == @revision_identifier)
        return true
      end
    end
    false
  end
end
