require 'yaml'
require 'lib/repo/repository'


class InvalidConnectionFileFormat < Repository::ConnectionError; end

class MemoryRepository < Repository::AbstractRepository
  
  
  def initialize(connect_string)
    # Does the file provided by connect_string exist?
    if !File.exists?(connect_string)
      raise IOError, "Could not initialize MemoryRepository: '#{connect_string}' does not exist" 
    end
    # Is the file readable?
    if !File.readable?(connect_string)
      raise IOError, "Could not initialize MemoryRepository: '#{connect_string}' exists, but could not be read"
    end
    
    # Load the YAML file
    file_contents = YAML.load_file(connect_string)
    
    if !verify_file_contents?(file_contents)
      raise InvalidConnectionFileFormat, "YAML file #{connect_string} does not follow requirement rules for a MemoryRepository"
    end
    
    # Use private method populate to get the YAML data
    populate(file_contents)
    
    # Set up the job queue for commits
    @job_queue = []
  end

  # Given a repositoryFile of class File, try to find the File in question, and
  # return it as a string
  def download(repositoryFile)
    if !repositoryFile.is_a?(Repository::File)
      raise "Repository.download received a repositoryFile that was not of type Repository::File"
    end
    
    revision = repositoryFile.from_revision
    file_name = repositoryFile.name
    return @revisions[revision]['files'][file_name]['content']

  end
  
  def number_of_revisions
    return @revisions.length - 1
  end
  
  def get_latest_revision    
    return get_revision(number_of_revisions)
  end
  
  def get_revision(revision_number)
    
    if @revisions[revision_number].nil?
      raise Repository::RevisionDoesNotExist, "Revision #{revision_number} does not exist"
    end
    # This next line takes the string keys from the Yaml file, and converts them into
    # symbols.
    # So, if we get a hash like {"comment" => "Great!",...} it would become:
    # {:comment => "Great!"}, which is what Revision takes as parameters.
    revision_hash = @revisions[revision_number].inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    revision_hash[:number] = revision_number
    return Repository::Revision.new(revision_number, revision_hash)
  end
  
  # Assumes timestamp is a Time object (which is part of the Ruby standard library)
  def get_revision_by_timestamp(target_timestamp)
    revision_number = timestamp_to_revision(target_timestamp)
    return get_revision(revision_number)
  end
  
  def add_file(file_name, file_data)
    @job_queue.push({
      :action => :add, 
      :file_name => file_name, 
      :file_data => file_data
    })    
  end
  
  def remove_file(file_name)
    @job_queue.push({
      :action => :remove,
      :file_name => file_name
    })
  end
  
  def replace_file(file_name, file_data, expected_revision)
    @job_queue.push({
      :action => :replace,
      :file_name => file_name,
      :file_data => file_data,
      :expected_revision => expected_revision
    })
  end
  
  def commit
    conflicts = commit_conflicts
    if conflicts.size > 0
      @job_queue = []
      raise Repository::CommitConflicts.new(conflicts)
    end
    
    new_revision = @revisions.last.clone
    new_revision["files"].each do |file_name, file|
      file["changed"] = false
    end
    
    new_revision["comment"] = "This was a new commit!"
    new_revision["timestamp"] = Time.now.to_s
    new_revision["user_id"] = "c6conley" 

    @job_queue.each do |job|
      case job[:action]
      when :add
        new_revision = do_write_file(new_revision, job[:file_name], job[:file_data])
      when :remove
        new_revision = do_remove_file(new_revision, job[:file_name])
      when :replace
        new_revision = do_write_file(new_revision, job[:file_name], job[:file_data])
      else
        raise "Got an unknown job to perform: #{job.inspect}"
      end
    end
    
    @revisions.push(new_revision)
    @revision_timestamps.push(new_revision["timestamp"])
    @job_queue = []
  end
  
  def get_users
    return @users
  end
  
  def add_user(user_id)
    @users << user_id
  end
  
  def remove_user(user_id)
    @users.delete(user_id)
  end
  
 
  private 
  
  def commit_conflicts
    conflicts = []
    latest_revision = get_latest_revision
    @job_queue.each do |job|
      case job[:action]
      when :add
        if !latest_revision.all_files[job[:file_name]].nil?
          conflicts.push(Repository::FileExistsConflict.new(job))
        end
      when :remove
        if latest_revision.all_files[job[:file_name]].nil?
          conflicts.push(Repository::FileDoesNotExistConflict.new(job))
        end
      when :replace
        # Does the file exist?
        if latest_revision.all_files[job[:file_name]].nil?
          conflicts.push(Repository::FileDoesNotExistConflict.new(job))
        end
        # If the expected revision does not match this files revision,
        # then we have a revision conflict
        latest_version = latest_revision.all_files[job[:file_name]]
        if latest_version.last_modified_revision != job[:expected_revision]
          conflicts.push(Repository::RevisionOutOfSyncConflict.new(job))
        end
      else
        raise "Got an unknown job to inspect for conflicts: #{job.inspect}"
      end
    end
    
    return conflicts
  end
  
  def do_remove_file(new_revision, file_name)
    new_revision["files"].delete(file_name)
    return new_revision
  end
  
  def do_write_file(new_revision, file_name, file_data)
    file_hash = {
      "name" => file_name, 
      "path" => "/", 
      "last_modified_revision" => @revisions.length,
      "mime_type" => "text/java",
      "changed" => true,
      "content" => file_data
    }
    new_revision["files"][file_name] = file_hash
    return new_revision
  end
  
  
  def populate(file_contents)
    @revision_timestamps = file_contents["revision_timestamps"]
    @revisions = file_contents["revisions"]
    @users = file_contents["users"]
  end
  
  # Does this YAML file follow our schema?
  def verify_file_contents?(file_contents)
    return false if file_contents["revision_timestamps"].nil?
    return false if file_contents["revisions"].nil?
    return false if file_contents["users"].nil?

    return true
  end
  
  # Given a timestamp, find the revision number
  def timestamp_to_revision(target_timestamp)
    if !target_timestamp.is_a?(Time)
      raise "Expected a timestamp of type Time"
    end
    # What if there are no revisions in the repository?
    if @revisions.size == 0
      raise "There are no revisions in the repository"
    end

    # Case 1:  We're given a timestamp which is a key for a revision
    if !@revision_timestamps.index(target_timestamp.to_s).nil?
      return @revision_timestamps.index(target_timestamp.to_s)
    end
    
    # Case 2:  We're given a timestamp that is before the first revision
    created_on = Time.parse(@revisions.first['timestamp'])
    if target_timestamp < created_on
      raise Repository::RevisionDoesNotExist, "The timestamp provided is from before the repository was created"
    end

    # Case 3:  We're given a timestamp that is after the latest revision
    last_revision_on = Time.parse(@revisions.last['timestamp'])
    if target_timestamp > last_revision_on
      return @revisions.length - 1
    end
    
    found_revision_number = nil

    @revision_timestamps.each_with_index do |current_revision_timestamp_string, current_revision_number|
      current_revision_timestamp = Time.parse(current_revision_timestamp_string)
      if(current_revision_timestamp >= target_timestamp)
        return found_revision_number
      end
      found_revision_number = current_revision_number
    end
    # Catches case where we're getting the latest revision
    if !found_revision_number.nil?
      return found_revision_number
    end
    raise Repository::RevisionDoesNotExist, "Revision for time: #{target_timestamp} does not exist"
  end
end
