require "svn/repos"
require "md5"
require "fileutils"
require 'lib/repo/repository'

module Repository

SVN_CONSTANTS = {
  :author => Svn::Core::PROP_REVISION_AUTHOR, 
  :date => Svn::Core::PROP_REVISION_DATE,
  :mime_type => Svn::Core::PROP_MIME_TYPE
}
SVN_FS_TYPES = {:fsfs => Svn::Fs::TYPE_FSFS, :bdb => Svn::Fs::TYPE_BDB}


class InvalidSubversionRepository < Repository::ConnectionError; end

class SubversionRepository < Repository::AbstractRepository

  
  def initialize(connect_string)
    @repos_path = connect_string
    if (self.class.repository_exists?(@repos_path))
      @repos = Svn::Repos.open(@repos_path)
    else
      raise "Repository does not exist at path \"" + @repos_path + "\""
    end
  end

  def self.create(connect_string, fs_type = :fsfs)
    if self.repository_exists?(connect_string)
      raise RepositoryCollision.new("There is already a repository at #{connect_string}")
    end
    if !self.repository_path_valid?(connect_string)
      raise IOError.new("Could not create a repository at #{connect_string}")
    end
    
    fs_config = {Svn::Fs::CONFIG_FS_TYPE => Repository::SVN_FS_TYPES[fs_type]} 
    Svn::Repos.create(connect_string, {}, fs_config)
    SubversionRepository.open(connect_string)
    
  end
  
  def self.open(connect_string)
    SubversionRepository.new(connect_string)
  end

  # Given a repositoryFile of class File, try to find the File in question, and
  # return it as a string
  def download(files)
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
  
  def get_latest_revision
    return get_revision(latest_revision_number)
  end
  
  def self.repository_exists?(repos_path)
    return File.exist?(File.join(repos_path, "format"))
  end
  
  def property(prop, rev=nil)
    return @repos.prop(Repository::SVN_CONSTANTS[prop] || prop.to_s, rev)  
  end
  
  def ls(path="/", revision_number=nil)
    entries = @repos.fs.root(revision_number).dir_entries(path)
    entries.each do |key, value|
      entries[key] = (value.kind == 1) ? :file : :directory
    end
    return entries
  end
  
  # This function is very similar to @repos.fs.history(); however, it's been altered a little
  # to return only an array of revision numbers. This function, in contrast to the original,
  # takes multiple paths and returns one large history for all paths given.
  def history(paths, starting_revision=nil, ending_revision=nil)

    # We do the to_i's because we want to leave the value nil if it is.
    if (starting_revision.to_i < 0)
      raise "Invalid start revision " + starting_revision.to_i.to_s + "."
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
  
  def get_revision(revision_number)
    return Repository::SubversionRevision.new(revision_number, self)   
  end
  
  # Assumes timestamp is a Time object (which is part of the Ruby standard library)
  def get_revision_number_by_timestamp(target_timestamp)
    if !target_timestamp.kind_of?(Time)
      raise "Was expecting a timestamp of type Time"
    end
    @repos.dated_revision(target_timestamp)
  end
  
  def get_revision_by_timestamp(target_timestamp)
    if !target_timestamp.kind_of?(Time)
      raise "Was expecting a timestamp of type Time"
    end
    return get_revision(get_revision_number_by_timestamp(target_timestamp))
  end
  
  
  # Commit a file. This function either takes in a hash with the :path and :data
  # keys set to their respective values, or it takes in an array of hashes each with the
  # same keys set. Passing an array will let you commit multiple files at once.
  # 
  # The attributes hash is optional, and as of now, is only available for setting the
  # author of a revisoin. An example would be {:author => "tcoulter"}.
  # 
  # Note that this function takes care of making sure files and directories are present
  # within the repository. You don't have to create them; this function will do it for you.
  def commit(transaction)
    jobs = transaction.jobs
    txn = @repos.fs.transaction # transaction date is set implicitly
    txn.set_prop(Repository::SVN_CONSTANTS[:author], transaction.user_id)
    jobs.each do |job|
      case job[:action]
        when :add_path
          begin
            make_directory(txn, job[:path])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :add
          begin
            add_file(txn, job[:path], job[:file_data])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :remove
          begin
            remove_file(txn, job[:path], job[:expected_revision_number])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
        when :replace
          begin
            replace_file(txn, job[:path], job[:file_data], job[:expected_revision_number])
          rescue Repository::Conflict => e
            transaction.add_conflict(e)
          end
      end
    end
    
    if transaction.conflicts?
      return false
    end
    
    @repos.commit(txn)
    return true
  end
  
  
  def get_transaction(user_id, comment="")
    if user_id.nil?
      raise "Expected a user_id (Repository.get_transaction(user_id))"
    end
    return Repository::Transaction.new(user_id, comment)
  end
  
  
  def get_users

  end
  
  def add_user(user_id)

  end
  
  def remove_user(user_id)

  end

  def path_exists?(path, revision=nil)
    return @repos.fs.root(revision).check_path(path) != 0
  end 
  
  private
  
  def add_file(txn, path, file_data=nil)
    if path_exists?(path)
      raise Repository::FileExistsConflict.new(path)
    end
    write_file(txn, path, file_data)
  end
  
  def remove_file(txn, path, expected_revision_number=0)
    if latest_revision_number(path).to_i != expected_revision_number.to_i
      raise Repository::FileOutOfSyncConflict.new(path)
    end
    if !path_exists?(path)
      raise Repository::FileDoesNotExistConflict.new(path)
    end
    txn.root.delete(path)
  end
  
  def replace_file(txn, path, file_data=nil, expected_revision_number=0)
    if latest_revision_number(path).to_i != expected_revision_number.to_i
      raise Repository::FileOutOfSyncConflict.new(path)
    end
    write_file(txn, path, file_data)
  end
  
  def write_file(txn, path, file_data=nil)
     if (!path_exists?(path))
      pieces = path.split("/").delete_if {|x| x == ""}
      dir_path = ""
      
      (0..pieces.length - 2).each do |index|     
        dir_path += "/" + pieces[index]
        make_directory(txn, dir_path)
      end
      make_file(txn, path)
    end
    stream = txn.root.apply_text(path)
    stream.write(file_data)
    stream.close 
  end
  
  # Make a file if it's not already present.
  def make_file(txn, path)
    if (txn.root.check_path(path) == 0)
      txn.root.make_file(path)
    end
  end
  
  # Make a directory if it's not already present.
  def make_directory(txn, path)  
    if (txn.root.check_path(path) == 0)
      txn.root.make_dir(path)
    end
  end

end

class SubversionRevision < Repository::AbstractRevision

  def initialize(revision_number, repo)
    @repo = repo
    begin 
      @repo.property(:date, revision_number).nil? 
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
    return @repo.path_exists?(path, @revision_number)
  end
  
  def directories_at_path(path='/')
    result = Hash.new(nil)
    raw_contents = @repo.ls(path, @revision_number)
    raw_contents.each do |file_name, type|
      if type == :directory
        last_modified_revision = @repo.history(File.join(path, file_name)).last
        new_directory = Repository::RevisionDirectory.new(@revision_number, {
          :name => file_name,
          :path => path,
          :last_modified_revision => last_modified_revision,
          :changed => (last_modified_revision == @revision_number),
          :user_id => @repo.property(:author, last_modified_revision)
        })
        result[file_name] = new_directory
      end
    end
    return result
  end
  
  def changed_files_at_path(path)
    return files_at_path_helper(path, true)
  end
  
  private
  
  def files_at_path_helper(path='/', only_changed=false)
    if path.nil?
      path = '/'
    end
    result = Hash.new(nil)
    raw_contents = @repo.ls(path, @revision_number)
    raw_contents.each do |file_name, type|
      if type == :file
        last_modified_revision = @repo.history(File.join(path, file_name), nil, @revision_number).last

        if(!only_changed || (last_modified_revision == @revision_number))
          new_file = Repository::RevisionFile.new(@revision_number, {
            :name => file_name,
            :path => path,
            :last_modified_revision => last_modified_revision,
            :changed => (last_modified_revision == @revision_number),
            :user_id => @repo.property(:author, last_modified_revision)
          })
          result[file_name] = new_file
        end
      end
    end
    return result
  end    


end

end
