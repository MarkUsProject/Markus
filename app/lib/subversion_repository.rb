require 'digest/md5'

# Implements AbstractRepository for Subversion repositories
# It implements the following paradigm:
#   1. Repositories are created by using SubversionRepository.create()
#   2. Existing repositories are opened by using either SubversionRepository.open()
#      or SubversionRepository.new()
class SubversionRepository < Repository::AbstractRepository
  # Constructor: Connects to an existing Subversion
  # repository, using Ruby bindings; Note: A repository has to be
  # created using SubversionRepository.create(), it it is not yet existent
  def initialize(connect_string)
    # Check if configuration is in order
    unless Settings.repository.is_repository_admin
      raise ConfigurationError, "Init: Required config 'repository.is_repository_admin' not set"
    end
    @repos_path = connect_string
    @repos_auth_file = Repository::PERMISSION_FILE
    @repos_admin = Settings.repository.is_repository_admin
    if SubversionRepository.repository_exists?(@repos_path)
      @repos = Svn::Repos.open(@repos_path)
    else
      raise "Repository does not exist at path \"#{@repos_path}\""
    end
  end

  # Static method: Creates a new Subversion repository at
  # location 'connect_string'
  def self.create(connect_string, _course)
    if SubversionRepository.repository_exists?(connect_string)
      raise RepositoryCollision, "There is already a repository at #{connect_string}"
    end
    if File.exist?(connect_string)
      raise IOError, "Could not create a repository at #{connect_string}: some directory with same name exists already"
    end
    # create the repository using the ruby bindings
    fs_config = { Svn::Fs::CONFIG_FS_TYPE => Svn::Fs::TYPE_FSFS }
    repository = Svn::Repos.create(connect_string, {}, fs_config) # raises exception if not successful
    repository.close

    true
  end

  # Static method: Opens an existing Subversion repository
  # at location 'connect_string'
  def self.open(connect_string)
    raise 'Repository does not exist' unless SubversionRepository.repository_exists? connect_string
    SubversionRepository.new(connect_string)
  end

  # Static method: Yields an existing Subversion repository and closes it afterwards
  def self.access(connect_string)
    self.redis_exclusive_lock(connect_string, namespace: :repo_lock) do
      repository = SubversionRepository.open(connect_string)
      yield repository
    ensure
      repository&.close
    end
  end

  # Static method: Deletes an existing Subversion repository
  def self.delete(repo_path)
    Svn::Repos.delete(repo_path)
  end

  # method : Export an existing Subversion repository to a new folder
  #
  # If a filepath is given, the repo_dest_dir needs to point to a file, and
  # all the repository on that path need to exist, or the export will fail.
  def export(repo_dest_dir, filepath = nil, revision_number = nil)
    # Modify the path of the repository
    # If libsvn-ruby raise a segfault, check the first argument of
    # Svn::Client::export which must be an URI (ex : file:///home/...)

    if !filepath.nil?
      repo_path_dir = "file://#{File.join(expand_path(@repos_path), filepath)}"
    else
      repo_path_dir = "file://#{expand_path(@repos_path)}"
    end

    ctx = Svn::Client::Context.new

    # don't fail on non CA signed ssl server
    ctx.add_ssl_server_trust_file_provider
    setup_auth_baton(ctx.auth_baton)
    ctx.add_username_provider

    # username and password
    ctx.add_simple_prompt_provider(0) do |cred, _realm, _username, _may_save|
      cred.username = 'markus'
      cred.password = 'markus'
      cred.may_save = false
    end

    # Raise an error if the destination repository already exists
    if File.exist?(repo_dest_dir)
      raise(ExportRepositoryAlreadyExists,
            'Exported repository already exists')
    end

    ctx.export(repo_path_dir, repo_dest_dir, revision_number, nil)
  end

  # Closes the repository
  def close
    @repos.close
  end

  # Returns whether or not repository is closed
  def closed?
    @repos.closed?
  end

  # Static method: Reports if a Subversion repository exists
  # It's in fact a pretty hacky method checking for files typical
  # for Subversion repositories
  def self.repository_exists?(repos_path)
    repos_meta_files_exist = false
    if File.exist?(File.join(repos_path, 'conf')) &&
        File.exist?(File.join(repos_path, 'conf/svnserve.conf')) &&
        File.exist?(File.join(repos_path, 'format'))
      repos_meta_files_exist = true
    end
    repos_meta_files_exist
  end

  def self.get_checkout_command(external_repo_url, revision_number, group_name, repo_folder = nil)
    unless repo_folder.nil?
      external_repo_url += "/#{repo_folder}"
    end
    "svn checkout -r #{revision_number} \"#{external_repo_url}\" \"#{group_name}\""
  end

  # Given a single object, or an array of objects of type
  # RevisionFile, try to find the file in question, and
  # return it as a string
  def stringify_files(files)
    expects_array = files.is_a? Array
    unless expects_array
      files = [files]
    end
    files.collect! do |file|
      unless file.is_a? Repository::RevisionFile
        raise TypeError, 'Expected a Repository::RevisionFile'
      end
      begin
        @repos.fs.root(file.from_revision).file_contents(File.join(file.path, file.name), &:read)
      rescue Svn::Error::FS_NOT_FOUND
        raise FileDoesNotExistConflict, File.join(file.path, file.name)
      end
    end
    if !expects_array
      files.first
    else
      files
    end
  end
  alias download_as_string stringify_files # create alias

  # Returns a Repository::SubversionRevision instance
  # holding the latest Subversion repository revision
  # number
  def get_latest_revision
    get_revision(latest_revision_number)
  end

  # Returns revision_number wrapped
  # as a SubversionRevision instance
  def get_revision(revision_number)
    SubversionRevision.new(revision_number, self)
  end

  # Returns a SubversionRevision instance representing
  # a revision at a current timestamp
  #    target_timestamp
  # should be a Ruby Time instance
  def get_revision_by_timestamp(at_or_earlier_than, path = nil, _later_than = nil)
    unless at_or_earlier_than.is_a?(Time)
      raise 'Was expecting a timestamp of type Time'
    end
    at_or_earlier_than = at_or_earlier_than.utc
    if !path.nil?
      # latest_revision_number will fail if the path does not exist at the given revision number or less than
      # the revision number. The begin and ensure statement is to ensure that there is a nil return.
      begin
        revision_number = latest_revision_number(path, get_revision_number_by_timestamp(at_or_earlier_than))
        get_revision(revision_number)
      rescue StandardError
        nil
      end
    else
      get_revision(get_revision_number_by_timestamp(at_or_earlier_than))
    end
  end

  def get_all_revisions
    revisions = []
    latest_revision_number.downto(1) do |revision_number|
      revisions << get_revision(revision_number)
    end
    revisions
  end

  # Returns a Repository::TransAction object, to work with. Do operations,
  # like 'add', 'remove', etc. on the transaction instead of the repository
  def get_transaction(user_id, comment = '')
    if user_id.nil?
      raise 'Expected a user_id (Repository.get_transaction(user_id))'
    end
    Repository::Transaction.new(user_id, comment)
  end

  # Carries out actions on a Subversion repository stored in
  # 'transaction'. In case of certain conflicts corresponding
  # Repositor::Conflict(s) are added to the transaction object
  def commit(transaction)
    jobs = transaction.jobs
    txn = @repos.fs.transaction # transaction date is set implicitly
    txn.set_prop(Svn::Core::PROP_REVISION_AUTHOR, transaction.user_id)
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
      when :remove, :remove_directory
        begin
          txn = remove_file(txn, job[:path], job[:expected_revision_identifier])
        rescue Repository::Conflict => e
          transaction.add_conflict(e)
        end
      when :replace
        begin
          txn = replace_file(txn, job[:path], job[:file_data], job[:mime_type], job[:expected_revision_identifier])
        rescue Repository::Conflict => e
          transaction.add_conflict(e)
        end
      end
    end

    if transaction.conflicts?
      return false
    end
    txn.commit
    true
  end

  # Converts a pathname to an absolute pathname
  def expand_path(file_name, dir_string = '/')
    expanded = File.expand_path(file_name, dir_string)
    if RUBY_PLATFORM =~ /(:?mswin|mingw)/ # only if the platform is Windows
      expanded = expanded[2..-1] # remove the drive letter
    end
    expanded
  end

  ####################################################################
  ##  Semi-private class methods (one should not use them from outside
  ##  this class).
  ####################################################################

  # Semi-private class method
  def self.__read_in_authz_file
    # Check if configuration is in order
    unless Settings.repository.is_repository_admin
      raise NotAuthorityError, 'Unable to read authsz file: ' \
                               'Not in authoritative mode!'
    end
    unless File.exist?(Repository::PERMISSION_FILE)
      # create file if it doesn't exist
      File.open(Repository::PERMISSION_FILE, 'w').close
    end
    # Load up the Permissions:
    file_content = ''
    File.open(Repository::PERMISSION_FILE, 'r+') do |auth_file|
      auth_file.flock(File::LOCK_EX)
      begin
        file_content = auth_file.read
      ensure
        auth_file.flock(File::LOCK_UN) # release lock
      end
    end
    file_content
  end

  # Semi-private class method
  def self.__write_out_authz_file(authz_file_contents)
    # Check if configuration is in order
    unless Settings.repository.is_repository_admin
      raise NotAuthorityError, 'Unable to write authsz file: Not in authoritative mode!'
    end

    unless File.exist?(Repository::PERMISSION_FILE)
      # create file if not existent
      FileUtils.mkdir_p(File.dirname(Repository::PERMISSION_FILE))
      File.open(Repository::PERMISSION_FILE, 'w').close
    end
    result = false
    File.open(Repository::PERMISSION_FILE, 'w+') do |auth_file|
      # Blast out the string to the file
      result = (auth_file.write(authz_file_contents) == authz_file_contents.length)
    end
    result
  end

  # Semi-private class method: Parses a subversion authz file passed in as a string
  def self.__parse_authz_file(authz_string)
    permissions_mapping = {}

    permissions_array = authz_string.scan(%r{\[(.+):/\]\n([\w\s=]+)})
    permissions_array.each do |permissions_group|
      # The first match is the group repository name
      user_permissions = {}
      raw_users_permissions = permissions_group[1].scan(/\s*(\w+)\s*=\s*(\w+)\s*/)
      raw_users_permissions.each do |raw_user_permissions|
        user_permissions[raw_user_permissions[0]] = self.__translate_perms_from_file(raw_user_permissions[1])
      end
      permissions_mapping[permissions_group[0]] = user_permissions
    end
    permissions_mapping
  end

  # Semi-private class method: Transforms passed in permissions into
  # subversion authz file syntax
  def self.__prepare_authz_string(permissions)
    result = ''
    permissions.each do |repository_name, users_permissions|
      result += "[#{repository_name}:/]\n"
      users_permissions.each do |user_id, user_permissions|
        user_permissions_string = self.__translate_to_svn_perms(user_permissions)
        result += "#{user_id} = #{user_permissions_string}\n"
      end
      result += "\n"
    end
    result
  end

  ####################################################################
  ##  The following stuff is semi-private. As a general rule don't use
  ##  it directly. The only reason it's public, is that
  ##  SubversionRevision needs to have access.
  ####################################################################

  # Not (!) part of the AbstractRepository API:
  # Check if given file or path exists in repository beeing member of
  # the provided revision
  def __path_exists?(path, revision = nil)
    @repos.fs.root(revision).check_path(path) != 0
  end

  # Not (!) part of the AbstractRepository API:
  # Returns a hash of files/directories part of the requested
  # revision; Don't use it directly, use SubversionRevision's
  # 'files_at_path' instead
  def __get_files(path = '/', revision_number = nil)
    begin
      entries = @repos.fs.root(revision_number).dir_entries(path)
    rescue StandardError
      raise FileDoesNotExist, "#{path} does not exist in the repository for revision #{revision_number}"
    end
    entries.each do |key, value|
      entries[key] = value.kind == 1 ? :file : :directory
    end
    entries
  end

  # Not (!) part of the AbstractRepository API:
  # Returns
  #    prop
  # of Subversion repository
  def __get_property(prop, rev = nil)
    @repos.prop(prop, rev)
  end

  # Not (!) part of the AbstractRepository API:
  # Returns
  #    prop
  # of Subversion repository file

  def __get_file_property(prop, path, revision_number)
    @repos.fs.root(revision_number).node_prop(path, prop)
  end

  # Not (!) part of the AbstractRepository API:
  # Returns
  #    The last modified date
  # of a Subversion repository file or directory

  def __get_node_last_modified_date(path, revision_number)
    @repos.fs.root(revision_number).stat(path).time2
  end

  # Not (!) part of the AbstractRepository API:
  # This function is very similar to @repos.fs.history(); however, it's been altered a little
  # to return only an array of revision numbers. This function, in contrast to the original,
  # takes multiple paths and returns one large history for all paths given.
  def __get_history(paths, starting_revision = nil, ending_revision = nil)
    # We do the to_i's because we want to leave the value nil if it is.
    if starting_revision.to_i < 0
      raise "Invalid starting revision #{starting_revision.to_i}."
    end
    revision_numbers = []
    paths = [paths].flatten
    paths.each do |path|
      hist = []
      history_function = proc do |path_, revision|
        yield(path_, revision) if block_given?
        hist << revision
      end
      begin
        Svn::Repos.history2(@repos.fs, path, history_function, nil, starting_revision || 0,
                            ending_revision || @repos.fs.youngest_rev, true)
      rescue Svn::Error::FS_NOT_FOUND
        raise Repository::FileDoesNotExistConflict, path
      rescue Svn::Error::FS_NO_SUCH_REVISION
        raise "Ending revision #{ending_revision} does not exist."
      end
      revision_numbers.concat hist
    end
    revision_numbers.sort.uniq
  end

  # Helper method to translate internal permissions to Subversion
  # permissions
  def self.__translate_to_svn_perms(permissions)
    case permissions
    when Repository::Permission::READ
      'r'
    when Repository::Permission::READ_WRITE
      'rw'
    else raise 'Unknown permissions'
    end
  end

  # Helper method to translate Subversion permissions to internal
  # permissions
  def self.__translate_perms_from_file(perm_string)
    case perm_string
    when 'r'
      Repository::Permission::READ
    when 'rw'
      Repository::Permission::READ_WRITE
    else raise 'Unknown permissions'
    end
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

  # Generate and write the SVN authorization file for the repo.
  def self.update_permissions_file(permissions)
    return true unless Settings.repository.is_repository_admin
    authz_string = ''
    permissions.each do |repo_name, users|
      authz_string += "[#{repo_name}:/]\n"
      users.each do |user_name|
        authz_string += "#{user_name} = rw\n"
      end
      authz_string += "\n"
    end
    __write_out_authz_file(authz_string)
  end

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
    if path.nil?
      @repos.fs.youngest_rev
    else
      begin
        data = Svn::Repos.get_committed_info(@repos.fs.root(revision_number || @repos.fs.youngest_rev), path)
        data[0]
      rescue Svn::Error::FS_NOT_FOUND
        raise Repository::FileDoesNotExistConflict, path
      rescue Svn::Error::FS_NO_SUCH_REVISION
        raise "Revision #{revision_number} does not exist."
      end
    end
  end

  # Assumes timestamp is a Time object (which is part of the Ruby
  # standard library)
  def get_revision_number_by_timestamp(target_timestamp)
    unless target_timestamp.is_a?(Time)
      raise 'Was expecting a timestamp of type Time'
    end
    @repos.dated_revision(target_timestamp)
  end

  # adds a file to a transaction and eventually to repository
  def add_file(txn, path, file_data = nil, mime_type = nil)
    if __path_exists?(path)
      raise Repository::FileExistsConflict, path
    end
    write_file(txn, path, file_data, mime_type)
  end

  # removes a file from a transaction and eventually from repository
  def remove_file(txn, path, expected_revision_number = 0)
    if latest_revision_number.to_i != expected_revision_number.to_i
      raise Repository::FileOutOfSyncConflict, path
    end
    unless __path_exists?(path)
      raise Repository::FileDoesNotExistConflict, path
    end
    txn.root.delete(path)
    txn
  end

  # replaces file at provided path with file_data
  def replace_file(txn, path, file_data = nil, mime_type = nil, expected_revision_number = 0)
    # NOTE: this check is inconsistent with the MemoryRepository
    if latest_revision_number.to_i > expected_revision_number.to_i
      raise Repository::FileOutOfSyncConflict, path
    end
    write_file(txn, path, file_data, mime_type)
  end

  def write_file(txn, path, file_data = nil, mime_type = nil)
    unless __path_exists?(path)
      pieces = path.split('/').delete_if { |x| x == '' }
      dir_path = ''

      (0..pieces.length - 2).each do |index|
        dir_path += "/#{pieces[index]}"
        txn = make_directory(txn, dir_path)
      end
      txn = make_file(txn, path)
    end
    stream = txn.root.apply_text(path)
    stream.write(file_data)
    stream.close
    # Set the mime type...
    txn.root.set_node_prop(path, Svn::Core::PROP_MIME_TYPE, mime_type)
    txn
  end

  # Make a file if it's not already present.
  def make_file(txn, path)
    if txn.root.check_path(path) == 0
      txn.root.make_file(path)
    end
    txn
  end

  # Make a directory if it's not already present.
  def make_directory(txn, path)
    # turn "path" into absolute path
    path = expand_path(path, '/')
    # do nothiing if "path" is the root
    return txn if path == '/'

    # get the path of parent folder
    parent_path = File.dirname(path)
    # and create parent folder before the current folder (recursively)
    txn = make_directory(txn, parent_path)

    # now that the parent folder has been created,
    # create the current folder
    if txn.root.check_path(path) == 0
      txn.root.make_dir(path)
    end

    txn
  end

  # Parses repository permissions from provided auth_file
  def get_repo_permissions_from_file_string(auth_string)
    u_perm_mapping = {}
    repo_name = File.basename(@repos_path)
    if %r{\[#{repo_name}:/\]([^\[]+)}.match(auth_string)
      perm_string = Regexp.last_match(1)
      perm_string.strip.split("\n").each do |line|
        if /\s*(\w+)\s*=\s*(\w+)\s*/.match(line)
          u_perm_mapping[Regexp.last_match(1).to_s] = Regexp.last_match(2).to_s
        end
      end
      u_perm_mapping
    else
      {} # repo name not found
    end
  end

  # Helper method to check file permissions of svn auth file
  def svn_auth_file_checks
    unless @repos_admin # if we are not admin, check if files exist
      unless File.file?(@repos_auth_file)
        raise FileDoesNotExist, "'#{@repos_auth_file}' not a file or not existent"
      end
      unless File.readable?(@repos_auth_file)
        raise "File '#{@repos_auth_file}' not readable"
      end
    end
    true
  end

  # Helper method to inject new permissions. Expects a hash representing
  # users <=> svn permissions mapping and the current file contents of
  # the svn authz file as a string
  def inject_permissions(users_permissions, auth_string)
    repo_name = File.basename(@repos_path)
    auth_string = auth_string.strip
    map_string = perm_mapping_to_svn_authz_string(users_permissions)
    if %r{\[#{repo_name}:/\][^\[]+}.match(auth_string)
      auth_string = auth_string.sub(%r{\[#{repo_name}:/\][^\[]+}, map_string)
    else
      # repo name not found so append at the end
      auth_string += "\n#{map_string}"
    end

    # format file_string a little
    auth_string = auth_string.strip # get rid of leading/trailing white-space
    lines = auth_string.split("\n")
    tmp_filestring = ''
    is_extraneous_empty_line = false
    lines.each do |line|
      if line == ''
        unless is_extraneous_empty_line
          tmp_filestring += "\n"
        end
        is_extraneous_empty_line = true
      else
        tmp_filestring += line + "\n"
        is_extraneous_empty_line = false
      end
    end
    tmp_filestring
  end

  # Translates a user <=> permissions mapping to a string corresponding
  # to Subversions authz file format
  def perm_mapping_to_svn_authz_string(users_perms)
    if users_perms.empty?
      return ''
    end
    repo_name = File.basename(@repos_path)
    result_string = "\n[#{repo_name}:/]\n"
    users_perms.each do |user, permstr|
      result_string += "#{user} = #{permstr}\n"
    end
    result_string
  end
end
