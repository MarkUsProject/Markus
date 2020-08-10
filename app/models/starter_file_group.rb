# Class describing a group of starter files
class StarterFileGroup < ApplicationRecord
  include SubmissionsHelper
  belongs_to :assignment, foreign_key: :assessment_id
  has_many :section_starter_file_groups, dependent: :destroy
  has_many :sections, through: :section_starter_file_groups
  has_many :starter_file_entries, dependent: :destroy

  after_destroy_commit :delete_files
  after_create_commit :create_dir
  before_validation :sanitize_rename_entry
  before_destroy :update_default
  before_destroy :warn_affected_groupings, prepend: true
  after_save :update_timestamp

  validates_exclusion_of :entry_rename, in: %w[.. .]
  validates_presence_of :entry_rename, if: -> { self.use_rename }

  def path
    Pathname.new(assignment.starter_file_path) + id.to_s
  end

  def files_and_dirs
    starter_file_entries.map(&:files_and_dirs).flatten.map { |f| f.relative_path_from(path).to_s }
  end

  def zip_starter_file_files(user)
    zip_name = "#{assignment.short_identifier}-#{name}-starter-files-#{user.user_name}"
    zip_path = File.join('tmp', zip_name + '.zip')
    FileUtils.rm_rf zip_path
    Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
      self.files_and_dirs.map do |file|
        zip_entry_path = File.join file
        abs_path = path.join(file)
        if abs_path.directory?
          zip_file.mkdir(zip_entry_path)
        else
          zip_file.get_output_stream(zip_entry_path) { |f| f.puts abs_path.read }
        end
      end
    end
    zip_path
  end

  def update_entries
    return [] unless Dir.exist? path

    fs_entry_paths = Dir.glob("#{path}/*", File::FNM_DOTMATCH).map do |f|
      unless %w[.. .].include?(File.basename(f))
        Pathname.new(f).relative_path_from(path).to_s
      end
    end.compact
    entry_paths = starter_file_entries.pluck(:path)
    to_delete = entry_paths - fs_entry_paths
    to_add = fs_entry_paths - entry_paths
    starter_file_entries.where(path: to_delete).destroy_all unless to_delete.empty?
    StarterFileEntry.upsert_all(to_add.map { |p| { starter_file_group_id: self.id, path: p } }) unless to_add.empty?
  end

  def should_rename
    use_rename && !entry_rename.blank? && assignment.starter_file_type == 'shuffle'
  end

  # Set starter_file_changed true for all groupings that have a starter file entry
  # from this starter file group
  def warn_affected_groupings
    affected_groupings = Grouping.joins(:starter_file_entries)
                                 .where('starter_file_entries.id': self.starter_file_entries.ids)
    affected_groupings.update_all(starter_file_changed: true)
  end

  private

  def delete_files
    FileUtils.rm_rf self.path
  end

  def create_dir
    FileUtils.mkdir_p self.path
  end

  def sanitize_rename_entry
    if entry_rename_changed?
      self.entry_rename = sanitize_file_name(entry_rename).strip
    end
  end

  def update_default
    if self.id == assignment.assignment_properties.default_starter_file_group_id
      assignment.assignment_properties.update(default_starter_file_group_id: nil)
    end
  end

  def update_timestamp
    assignment.assignment_properties.update(starter_file_updated_at: Time.current)
  end
end
