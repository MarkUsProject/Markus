# upload users job
class UploadUsersJob < ApplicationJob
  def self.on_complete_js(_status)
    '() => {window.groupsManager && window.groupsManager.fetchData()}'
  end

  def perform(user_class, course, data, encoding)
    user_columns = user_class::CSV_UPLOAD_ORDER.dup
    progress.total = data.length
    User.transaction do
      MarkusCsv.parse(data, skip_blanks: true, row_sep: :auto, encoding: encoding) do |row|
        next if row.empty?

        user_hash = Hash[user_columns.zip row]
        user_hash[:type] = 'Standard'
        section = user_hash[:section_id]
        unless section.nil?
          section = Section.find_or_create_by(name: user_hash[:section_name])
        end
        user = User.find_or_initialize_by(user_hash.slice(:user_name)) do |user|
          user.assign_attributes(user_hash.slice(:first_name, :last_name))
        end
        user.update!(user_hash.except(:section_name))
        role = user_class.find_or_initialize_by(user: user, course: course)
        unless section.nil?
          role.section_id = section
        end
        role.save!
        progress.increment
      end
    end
  end
end
