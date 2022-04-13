class UploadUsersJob < ApplicationJob
  def perform(user_class, data, encoding)
    progress.total = data.lines.count
    user_indices = {
      user_name: EndUser::CSV_ORDER.index(:user_name) || 0,
      last_name: EndUser::CSV_ORDER.index(:last_name) || 1,
      first_name: EndUser::CSV_ORDER.index(:first_name) || 2,
      id_number: EndUser::CSV_ORDER.index(:id_number) || 3,
      email: EndUser::CSV_ORDER.index(:email) || 4
    }
    user_class.transaction do
      MarkusCsv.parse(data, encoding: encoding, skip_blanks: true, row_sep: :auto) do |row|
        user_data = {
          user_name: row[user_indices[:user_name]]&.strip,
          last_name: row[user_indices[:last_name]]&.strip,
          first_name: row[user_indices[:first_name]]&.strip,
          id_number: row[user_indices[:id_number]]&.strip,
          email: row[user_indices[:email]]&.strip
        }
        next if user_data[:user_name].blank? || user_data[:last_name].blank? || user_data[:first_name].blank?
        user = user_class.find_or_initialize_by(user_data)
        raise "#{user_data[:user_name]}: #{user.errors.full_messages.join('; ')}" unless user.save
        progress.increment
      end
    end
  end
end
