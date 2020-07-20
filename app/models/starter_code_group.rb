class StarterCodeGroup < ApplicationRecord
  include SubmissionsHelper
  belongs_to :assignment, foreign_key: :assessment_id
  has_many :section_starter_code_groups
  has_many :sections, through: :section_starter_code_groups
  has_many :starter_code_entries, dependent: :destroy

  after_destroy_commit :delete_files
  after_create_commit :create_dir
  before_validation :sanitize_rename_entry
  before_create :set_default_if_first
  after_save :only_one_default, if: -> { self.is_default }

  validates_exclusion_of :entry_rename, in: %w[.. .]

  def path
    Pathname.new(assignment.starter_code_path) + id.to_s
  end

  def files_and_dirs
    starter_code_entries.map(&:files_and_dirs).flatten.map { |f| f.relative_path_from(path).to_s }
  end

  def zip_starter_code_files(user)
    zip_name = "#{assignment.short_identifier}-#{name}-starter-files-#{user.user_name}"
    zip_path = File.join('tmp', zip_name + '.zip')
    FileUtils.rm_rf zip_path
    Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
      self.files_and_dirs.map do |file|
        zip_entry_path = File.join zip_name, file
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
    entry_paths = starter_code_entries.pluck(:path)
    to_delete = entry_paths - fs_entry_paths
    to_add = fs_entry_paths - entry_paths
    starter_code_entries.where(path: to_delete).delete_all unless to_delete.empty?
    StarterCodeEntry.upsert_all(to_add.map { |p| { starter_code_group_id: self.id, path: p } } ) unless to_add.empty?
  end

  def should_rename
    use_rename && !entry_rename.blank? && assignment.starter_code_type == 'shuffle'
  end

  private

  def delete_files
    FileUtils.rm_rf self.path
  end

  def create_dir
    FileUtils.mkdir_p self.path
  end

  def only_one_default
    assignment.starter_code_groups.where.not(id: self.id).each do |g|
      g.update(is_default: false)
    end
  end

  def set_default_if_first
    return if assignment.starter_code_groups.exists?

    self.is_default = true
  end

  def sanitize_rename_entry
    if entry_rename_changed?
      self.entry_rename = sanitize_file_name(entry_rename)
    end
  end
end
