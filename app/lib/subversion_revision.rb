# Convenience class, so that we can work on Revisions rather
# than repositories
class SubversionRevision < Repository::AbstractRevision
  # Constructor; Check if revision is actually present in
  # repository
  def initialize(revision_number, repo)
    revision_number = revision_number.to_i # can be passed as string or int
    super(revision_number)
    @repo = repo
    @revision_identifier_ui = revision_number.to_s
    begin
      @timestamp = @repo.__get_property(Svn::Core::PROP_REVISION_DATE, revision_number)
      if @timestamp.instance_of?(String)
        @timestamp = Time.zone.parse(@timestamp).localtime
      elsif @timestamp.instance_of?(Time)
        @timestamp = @timestamp.localtime
      end
    rescue Svn::Error::FsNoSuchRevision
      raise RevisionDoesNotExist
    end
    @server_timestamp = @timestamp
  end

  # Return all of the files in this repository at the root directory
  def files_at_path(path, with_attrs: true)
    files_at_path_helper(path)
  end

  def path_exists?(path)
    @repo.__path_exists?(path, @revision_identifier)
  end

  # Return all directories at 'path' (including subfolders?!)
  def directories_at_path(path = '/', with_attrs: true)
    result = Hash.new(nil)
    raw_contents = @repo.__get_files(path, @revision_identifier)
    raw_contents.each do |file_name, type|
      if type == :directory
        last_modified_revision = @repo.__get_history(File.join(path, file_name)).last
        last_modified_date = @repo.__get_node_last_modified_date(File.join(path, file_name), @revision_identifier)
        new_directory = Repository::RevisionDirectory.new(@revision_identifier, {
          name: file_name,
          path: path,
          last_modified_revision: last_modified_revision,
          last_modified_date: last_modified_date,
          submitted_date: last_modified_date,
          changed: (last_modified_revision == @revision_identifier),
          user_id: @repo.__get_property(Svn::Core::PROP_REVISION_AUTHOR, @revision_identifier)
        })
        result[file_name] = new_directory
      end
    end
    result
  end

  def changes_at_path?(path)
    !changed_filenames_at_path(path).empty?
    # TODO: This does not take into account the creation of the empty assignment directory
  end

  # Return the names of changed files at this revision at 'path'
  def changed_filenames_at_path(path)
    unless path.start_with?(File::SEPARATOR) # transform from relative to absolute
      path = "#{File::SEPARATOR}#{path}"
    end
    paths = @repo.__get_file_paths(@revision_identifier)
    paths.select { |p| p == path || p.start_with?("#{path}#{File::SEPARATOR}") }
    # p.start_with?(path) only would be wrong, there can be two assignments named like 'aX' and 'aXsuffix'
  end

  def tree_at_path(path, with_attrs: true)
    result = files_at_path(path, with_attrs: with_attrs)
    dirs = directories_at_path(path, with_attrs: with_attrs)
    result.merge!(dirs)
    dirs.each do |dir_path, _|
      result.merge!(tree_at_path(File.join(path, dir_path), with_attrs: with_attrs)
                      .transform_keys! { |sub_path| File.join(dir_path, sub_path) })
    end
    result
  end

  private

  def files_at_path_helper(path = '/', only_changed: false)
    if path.nil?
      path = '/'
    end
    result = Hash.new(nil)
    raw_contents = @repo.__get_files(path, @revision_identifier)
    raw_contents.each do |file_name, type|
      if type == :file
        last_modified_date = @repo.__get_node_last_modified_date(File.join(path, file_name), @revision_identifier)
        last_modified_revision = @repo.__get_history(File.join(path, file_name), nil, @revision_identifier).last

        if !only_changed || (last_modified_revision == @revision_identifier)
          new_file = Repository::RevisionFile.new(@revision_identifier, {
            name: file_name,
            path: path,
            last_modified_revision: last_modified_revision,
            changed: (last_modified_revision == @revision_identifier),
            user_id: @repo.__get_property(Svn::Core::PROP_REVISION_AUTHOR, last_modified_revision),
            mime_type: @repo.__get_file_property(Svn::Core::PROP_MIME_TYPE, File.join(path, file_name),
                                                 last_modified_revision),
            last_modified_date: last_modified_date,
            submitted_date: last_modified_date
          })
          result[file_name] = new_file
        end
      end
    end
    result
  end
end
