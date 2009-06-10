# Copyright (c) 2007 Tim Coulter
# 
# You are free to modify and use this file under the terms of the GNU LGPL.
# You should have received a copy of the LGPL along with this file.
# 
# Alternatively, you can find the latest version of the LGPL here:
#      
#      http://www.gnu.org/licenses/lgpl.txt
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.


require "svn/repos"
require "md5"
require "fileutils"

# Define three exceptions that will be used to "translate" actual Subversion
# exceptions to give nicer names and maintain separation.
class SvnPathNotFoundError < RuntimeError
end

class SvnNoSuchRevisionError < RuntimeError
end

class SvnNoSuchTransactionError < RuntimeError
end

class SvnRepos

  attr_reader :repos_path
  
  # Translate Subverion specific constants into more programmer friendly terms.
  SVN_CONSTANTS = {:author => Svn::Core::PROP_REVISION_AUTHOR, :date => Svn::Core::PROP_REVISION_DATE}
  SVN_FS_TYPES = {:fsfs => Svn::Fs::TYPE_FSFS, :bdb => Svn::Fs::TYPE_BDB}

  # Constructor. Open the repository if it exists.  
  def initialize(repos_path)
  
    @repos_path = repos_path
  
    if (self.class.repository_exists?(@repos_path))
      @repos = Svn::Repos.open(@repos_path)
    else
      raise "Repository does not exist at path \"" + @repos_path + "\""
    end
    
  end
  
  # Synonym for new.
  def self.open(repos_path)
    SvnRepos.new(repos_path)
  end
  
  # Create a new repository if one doesn't already exist.
  # 
  # The FS type defaults to :fsfs. If you get the "Can't grab FSFS repository mutex" error,
  # you need to upgrade Subversion and your Subversion Ruby Bindings to version 1.4 or higher.
  # Alternatively, you can use :bdb.
  # 
  # Here's more info: http://svn.haxx.se/dev/archive-2006-10/0010.shtml
  def self.create(repos_path, fs_type = :fsfs)
    if (self.repository_exists?(repos_path))
      raise "Repository already exists at path \"" + repos_path + "\"; cannot create."
    end
    
    fs_config = {Svn::Fs::CONFIG_FS_TYPE => SVN_FS_TYPES[fs_type]} 
    Svn::Repos.create(repos_path, {}, fs_config)
    SvnRepos.open(repos_path)
  end
  
  def self.repository_exists?(repos_path)
    File.exist?(File.join(repos_path, "format"))
  end
  
  def self.delete!(repos_path)
    FileUtils.remove_dir(repos_path, false)
  end
  
 
  # Commit a file. This function either takes in a hash with the :path and :data
  # keys set to their respective values, or it takes in an array of hashes each with the
  # same keys set. Passing an array will let you commit multiple files at once.
  # 
  # The attributes hash is option, and as of now, is only available for setting the
  # author of a revisoin. An example would be {:author => "tcoulter"}.
  # 
  # Note that this function takes care of making sure files and directories are present
  # within the repository. You don't have to create them; this function will do it for you.
  def commit(requests={})
    
    if (block_given?)
      yield requests
    end
    
    throw "Nothing commited. Request size was 0!" if (requests.size == 0)
    
    txn = begin_transaction(requests)
    add_to_transaction(requests, txn)
    commit_transaction(txn)
  end
  
  def begin_transaction(requests={})
    #txn = @repos.transaction_for_commit(requests[:author], requests[:log])
    txn = @repos.fs.transaction    
    
#    requests.delete(:author)
#    requests.delete(:log)
    
    requests.each do |request, value|
      if (request.kind_of? Symbol)
        txn.set_prop(SVN_CONSTANTS[request] || request.intern, value)
      end
    end
    
    txn
  end
  
  def add_to_transaction(requests, txn)
    process_commit_list(requests, txn)
  end
  
  def commit_transaction(txn)
    raise SvnNoSuchTransactionError.new("Transaction doesn't exist in repository.") unless @repos.fs.transactions.include?(txn.name)
    @repos.commit(txn)
  end
  
  # Get the contents of a file at a specific revision.
  # If no revision is passed, the most recent data is returned.
  # 
  # Note: If the files at the given path does not exist at the specified revision,
  # then this function will return nil.
  # TODO: Check the above statement.
  def file_contents(paths, revision = nil)
  
    expects_array = paths.kind_of? Array
    if (!expects_array)
      paths = [paths]  
    end
    
    paths.collect! {|path|
    
      throw "Nil path found!" if (path.nil?) 

      begin
        @repos.fs.root(revision).file_contents(path){|f| f.read}
      rescue Svn::Error::FS_NOT_FOUND => e
        throw_path_not_found_error(e.message)
      rescue Exception => e
        raise SvnNoSuchRevisionError.new("Revision " + revision.to_s + " does not exist.")
      end
    }
    
    if (!expects_array)
      paths.first
    else
      paths
    end
  end
  
  # This function is very similar to @repos.fs.history(); however, it's been altered a little
  # to return only an array of revision numbers. This function, in contrast to the original,
  # takes multiple paths and returns one large history for all paths given.
  def history(paths, starting_revision=nil, ending_revision=nil)

    # We do the to_i's because we want to leave the value nil if it is.
    if (starting_revision.to_i < 0)
      raise SvnNoSuchRevisionError.new("Invalid start revision " + starting_revision.to_i.to_s + ".")
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
      rescue Svn::Error::FS_NOT_FOUND => e
        throw_path_not_found_error(e.message)
      rescue Svn::Error::FS_NO_SUCH_REVISION => e
        raise SvnNoSuchRevisionError.new("Ending revision " + ending_revision.to_s + " does not exist.")
      end
                          
      revision_numbers.concat hist
    end
    
    revision_numbers.sort.uniq
  end
  
  # Get the Subversion properties for a given revision id, or an array of revision ids.
  # It returns an array of hashes, where each hash in the returned array corresponds with the
  # revision id in the passed array. This function works cleanly with the return value of history().
  def properties(revisions)
      revisions = [revisions].flatten
      revisions.collect{|revision|
        begin
          proplist = @repos.fs.proplist(revision)
        rescue Svn::Error::FS_NO_SUCH_REVISION => e
          raise SvnNoSuchRevisionError.new("Revision " + revision.to_s + " does not exist.")
        end
        proplist[:id] = revision
        make_hash_friendly(proplist)
        proplist
      }  
  end
  
  def property(prop, rev=nil)
    @repos.prop(SVN_CONSTANTS[prop] || prop.to_s, rev)  
  end
  
  # Diff the file at a given path and revision with the file at the given
  # base_path and base_revision. The value of revision is considered
  # to be newer in time; if a higher number is specified for base_revision than revision,
  # this function will be diffing backwards in time.
  #
  # This function was pulled from the do_diff function in the Binding's info.rb and
  # edited to suit our needs.
  def diff(base_path, base_revision, path, revision)

    # Note: This differ statement was taken from the Subverion Bindings try_diff()
    # function in info.rb; there were four options for situations I didn't understand.
    # This may not work as expected for all situations (however, it seems to for all I've tried).
    begin
      differ = Svn::Fs::FileDiff.new(@repos.fs.root(base_revision), base_path, @repos.fs.root(revision), path)
    
      diff = ""
  
      if differ.binary?
        diff = "(Binary files differ)\n"
      else
        base_label = "#{base_path} (rev #{base_revision})"
        label = "#{path} (rev #{revision})"
        diff = differ.unified(base_label, label)
      end
    
    rescue Svn::Error::FS_NOT_FOUND => e
      throw_path_not_found_error(e.message)
    rescue Svn::Error::FS_NO_SUCH_REVISION => e
      raise SvnNoSuchRevisionError.new("Either revision " + base_revision.to_s + " or revision " + revision.to_s + " does not exist.")
    end
    
    diff
  end

  # Returns the most recent revision of the repository. If a path is specified, 
  # the youngest revision is returned for that path; if a revision is also specified,
  # the function will return the youngest revision that is equal to or older than the one passed.
  # 
  # This will only work for paths that have not been deleted from the repository.
  def youngest_revision(path=nil, revision=nil)
    if (!path.nil?)
      begin
        data = Svn::Repos.get_committed_info(@repos.fs.root(revision || @repos.fs.youngest_rev), path)
        return data[0]
      rescue Svn::Error::FS_NOT_FOUND => e
        throw_path_not_found_error(e.message)
      rescue Svn::Error::FS_NO_SUCH_REVISION => e
        raise SvnNoSuchRevisionError.new("Revision " + revision.to_s + " does not exist.")
      end
    else
      return @repos.fs.youngest_rev
    end
  end
  
  def revision_count
    youngest_revision
  end
  
  def path_exists?(path, revision=nil)
    @repos.fs.root(revision).check_path(path) != 0
  end
  
  def touch(path, attributes={})
    if (!path_exists?(path))
      commit({path => ""}.merge(attributes))
    end
  end
  
  def delete(path, attributes={})
    begin
      txn = begin_transaction(attributes)
      txn.root.delete(path)
      commit_transaction(txn)
    rescue Svn::Error::FS_NOT_FOUND => e
      throw_path_not_found_error(e.message)
    end
  end
  
  # Provides a list of directory entries. path must be a directory.
  def ls(path="/", revision=nil)
    entries = @repos.fs.root(revision).dir_entries(path)
    entries.each do |key, value|
      entries[key] = (value.kind == 1) ? :file : :directory
    end
    entries
  end
  
  # Dump the filesystem. There's a lot of functionality here that is not being
  # utilized, and there may be special cases I don't understand (like, what's with the
  # feedback thing; the second parameter?).
  def dump
    dump_stream = StringIO.new("")
    @repos.dump_fs(dump_stream, StringIO.new(""), 0, @repos.youngest_rev)
    dump_stream.rewind
    dump_stream.read
  end
  
  def load(dump_stream)
    dump_stream = StringIO.new(dump_stream) if (dump_stream.is_a? String)
    dump_stream.rewind
    @repos.load_fs(dump_stream, StringIO.new(""), Svn::Repos::LOAD_UUID_DEFAULT, "/")     
  end
  
private

  def process_commit_list(requests, txn)
    requests.each do |key, value|
      # If the request key is a string, then the key represents a file
      # within the repository.
      if (key.kind_of? String)
        write_file(txn, key, value)
      end
    end 
  end

  # Make a directory if it's not already present.
  def make_directory(txn, path)  
    if (txn.root.check_path(path) == 0)
      txn.root.make_dir(path)
    end
  end

  # Make a file if it's not already present.
  def make_file(txn, path)
    if (txn.root.check_path(path) == 0)
      txn.root.make_file(path)
    end
  end
  
  # Set the author if it's present in the attributes hash.
  def set_author_if_present(txn, requests)
    if (requests.has_key? :author)
      txn.set_prop(SVN_CONSTANTS[:author], requests[:author])
    end
  end
  
  # Helper. This function does the actual writing.
  def write_file(txn, path, data)
    
    if (!path_exists?(path))
      pieces = path.split("/").delete_if {|x| x == ""}
        
      dir_path = ""
      (0..pieces.length - 2).each do |index|
      
        dir_path += "/" + pieces[index]
        make_directory(txn, dir_path)
      end
      
      make_file(txn, path)
    end
    
    #checksum = MD5.new(data).hexdigest
    stream = txn.root.apply_text(path)#, checksum)
    stream.write(data)
    stream.close 
  end

  def make_hash_friendly(hash)
    SVN_CONSTANTS.each do |friendly_key, svn_key|
      if (hash.has_key?(svn_key))
        hash[friendly_key] = hash[svn_key] 
        hash.delete(svn_key)
      end              
    end
  end
  
  def throw_path_not_found_error(svn_message)
    message = svn_message[svn_message.rindex("File not found")..svn_message.length-1]
    raise SvnPathNotFoundError.new(message)
  end
  
  def throw_cant_open_directory_error(svn_message)
    message = svn_message[svn_message.rindex("Can't open directory")..svn_message.length-1] 
    raise SvnPathNotFoundError.new(message)
  end
  
end
