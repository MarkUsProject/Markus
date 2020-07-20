class StarterCodeEntry < ApplicationRecord
  belongs_to :starter_code_group
  validate :entry_exists

  def full_path
    starter_code_group.path + path
  end

  def files_and_dirs
    Dir.glob("#{full_path}/**/*", File::FNM_DOTMATCH).map do |f|
      unless %w[.. .].include?(File.basename(f))
        Pathname.new(f)
      end
    end.compact + [full_path]
  end

  def add_files_to_transaction(txn, expected_revision_id, current_tree: nil)
    relative_root = Pathname.new(starter_code_group.path)
    repo_root_dir = starter_code_group.assignment.repository_folder
    should_rename = starter_code_group.should_rename
    rename = starter_code_group.entry_rename
    files_and_dirs.each do |fd|
      rel_path = fd.relative_path_from(relative_root)
      rel_path = File.join(rename, *rel_path.each_filename.to_a[1..-1]) if should_rename
      path_exists = current_tree&.include?(rel_path.to_s)
      repo_path = File.join(repo_root_dir, rel_path)
      if fd.directory?
        next if path_exists
        txn.add_path(repo_path)
      elsif path_exists
        txn.replace(repo_path,
                    File.open(fd, 'rb', &:read),
                    Rack::Mime.mime_type(File.extname(fd)),
                    expected_revision_id)
      else
        txn.add(repo_path, File.open(fd, 'rb', &:read), Rack::Mime.mime_type(File.extname(fd)))
      end
    end
  end

  private

  def entry_exists
    errors.add(:base, 'entry does not exist') unless File.exist?(full_path)
  end
end
