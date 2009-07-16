module Repository

# Permission constants for repositories
class Permission
  if !defined? WRITE  # avoid constant already defined warnings
    WRITE      = 2
  end
  if !defined? READ
    READ       = 4
  end
  if !defined? READ_WRITE
    READ_WRITE = READ + WRITE
  end
  if !defined? ANY
    ANY        = READ # any permission means at least read permission
  end
end

# Exceptions for repositories
class ConnectionError < Exception; end

class Conflict < Exception
  attr_reader :path
  def initialize(path)
    super()
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
  # The is_admin flag indicates if we have admin privileges. If set to false,
  # the repository relies on a third party to create repositories and manage its
  # permissions.
  def initialize(connect_string, is_admin=true)
    raise NotImplementedError, "Repository.initialize(connect_string): Not yet implemented"
  end
  
  # Static method: Should report if a repository exists at given location
  def self.repository_exists?(path)
    raise NotImplementedError, "Repository::repository_exists? Not yet implemented"
  end
  
  # Static method: Opens a repository at given location; returns an
  # AbstractRepository instance
  def self.open(connect_string)
    raise NotImplementedError, "Repository::open Not yet implemented"
  end
  
  # Static method: Creates a new repository at given location; returns
  # an AbstractRepository instance, with the repository opened.  
  def self.create(connect_string)
    raise NotImplementedError, "Repository::create Not yet implemented"
  end
  
  # Given either an array of, or a single object of class RevisionFile, 
  # return a stream of data for the user to download as the file(s).
  def stringify_files(files)
    raise NotImplementedError,  "Repository.download: Not yet implemented"
  end
  alias download_as_string stringify_files

  # Returns a transaction for the provided user and uses comment as the commit message
  def get_transaction(user_id, comment)
    raise NotImplementedError,  "Repository.get_transaction: Not yet implemented"
  end  
  
  # Commits a transaction associated with a repository
  def commit(transaction)
    raise NotImplementedError,  "Repository.commit: Not yet implemented"
  end
  
  # Returns the latest Repository::AbstractRevision
  def get_latest_revision
    raise NotImplementedError, "Repository.get_latest_revision: Not yet implemented"
  end
    
  # Return a Repository::AbstractRevision for a given revision_number
  # if it exists
  def get_revision(revision_number)
    raise NotImplementedError,  "Repository.get_revision: Not yet implemented"
  end
  
  # Return a RepositoryRevision for a given timestamp
  def get_revision_by_timestamp(timestamp)
    raise NotImplementedError,  "Repository.get_revision_by_timestamp: Not yet implemented"
  end
   
  # Adds a user with a given permission-set to the repository
  def add_user(user_id, permissions)
    raise NotImplementedError,  "Repository.add_user: Not yet implemented"
  end
  
  # Removes user permissions for read & write access to the repository
  def remove_user(user_id)
    raise NotImplementedError,  "Repository.remove_user: Not yet implemented"
  end
  
  # Gets a list of users with permissions in question on the repository
  #   use "Repository::Permission::ANY" to get a list of all users with any permissions
  #   i.e. all users with at least read permissions
  def get_users(permissions)
    raise NotImplementedError, "Repository.get_users: Not yet implemented"
  end
  
  # Gets permissions for a particular user
  def get_permissions(user_id)
    raise NotImplementedError, "Repository.get_permissions: Not yet implemented"
  end
  
  # Sets permissions for a particular user
  def set_permissions(user_id, permissions)
    raise NotImplementedError, "Repository.set_permissions: Not yet implemented"
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
  
# Exceptions for repo user management
class UserNotFound < Exception; end
class UserAlreadyExistent < Exception; end
# raised, when trying to modify permissions and repo is not in authoritative mode
class NotAuthorityError < Exception; end


#################################################
#  Class File:
#        Files stored in a Revision
#################################################
class RevisionFile
   
  def initialize(from_revision, args)
    @name = args[:name]
    @path = args[:path]
    @last_modified_revision = args[:last_modified_revision]
    @last_modified_date = args[:last_modified_date]
    @changed = args[:changed]
    @user_id = args[:user_id]
    @mime_type = args[:mime_type]
    @from_revision = from_revision   
  end
  
  attr_accessor :name, :path, :last_modified_revision, :changed
  attr_accessor :from_revision, :user_id, :mime_type, :last_modified_date
    
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
  
  def add(path, file_data=nil, mime_type=nil)
    @jobs.push(:action => :add, :path => path, :file_data => file_data, :mime_type => mime_type)
  end
  
  def remove(path, expected_revision_number)
    @jobs.push(:action => :remove, :path => path, :expected_revision_number => expected_revision_number)
  end
  
  def replace(path, file_data, mime_type, expected_revision_number)
    @jobs.push(:action => :replace, :path => path, :file_data => file_data, :mime_type => mime_type, :expected_revision_number => expected_revision_number)
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
