# Class describing a top level file or directory in a starter files group
class StarterFileEntry < ApplicationRecord
  belongs_to :starter_file_group
  validate :entry_exists, if: :starter_file_group

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
