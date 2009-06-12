require 'yaml'
require 'lib/repo/repository'

class InvalidConnectionFileFormat < Repository::ConnectionError; end

class MemoryRepository < Repository::AbstractRepository
  
  # Initializes Object, and verifies connection to the repository back end.
  # This should throw a ConnectionError if we're unable to connect.
  def initialize(connect_string)
   #  raise NotImplementedError, "Repository.initialize(connect_string): Not yet implemented"
  end
  
  def self.repository_path_valid?(path)
    return !File.exists?(path)
  end
  
  def self.open(connect_string)
    return MemoryRepository.new(connect_string)
    # raise NotImplementedError, "Repository::open Not yet implemented"
  end
  
  def self.create(connect_string)
    return true
  end
  
  # Given either an array of, or a single object of class RevisionFile, 
  # return a stream of data for the user to download as the file(s).
  def download(files)
    raise NotImplementedError,  "Repository.download: Not yet implemented"
  end 

  # Returns the most recent revision of the repository. If a path is specified, 
  # the youngest revision is returned for that path; if a revision is also specified,
  # the function will return the youngest revision that is equal to or older than the one passed.
  # 
  # This will only work for paths that have not been deleted from the repository.
  def latest_revision_number(path=nil, revision_number=nil)
    raise NotImplementedError, "Repository.latest_revision_number: Not yet implemented"  
  end
  
  def get_transaction(user_id, comment)
    raise NotImplementedError,  "Repository.get_transaction: Not yet implemented"
  end  
  
  def commit(transaction)
  
  end
  
  def number_of_revisions
    raise NotImplementedError, "Repository.number_of_revisions: Not yet implemented"
  end
  
  def get_latest_revision
    raise NotImplementedError, "Repository.get_latest_revision: Not yet implemented"
  end
    
  # Return a RepositoryRevision for a given revision_number
  def get_revision(revision_number)
    raise NotImplementedError,  "Repository.get_revision: Not yet implemented"
  end
  
  # Return a RepositoryRevision for a given timestamp
  def get_revision_by_timestamp(timestamp)
    raise NotImplementedError,  "Repository.get_revision_by_timestamp: Not yet implemented"
  end

  # Return a revision number for a given timestamp
  def get_revision_number_by_timestamp(timestamp)
    raise NotImplementedError,  "Repository.get_revision_number_by_timestamp: Not yet implemented"  
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

class MemoryRevision < Repository::AbstractRevision
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
