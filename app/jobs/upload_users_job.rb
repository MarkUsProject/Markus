class UploadUsersJob < ApplicationJob
  def self.on_complete_js(_status)
    'window.location.reload.bind(window.location)'
  end

  def perform(user_class, data, encoding)
    progress.total = data.lines.count
    user_class.transaction do
      MarkusCsv.parse(data, encoding: encoding, skip_blanks: true, row_sep: :auto) do |row|
        user_data = EndUser::CSV_ORDER.zip(row).to_h
        user = user_class.find_by(user_name: user_data[:user_name]) || user_class.new(user_data)
        user.assign_attributes(user_data)
        raise "#{user_data[:user_name]}: #{user.errors.full_messages.join('; ')}" unless user.save
        progress.increment
      end
    end
  end
end
