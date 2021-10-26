# upload users job
class UploadUsersJob < ApplicationJob
  def perform(user_class, course, data, encoding)
    user_columns = user_class::CSV_UPLOAD_ORDER.dup
    progress.total = data.lines.count
    User.transaction do
      MarkusCsv.parse(data, skip_blanks: true, row_sep: :auto, encoding: encoding) do |row|
        next if row.empty?

        user_hash = Hash[user_columns.zip row]
        unless user_hash[:section_name].nil?
          section = Section.find_or_create_by(name: user_hash[:section_name], course: course)
        end
        user = Human.find_or_initialize_by(user_hash.slice(:user_name)) do |u|
          u.assign_attributes(user_hash.slice(:first_name, :last_name))
        end
        user.update!(user_hash.except(:section_name))
        role = user_class.find_or_initialize_by(human: user, course: course)
        role.section = section unless section.nil?
        role.save!
        progress.increment
      end
    end
  end
end
