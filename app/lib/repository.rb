module Repository
  # Configuration for the repository library,
  # which is set via Repository.get_class
  # TODO: Get rid of Repository.conf
  # @CONF = {}
  #  def Repository.conf
  #   return @CONF
  #  end

  # Permission constants for repositories
  class Permission
    unless defined? WRITE  # avoid constant already defined warnings
      WRITE = 2
    end
    unless defined? READ
      READ = 4
    end
    unless defined? READ_WRITE
      READ_WRITE = READ + WRITE
    end
    unless defined? ANY
      ANY = READ # any permission means at least read permission
    end
  end

  ROOT_DIR = (Settings.file_storage.repos || File.join(Settings.file_storage.default_root_path, 'repos')).freeze
  PERMISSION_FILE = File.join(ROOT_DIR, '.access').freeze

  # Exceptions for repositories
  class ConnectionError < StandardError; end

  class Conflict < StandardError
    attr_reader :path

    def initialize(path)
      super()
      @path = path
    end

    def to_s
      "There was an unspecified conflict with file #{@path}"
    end
  end

  class FileExistsConflict < Conflict
    def to_s
      "#{@path} could not be added - it already exists in the folder. \
        If you'd like to overwrite, try replacing the file instead."
    end
  end

  class FileDoesNotExistConflict < Conflict
    def to_s
      "#{@path} could not be changed - it was deleted since you last saw it"
    end
  end

  # Exception for folders
  class FolderExistsConflict < Conflict
    def to_s
      "#{@path} could not be added - it already exists"
    end
  end

  class FolderDoesNotExistConflict < Conflict
    def to_s
      "#{@path} could not be removed - it is not exist"
    end
  end

  # Exception for folders
  class FolderIsNotEmptyConflict < Conflict
    def to_s
      "#{@path} could not be removed - it is not empty"
    end
  end

  class FileOutOfSyncConflict < Conflict
    def to_s
      "#{@path} has been updated since you last saw it, and could not be changed"
    end
  end

  class ExportRepositoryAlreadyExists < StandardError; end

  class RepositoryCollision < StandardError; end

  class AbstractRepository
    # Initializes Object, and verifies connection to the repository back end.
    # This should throw a ConnectionError if we're unable to connect.
    def initialize(connect_string)
      raise NotImplementedError
    end

    # Static method: Should report if a repository exists at given location
    def self.repository_exists?(path)
      raise NotImplementedError
    end

    # Static method: Opens a repository at given location; returns an
    # AbstractRepository instance
    def self.open(connect_string)
      raise NotImplementedError
    end

    # Static method: Creates a new repository at given location; returns
    # an AbstractRepository instance, with the repository opened.
    def self.create(connect_string, course)
      raise NotImplementedError
    end

    # Static method: Yields an existing Repository and closes it afterwards
    def self.access(connect_string)
      raise NotImplementedError
    end

    # Static method: Deletes an existing repository
    def self.delete(connect_string)
      raise NotImplementedError
    end

    # Closes the repository
    def close
      raise NotImplementedError
    end

    # Tests if the repository is closed
    def closed?
      raise NotImplementedError
    end

    # Static method: returns the shell command to check out a repository or one of its folders
    def self.get_checkout_command(external_repo_url, revision_identifier, group_name, repo_folder = nil)
      raise NotImplementedError
    end

    # Given either an array of, or a single object of class RevisionFile,
    # return a stream of data for the user to download as the file(s).
    def stringify_files(files)
      raise NotImplementedError
    end
    alias download_as_string stringify_files

    # Returns a transaction for the provided user and uses comment as the commit message
    def get_transaction(user_id, comment)
      raise NotImplementedError
    end

    # Commits a transaction associated with a repository
    def commit(transaction)
      raise NotImplementedError
    end

    # Returns the latest Repository::AbstractRevision
    def get_latest_revision
      raise NotImplementedError
    end

    # Returns all revisions
    def get_all_revisions
      raise NotImplementedError
    end

    # Return a Repository::AbstractRevision for a given revision_identifier
    # if it exists
    def get_revision(revision_identifier)
      raise NotImplementedError
    end

    # Return a RepositoryRevision for a given timestamp
    def get_revision_by_timestamp(at_or_earlier_than, path = nil, later_than = nil)
      raise NotImplementedError
    end

    # Converts a pathname to an absolute pathname
    def expand_path(file_name, dir_string)
      raise NotImplementedError
    end

    # This function allows a cached value of non_bare_repo to be cleared.
    # Currently only implemented in GitRepository.
    def reload_non_bare_repo
      raise NotImplementedError
    end

    # Updates permissions file unless it is being called from within a
    # block passed to self.update_permissions_after or if it does not
    # read the most up to date data (using self.get_all_permissions)
    def self.update_permissions
      return unless Settings.repository.is_repository_admin
      Thread.current[:requested?] = true
      # abort if this is being called in a block passed to
      # self.update_permissions_after
      return if Thread.current[:permissions_lock]&.owned?
      UpdateRepoPermissionsJob.perform_later(self.name)
      nil
    end

    # Executes a block of code and then updates the permissions file.
    # Also prevents any calls to self.update_permissions or
    # self.update_permissions_after within that block.
    #
    # If only_on_request is true then self.update_permissions will be
    # called after the block only if it would have been called in the
    # yielded block but was prevented
    #
    # This allows us to ensure that the permissions file will only be
    # updated a single time once all relevant changes have been made.
    def self.update_permissions_after(only_on_request: false, &block)
      if Thread.current[:permissions_lock].nil?
        Thread.current[:permissions_lock] = Mutex.new
        Thread.current[:requested?] = false
      end
      if Thread.current[:permissions_lock].owned?
        # if owned by the current thread, yield the block without
        # trying to lock again (which would raise a ThreadError)
        yield
      else
        Thread.current[:permissions_lock].synchronize(&block)
      end
      if !only_on_request || Thread.current[:requested?]
        self.update_permissions
      end
      nil
    end

    # Return a nested hash of the form { assignment_id => { section_id => visibility } } where visibility
    # is a boolean indicating whether the given assignment is visible to the given section.
    def self.visibility_hash
      current_time = Time.current
      records = Assignment.left_outer_joins(:assessment_section_properties)
                          .pluck_to_hash('assessments.id',
                                         'section_id',
                                         'assessments.is_hidden',
                                         'assessments.visible_on',
                                         'assessments.visible_until',
                                         'assessment_section_properties.is_hidden',
                                         'assessment_section_properties.visible_on',
                                         'assessment_section_properties.visible_until')

      visibilities = records.uniq { |r| r['assessments.id'] }
                            .map do |r|
                              # Check if datetime-based visibility is set
                              visible_on = r['assessments.visible_on']
                              visible_until = r['assessments.visible_until']
                              default_visible = if visible_on || visible_until
                                                  (visible_on.nil? || visible_on <= current_time) &&
                                                    (visible_until.nil? || visible_until >= current_time)
                                                else
                                                  !r['assessments.is_hidden']
                                                end
                              [r['assessments.id'], Hash.new { default_visible }]
                            end
                            .to_h

      records.each do |r|
        section_visible_on = r['assessment_section_properties.visible_on']
        section_visible_until = r['assessment_section_properties.visible_until']
        section_is_hidden = r['assessment_section_properties.is_hidden']

        unless section_is_hidden.nil? && section_visible_on.nil? && section_visible_until.nil?
          # Section-specific settings exist
          section_visible = if section_visible_on || section_visible_until
                              (section_visible_on.nil? || section_visible_on <= current_time) &&
                                (section_visible_until.nil? || section_visible_until >= current_time)
                            else
                              !section_is_hidden
                            end
          visibilities[r['assessments.id']][r['section_id']] = section_visible
        end
      end
      visibilities
    end

    # Builds a hash of all repositories and users allowed to access them (assumes all permissions are rw)
    def self.get_all_permissions
      visibility = self.visibility_hash
      permissions = Hash.new { |h, k| h[k] = [] }
      admins = AdminUser.pluck(:user_name)
      permissions['*/*'] = admins unless admins.empty?
      instructors = Instructor.joins(:course, :user)
                              .where('roles.hidden': false)
                              .pluck('courses.name', 'users.user_name')
                              .group_by(&:first)
                              .transform_values { |val| val.map(&:second) }
      instructors.each do |course_name, instructor_names|
        permissions[File.join(course_name, '*')] = instructor_names
      end

      # Bulk query for student permissions (optimized to avoid N+1)
      student_permissions = get_student_permissions_bulk(visibility)
      student_permissions.each do |repo_path, user_names|
        permissions[repo_path] = user_names
      end

      # NOTE: this will allow graders to access the files in the entire repository
      # even if they are the grader for only a single assignment
      graders_info = TaMembership.joins(role: [:user, :course],
                                        grouping: [:group, { assignment: :assignment_properties }])
                                 .where('assignment_properties.anonymize_groups': false, 'roles.hidden': false)
                                 .pluck(:repo_name, :user_name, 'courses.name')
      graders_info.each do |repo_name, user_name, course_name|
        repo_path = File.join(course_name, repo_name) # NOTE: duplicates functionality of Group.repository_relative_path
        permissions[repo_path] << user_name
      end
      permissions
    end

    # Bulk query to get student permissions without N+1 queries.
    # Returns a hash of { repo_path => [user_names] }
    def self.get_student_permissions_bulk(visibility)
      current_time = Time.current
      accepted_statuses = [StudentMembership::STATUSES[:accepted], StudentMembership::STATUSES[:inviter]]
      rejected_status = StudentMembership::STATUSES[:rejected]
      inviter_status = StudentMembership::STATUSES[:inviter]

      # Step 1: Get membership counts per grouping for is_valid? check
      # (grouping is valid if instructor_approved OR non_rejected_count >= group_min)
      membership_counts = StudentMembership
                          .where.not(membership_status: rejected_status)
                          .group(:grouping_id)
                          .count

      # Step 2: Get inviter section_id for each grouping (for visibility check)
      inviter_sections = StudentMembership
                         .joins(:role)
                         .where(membership_status: inviter_status)
                         .pluck(:grouping_id, 'roles.section_id')
                         .to_h

      # Step 3: Bulk query for all relevant data
      # Timed assignment filter: non-timed OR started OR (not started AND past due date)
      timed_filter = <<~SQL.squish
        (assignment_properties.is_timed = false
         OR groupings.start_time IS NOT NULL
         OR (groupings.start_time IS NULL AND assessments.due_date <= :current_time))
      SQL

      raw_data = Assignment
                 .joins(:assignment_properties, :course)
                 .joins(groupings: [:group, { accepted_student_memberships: { role: :user } }])
                 .where(assignment_properties: { vcs_submit: true })
                 .where('courses.is_hidden': false)
                 .where('roles.hidden': false)
                 .where(memberships: { membership_status: accepted_statuses })
                 .where(timed_filter, current_time: current_time)
                 .order(due_date: :desc)
                 .pluck(
                   'assessments.id',
                   'groupings.id',
                   'groupings.instructor_approved',
                   'assignment_properties.group_min',
                   'courses.name',
                   'groups.repo_name',
                   'users.user_name'
                 )

      # Step 4: Process results in Ruby (now O(n) iteration, not O(n) DB queries)
      # Group by assignment first to preserve due_date DESC ordering (last-deadline approach)
      permissions = Hash.new { |h, k| h[k] = [] }
      processed_repos = Set.new

      # Group by assignment_id first (preserves due_date ordering), then by grouping_id
      by_assignment = raw_data.group_by { |row| row[0] } # group by assignment_id

      by_assignment.each do |assignment_id, assignment_rows|
        by_grouping = assignment_rows.group_by { |row| row[1] } # group by grouping_id

        by_grouping.each do |grouping_id, rows|
          first_row = rows.first
          instructor_approved = first_row[2]
          group_min = first_row[3]
          course_name = first_row[4]
          repo_name = first_row[5]
          repo_path = File.join(course_name, repo_name)

          # Last-deadline approach: skip if repo already processed by earlier (later due_date) assignment
          next if processed_repos.include?(repo_path)

          # Check if grouping is valid (same logic as Grouping#is_valid?)
          non_rejected_count = membership_counts[grouping_id] || 0
          is_valid = instructor_approved || non_rejected_count >= group_min
          next unless is_valid

          # Check visibility based on inviter's section
          inviter_section_id = inviter_sections[grouping_id]
          next unless visibility[assignment_id][inviter_section_id]

          processed_repos << repo_path
          permissions[repo_path] = rows.map { |row| row[6] }.uniq
        end
      end

      permissions
    end

    # '*' which is reserved to indicate all repos when setting permissions
    # TODO: add to this if needed
    def self.reserved_locations
      ['*']
    end

    # Generate and write the the authorization file for all repos.
    def self.update_permissions_file(_permissions)
      raise NotImplementedError
    end

    # Returns a set of file names that are used internally by the repository and are not part of any student submission.
    def self.internal_file_names
      []
    end

    # Exclusive blocking lock using a redis list to ensure that all threads and all processes respect
    # the lock.  If the resource defined by +resource_id+ is locked, the calling thread will wait +timeout+
    # milliseconds, while trying to acquire the lock every +interval+ milliseconds. If the calling thread
    # is able to acquire the lock it will yield, otherwise the passed block will not be executed
    # and a Timeout::Error will be raised.
    #
    # Access to the resource will be given in request order. So if threads a, b, and c all request access to the
    # same resource (in that order), access is guaranteed to be given to a then b then c (in that order).
    #
    # The +namespace+ argument can be given to ensure that two resources with the same resource_id can be treated
    # as separate resources as long as the +namespace+ value is distinct. By default the +namespace+ is the relative
    # root of the current MarkUs instance.
    def self.redis_exclusive_lock(resource_id, namespace: Rails.root.to_s, timeout: 5000, interval: 100)
      redis = Redis::Namespace.new(namespace, redis: Resque.redis)
      return yield if redis.lrange(resource_id, -1, -1).first&.to_i == Thread.current.object_id

      # clear any threads that are no longer alive from the queue
      redis.lrange(resource_id, 0, -1).each do |thread_id|
        begin
          thread_obj = ObjectSpace._id2ref(thread_id.to_i)
        rescue TypeError, RangeError
          redis.lrem(resource_id, 0, thread_id)
          next
        end
        unless thread_obj.is_a?(Thread) && thread_obj.alive?
          redis.lrem(resource_id, 0, thread_id)
        end
      end

      redis.lpush(resource_id, Thread.current.object_id) # assume thread ids are unique accross processes as well
      elapsed_time = 0
      begin
        loop do
          return yield if redis.lrange(resource_id, -1, -1).first&.to_i == Thread.current.object_id
          raise Timeout::Error, I18n.t('repo.timeout') if elapsed_time >= timeout

          sleep(interval / 1000.0) # interval is in milliseconds but sleep arg is in seconds
          elapsed_time += interval
        end
      ensure
        redis.lrem(resource_id, -1, Thread.current.object_id)
      end
    end

    # Given a subdirectory path, and an already created zip_file, fill the subdirectory
    # within the zip_file with all of its files.
    #
    # If a block is passed to this function, The block will receive a Repository::RevisionFile
    # object as a parameter.
    # The result of the block will be written to the zip file instead of the file content.
    #
    # This can be used to modify the file content before it is written to the zip file.
    def send_tree_to_zip(subdirectory_path, zip_file, revision, zip_subdir: nil, &block)
      revision.tree_at_path(subdirectory_path, with_attrs: false).each do |path, obj|
        if obj.is_a? Repository::RevisionFile
          file_contents = block ? yield(obj) : download_as_string(obj)
          full_path = zip_subdir ? File.join(zip_subdir, path) : path
          zip_file.get_output_stream(full_path) do |f|
            f.print file_contents
          end
        end
      end
    end
  end

  # Exceptions for Revisions
  class RevisionDoesNotExist < StandardError; end
  class RevisionOutOfSyncConflict < Conflict; end

  class AbstractRevision
    attr_reader :revision_identifier, :revision_identifier_ui, :timestamp, :user_id, :comment
    attr_accessor :server_timestamp

    def initialize(revision_identifier)
      raise RevisionDoesNotExist if revision_identifier.nil?

      @revision_identifier = revision_identifier
      @revision_identifier_ui = @revision_identifier
    end

    # Checks if +path+ is a file or directory in this revision of the repository.
    def path_exists?(path)
      raise NotImplementedError
    end

    # Checks if there are changes under +path+ (subdirectories included) due to this revision.
    def changes_at_path?(path)
      raise NotImplementedError
    end

    # Returns all the files under +path+ (but not in subdirectories) in this revision of the repository.
    def files_at_path(_path, with_attrs: true)
      raise NotImplementedError
    end

    # Returns all the directories under +path+ (but not in subdirectories) in this revision of the repository.
    def directories_at_path(_path, with_attrs: true)
      raise NotImplementedError
    end

    # Walks all files and subdirectories starting at +path+ and
    # returns an array of tuples containing [path, revision_object]
    # for every file and directory discovered in this way
    def tree_at_path(_path, with_attrs: true)
      raise NotImplementedError
    end
  end

  # Exceptions for Files
  class FileOutOfDate < StandardError; end
  class FileDoesNotExist < StandardError; end
  # Exceptions for Folders
  class FolderDoesNotExist < StandardError; end
  # Exceptions for repo user management
  class UserNotFound < StandardError; end
  class UserAlreadyExistent < StandardError; end
  # raised when trying to modify permissions and repo is not in authoritative mode
  class NotAuthorityError < StandardError; end
  # raised when configuration is wrong
  class ConfigurationError < StandardError; end

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
      @submitted_date = args[:submitted_date]
      @changed = args[:changed]
      @user_id = args[:user_id]
      @mime_type = args[:mime_type]
      @from_revision = from_revision
    end

    attr_accessor :name, :path, :last_modified_revision, :changed, :submitted_date, :from_revision, :user_id,
                  :mime_type, :last_modified_date
  end

  class RevisionDirectory
    def initialize(from_revision, args)
      @name = args[:name]
      @path = args[:path]
      @last_modified_revision = args[:last_modified_revision]
      @last_modified_date = args[:last_modified_date]
      @submitted_date = args[:submitted_date]
      @changed = args[:changed]
      @user_id = args[:user_id]
      @from_revision = from_revision
    end

    attr_accessor :name, :path, :last_modified_revision, :changed, :submitted_date, :from_revision, :user_id,
                  :last_modified_date
  end

  class Transaction
    attr_reader :user_id, :comment, :jobs, :conflicts

    def initialize(user_id, comment)
      @user_id = user_id
      @comment = comment
      @jobs = []
      @conflicts = []
    end

    def add_path(path)
      @jobs.push(action: :add_path, path: path)
    end

    def add(path, file_data = nil, mime_type = nil)
      @jobs.push(action: :add, path: path, file_data: file_data, mime_type: mime_type)
    end

    def remove(path, expected_revision_identifier, keep_folder: true)
      @jobs.push(action: :remove, path: path, expected_revision_identifier: expected_revision_identifier,
                 keep_folder: keep_folder)
    end

    def remove_directory(path, expected_revision_identifier, keep_parent_dir: false)
      @jobs.push(action: :remove_directory, path: path, expected_revision_identifier: expected_revision_identifier,
                 keep_parent_dir: keep_parent_dir)
    end

    def replace(path, file_data, mime_type, expected_revision_identifier)
      @jobs.push(action: :replace, path: path, file_data: file_data, mime_type: mime_type,
                 expected_revision_identifier: expected_revision_identifier)
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

  # Gets the configured repository implementation
  def self.get_class
    repo_type = Settings.repository.type
    case repo_type
    when 'git'
      GitRepository
    when 'mem'
      MemoryRepository
    else
      raise "Repository implementation not found: #{repo_type}"
    end
  end
end
