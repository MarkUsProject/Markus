# upload users job
class UploadRolesJob < ApplicationJob
  def perform(role_class, course, data, encoding)
    progress.total = data.lines.count
    role_class.transaction do
      MarkusCsv.parse(data, encoding: encoding, skip_blanks: true, row_sep: :auto) do |row|
        user_name = row.first.strip
        next if user_name.blank?
        human = Human.find_by_user_name(user_name)
        raise I18n.t('users.not_found', user_names: user_name) if human.nil?
        role = role_class.new(human: human, course: course)
        raise "#{user_name}: #{role.errors.full_messages.join('; ')}" unless role.save
        progress.increment
      end
    end
  end
end
