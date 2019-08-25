class Tag < ApplicationRecord
  has_and_belongs_to_many :groupings
  belongs_to :user

  # Constants
  NUM_CSV_FIELDS = 3

  def ==(another_tag)
    description == another_tag.description &&
        name == another_tag.name
  end

  def self.from_csv(data)
    admins = Hash[Admin.pluck(:user_name, :id)]
    tag_data = []
    result = MarkusCsv.parse(data) do |row|
      raise CsvInvalidLineError if row.length < NUM_CSV_FIELDS
      name, description, user_id = row[0], row[1], admins[row[2]]
      if name.nil? || name.strip.blank? || user_id.nil?
        raise CsvInvalidLineError
      end

      tag_data << {
        name: name,
        description: description,
        user_id: user_id
      }
    end
    Tag.import tag_data, validate: false, on_duplicate_key_ignore: true

    result
  end

  def self.from_yml(data)
    admins = Hash[Admin.pluck(:user_name, :id)]
    begin
      tag_data = data.map do |row|
        name, description, user_id = row['name'], row['description'], admins[row['user']]
        if name.nil? || name.strip.blank? || user_id.nil?
          raise ArgumentError("Invalid tag data #{row}.")
        end

        {
          name: name.strip,
          description: description,
          user_id: user_id
        }
      end
      Tag.import tag_data, validate: false, on_duplicate_key_ignore: true
    rescue ActiveRecord::ActiveRecordError, ArgumentError => e
      e
    end
  end
end
