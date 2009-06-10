module Repository

# Exceptions for Repositories
class ConnectionError < Exception; end

class Conflict < Exception
  attr_reader :path
  def initialize(path)
    @path = path
  end
  def to_s
    return 'There was an unspecified conflict with file ' + @path
  end
end

class FileExistsConflict < Conflict
  def to_s
    return "#{@path} could not be created - it already exists in the folder"
  end
end

class FileDoesNotExistConflict < Conflict
  def to_s
    return "#{@path} could not be changed - it was removed since you last saw it"
  end
end

class FileOutOfSyncConflict < Conflict
  def to_s
    return "#{@path} has been updated since you last saw it, and could not be changed"
  end
end

class RepositoryCollision < Exception; end

class AbstractRepository

  # Initializes Object, and verifies connection to the repository back end.
  # This should throw a ConnectionError if we're unable to connect.
  def initialize(connect_string)
    raise NotImplementedError, "Repository.initialize(connect_string): Not yet implemented"
  end
  
  def self.repository_path_valid?(path)
    return !File.exists?(path)
  end
  
  def self.open(connect_string)
    raise NotImplementedError, "Repository::open Not yet implemented"
  end
  
  def self.create(connect_string)
    raise NotImplementedError, "Repository::create Not yet implemented"
  end
  
  # Given a repositoryFile of class File, return a stream of data for
  # the user to download as that file.
  def download(repositoryFile)
    raise NotImplementedError,  "Repository.download: Not yet implemented"
  end 
  
  def get_transaction(user_id, comment)
    raise NotImplementedError,  "Repository.get_transaction: Not yet implemented"
  end  
  
  def number_of_revisions
    raise NotImplementedError, "Repository.number_of_revisions: Not yet implemented"
  end
  
  def get_latest_revision
    raise NotImplementedError, "Repository.get_latest_revision: Not yet implemented"
  end
    
  # Returns an array of File objects for all files in root_path, for a given
  # revision number
  def get_revision(revision)
    raise NotImplementedError,  "Repository.all_files_by_revision: Not yet implemented"
  end
  
  # Returns an array of File objects for all files in root_path, for a given
  # timestamp
  def get_revision_by_timestamp(timestamp)
    raise NotImplementedError,  "Repository.all_files_by_timestamp: Not yet implemented"
  end
   
  # Adds user permissions for read/write access to the repository
  def add_user(user_id)
    raise NotImplementedError,  "Repository.add_user: Not yet implemented"
  end
  
  # Removes user permissions for read/write access to the repository
  def remove_user(user_id)
    raise NotImplementedError,  "Repository.remove_user: Not yet implemented"
  end
  
  def get_users
    raise NotImplementedError, "Repository.get_users: Not yet implemented"
  end
  
end


# Exceptions for Revisions
class RevisionDoesNotExist < Exception; end
class RevisionOutOfSyncConflict < Conflict; end

class AbstractRevision
  attr_reader :revision_number, :timestamp, :user_id, :comment

  def initialize(revision_number)
    @revision_number = revision_number
  end
  
  def path_exists?(path)
    raise NotImplementedError, "Revision.path_exists? not yet implemented"
  end
  
  # Return all of the files in this repository at the root directory
  def files_at_path(path)
    raise NotImplementedError, "Revision.files_at_path not yet implemented"
  end
  
  def directories_at_path(path)
    raise NotImplementedError, "Revision.directories_at_path not yet implemented"
  end
  
  def changed_files_at_path(path)
    raise NotImplementedError, "Revision.changed_files_at_path not yet implemented"
  end    
end

# Exceptions for Files
class FileOutOfDate < Exception; end
class FileDoesNotExist < Exception; end


#################################################
#  Class File:
#        Files stored in a Revision
#################################################
class RevisionFile
   
  def initialize(from_revision, args)
    @name = args[:name]
    @path = args[:path]
    @last_modified_revision = args[:last_modified_revision]
    @changed = args[:changed]
    @user_id = args[:user_id]
    @from_revision = from_revision   
  end
  
  attr_accessor :name, :path, :last_modified_revision, :changed
  attr_accessor :from_revision, :user_id
    
end # end class File

class RevisionDirectory
   
  def initialize(from_revision, args)
    @name = args[:name]
    @path = args[:path]
    @last_modified_revision = args[:last_modified_revision]
    @changed = args[:changed]
    @user_id = args[:user_id]
    @from_revision = from_revision   
  end
  
  attr_accessor :name, :path, :last_modified_revision, :changed
  attr_accessor :from_revision, :user_id
    
end # end class File


class Transaction

  attr_reader :user_id, :comment, :jobs, :conflicts

  def initialize(user_id, comment)
    @user_id = user_id
    @comment = comment
    @jobs = []
    @conflicts = []
  end
  
  def add_path(path)
    @jobs.push(:action => :add_path, :path => path)
  end
  
  def add(path, file_data=nil)
    @jobs.push(:action => :add, :path => path, :file_data => file_data)
  end
  
  def remove(path, expected_revision_number)
    @jobs.push(:action => :remove, :path => path, :expected_revision_number => expected_revision_number)
  end
  
  def replace(path, file_data, expected_revision_number)
    @jobs.push(:action => :replace, :path => path, :file_data => file_data, :expected_revision_number => expected_revision_number)
  end
  
  def add_conflict(conflict)
    @conflicts.push(conflict)
  end
  
  def conflicts?
    @conflicts.size > 0
  end
  
  def has_jobs?
    @jobs.size > 0
  end
 
end


end # end module Repository
