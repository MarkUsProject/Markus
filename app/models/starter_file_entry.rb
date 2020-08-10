# Class describing a top level file or directory in a starter files group
class StarterFileEntry < ApplicationRecord
  belongs_to :starter_file_group
  validate :entry_exists

  has_many :grouping_starter_file_entries, dependent: :destroy
  has_many :groupings, through: :grouping_starter_file_entries

  def full_path
    starter_file_group.path + path
  end

  def files_and_dirs
    Dir.glob("#{full_path}/**/*", File::FNM_DOTMATCH).map do |f|
      unless %w[.. .].include?(File.basename(f))
        Pathname.new(f)
      end
    end.compact + [full_path]
  end

  def add_files_to_transaction(txn)
    relative_root = Pathname.new(starter_file_group.path)
    repo_root_dir = starter_file_group.assignment.repository_folder
    should_rename = starter_file_group.should_rename
    rename = starter_file_group.entry_rename
    files_and_dirs.each do |fd|
      rel_path = fd.relative_path_from(relative_root)
      rel_path = File.join(rename, *rel_path.each_filename.to_a[1..-1]) if should_rename
      repo_path = File.join(repo_root_dir, rel_path)
      if fd.directory?
        txn.add_path(repo_path)
      else
        txn.add(repo_path, File.open(fd, 'rb', &:read), Rack::Mime.mime_type(File.extname(fd)))
      end
    end
  end

  def add_files_to_zip_file(zip_file)
    relative_root = Pathname.new(starter_file_group.path)
    should_rename = starter_file_group.should_rename
    rename = starter_file_group.entry_rename
    files_and_dirs.sort.each do |abs_path|
      zip_entry_path = abs_path.relative_path_from(relative_root)
      zip_entry_path = File.join(rename, *zip_entry_path.each_filename.to_a[1..-1]) if should_rename
      next if zip_file.find_entry(zip_entry_path)

      if abs_path.directory?
        zip_file.mkdir(zip_entry_path)
      else
        zip_file.get_output_stream(zip_entry_path) { |f| f.puts abs_path.read }
      end
    end
  end

  private

  def entry_exists
    errors.add(:base, 'entry does not exist') unless File.exist?(full_path)
  end
end
