# upload users job
class UploadRolesJob < ApplicationJob
  def perform(role_class, course, data, encoding)
    progress.total = data.lines.count
    User.transaction do
      MarkusCsv.parse(data, skip_blanks: true, row_sep: :auto, encoding: encoding) do |row|
        next if row.empty?

        human_hash = Hash[role_class::CSV_UPLOAD_ORDER.zip row]
        human = Human.find_or_initialize_by(human_hash.slice(:user_name)) do |h|
          h.assign_attributes(human_hash.slice(:first_name, :last_name))
        end
        human.update!(human_hash.except(:section_name))
        role = role_class.find_or_initialize_by(human: human, course: course)
        unless human_hash[:section_name].nil?
          role.section = Section.find_or_create_by(name: human_hash[:section_name], course: course)
        end
        role.save!
        progress.increment
      end
    end
  end
end
