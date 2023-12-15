# Convenience class, so that we can work on Revisions rather
# than repositories
class GitRevision < Repository::AbstractRevision
  # Constructor; checks if +revision_hash+ is actually present in +repo+.
  def initialize(revision_hash, repo)
    super(revision_hash)
    @repo = repo.get_repos
    begin
      @commit = @repo.lookup(revision_hash)
    rescue Rugged::OdbError
      raise RevisionDoesNotExist
    end
    @revision_identifier_ui = @revision_identifier[0..6]
    @author = @commit.author[:name]
    @timestamp = @commit.time.in_time_zone
    @server_timestamp = @timestamp
  end

  def last_modified_date
    self.timestamp
  end

  # Gets a file or directory at +path+ from a +commit+ as a Rugged Hash.
  # The +path+ is relative to the repo root, the +commit+ can be omitted to default to this GitRevision.
  def get_entry_hash(path, commit = @commit)
    if path.start_with?(File::SEPARATOR) # transform from absolute to relative
      path = path[1..-1]
    end
    if path == '' # root Tree
      entry_hash = { name: path, oid: commit.tree_id, type: :tree, filemode: 0 } # mimic Tree#path output
    else # Tree or Blob
      begin
        entry_hash = commit.tree.path(path)
      rescue Rugged::TreeError # path not valid
        entry_hash = nil
      end
    end
    entry_hash
  end

  # Gets a file or directory at +path+ from a +commit+ as a Rugged::Blob or Rugged::Tree respectively.
  # The +path+ is relative to the repo root, the +commit+ can be omitted to default to this GitRevision.
  def get_entry(path, commit = @commit)
    entry_hash = get_entry_hash(path, commit)
    if entry_hash.nil?
      entry = nil
    else
      entry = @repo.lookup(entry_hash[:oid])
    end
    entry
  end

  def path_exists?(path)
    !get_entry_hash(path).nil?
  end

  # Checks if a file or directory at +path+ (relative to the repo root) was changed by +commit+.
  # The +commit+ can be omitted to default to this revision.
  # (optimizations based on Rugged bug #343)
  def entry_changed?(path, commit = @commit)
    entry = get_entry_hash(path, commit)
    # if at a root commit, consider it changed if we have this file;
    # i.e. if we added it in the initial commit
    parents = commit.parents
    if parents.empty?
      return !entry.nil?
    end
    # check each parent commit (a merge has 2+ parents)
    parents.each do |parent|
      parent_entry = get_entry_hash(path, parent)
      # neither exists, no change
      if !entry && !parent_entry
        next
        # only in one of them, change
      elsif !entry || !parent_entry
        return true
        # otherwise it's changed if their ids aren't the same
      elsif entry[:oid] != parent_entry[:oid]  # rubocop:disable Lint/DuplicateBranch
        return true
      end
    end
    false
  end

  def changes_at_path?(path)
    entry_changed?(path)
  end

  # Get all entries at directory +path+ of a specified +type+ (:blob, :tree, or nil for both), as
  # Repository::RevisionFile and Repository::RevisionDirectory.
  # If +recursive+ is true, get all entries in subdirectories too.
  def entries_at_path(path, type: nil, recursive: false)
    entries = {}
    path_tree = get_entry(path)
    if path_tree.nil?
      return entries
    end
    path_tree.each do |entry_hash|
      entry_type = entry_hash[:type]
      next unless type.nil? || type == entry_type
      entry_name = entry_hash[:name]
      # wrap in a RevisionFile or RevisionDirectory
      if entry_type == :blob
        mime_type = MiniMime.lookup_by_filename(entry_name)
        if mime_type.nil?
          mime_type = 'text'
        else
          mime_type = mime_type.content_type
        end
        entries[entry_name] = Repository::RevisionFile.new(@revision_identifier, name: entry_name, path: path,
                                                                                 mime_type: mime_type)
      elsif entry_type == :tree
        entries[entry_name] = Repository::RevisionDirectory.new(@revision_identifier, name: entry_name, path: path)
        if recursive
          entries.merge!(entries_at_path(File.join(path, entry_name), type: type, recursive: recursive)
                           .transform_keys! { |sub_name| File.join(entry_name, sub_name) })
        end
      end
    end
    entries
  end

  # Walk the git history once and collect the last commits and pushes that modified the +entries+ found at +path+.
  def add_entries_info(entries, path)
    # use the git reflog to get a list of pushes
    reflog = @repo.ref('refs/heads/master').log.reverse
    # walk through all the commits until this revision's +@commit+ is found
    # (this is needed to advance the reflog to the right point, since +@commit+ may be between two pushes)
    walker_entries = entries.dup
    last_commit = @repo.last_commit
    reflog_entries = {}
    reflog_entries[last_commit.oid] = { index: -1 }
    found = false
    walker = Rugged::Walker.new(@repo)
    walker.sorting(Rugged::SORT_TOPO)
    walker.push(last_commit.oid)
    walker.each do |commit|
      current_reflog_entry = GitRepository.try_advance_reflog!(reflog, reflog_entries, commit)
      found = true if @commit.oid == commit.oid
      next unless found
      # check entries that were modified
      mod_keys = walker_entries.keys.select { |entry_name| entry_changed?(File.join(path, entry_name), commit) }
      mod_entries = walker_entries.extract!(*mod_keys)
      mod_entries.each_value do |mod_entry|
        mod_entry.last_modified_revision = commit.oid
        mod_entry.last_modified_date = commit.time.in_time_zone
        mod_entry.submitted_date = current_reflog_entry[:time]
        mod_entry.changed = commit.oid == @revision_identifier
        mod_entry.user_id = commit.author[:name]
      end
      break if walker_entries.empty?
    end
  end

  def files_at_path(path, with_attrs: true)
    entries = entries_at_path(path, type: :blob)
    if with_attrs && !entries.empty?
      add_entries_info(entries, path)
    end
    entries
  end

  def directories_at_path(path, with_attrs: true)
    entries = entries_at_path(path, type: :tree)
    if with_attrs && !entries.empty?
      add_entries_info(entries, path)
    end
    entries
  end

  def tree_at_path(path, with_attrs: true)
    entries = entries_at_path(path, recursive: true)
    if with_attrs && !entries.empty?
      add_entries_info(entries, path)
    end
    entries
  end
end
