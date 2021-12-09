class Tag < ApplicationRecord
  has_and_belongs_to_many :groupings
  belongs_to :role
  belongs_to :assessment, optional: true

  has_one :course, through: :role
  validate :courses_should_match

  # Constants
  NUM_CSV_FIELDS = 3

  def ==(another_tag)
    description == another_tag.description &&
        name == another_tag.name
  end

  def self.from_csv(data, course, assignment = nil)
    admins = Hash[course.admins.joins(:end_user).pluck(:user_name, 'roles.id')]
    tag_data = []
    result = MarkusCsv.parse(data) do |row|
      raise CsvInvalidLineError if row.length < NUM_CSV_FIELDS
      name, description, role_id = row[0], row[1], admins[row[2]]
      if name.nil? || name.strip.blank? || role_id.nil?
        raise CsvInvalidLineError
      end

      tag_data << {
        name: name,
        description: description,
        role_id: role_id,
        assessment_id: assignment&.id
      }
    end
    Tag.insert_all(tag_data) unless tag_data.empty?
    result
  end

  def self.from_yml(data, course, assignment = nil)
    admins = Hash[course.admins.joins(:end_user).pluck(:user_name, 'roles.id')]
    begin
      tag_data = data.map do |row|
        name, description, role_id = row['name'], row['description'], admins[row['user']]
        if name.nil? || name.strip.blank? || role_id.nil?
          raise ArgumentError("Invalid tag data #{row}.")
        end

        {
          name: name.strip,
          description: description,
          role_id: role_id,
          assessment_id: assignment&.id
        }
      end
      Tag.insert_all(tag_data) unless tag_data.empty?
    rescue ActiveRecord::ActiveRecordError, ArgumentError => e
      e
    end
  end
end
