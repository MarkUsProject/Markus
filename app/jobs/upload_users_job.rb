class UploadUsersJob < ApplicationJob
  USER_FIELDS = [:user_name, :last_name, :first_name, :id_number, :email].freeze

  def self.on_complete_js(_status)
    'window.location.reload.bind(window.location)'
  end

  def perform(user_class, data, encoding)
    progress.total = data.lines.count
    user_class.transaction do
      MarkusCsv.parse(data, encoding: encoding, skip_blanks: true, row_sep: :auto) do |row|
        user_data = {}
        USER_FIELDS.each_with_index do |field, index|
          row_index = EndUser::CSV_ORDER.index(field) || index
          user_data[field] = row[row_index]&.strip
        end
        user = user_class.find_or_initialize_by(user_data)
        raise "#{user_data[:user_name]}: #{user.errors.full_messages.join('; ')}" unless user.save
        progress.increment
      end
    end
  end
end
