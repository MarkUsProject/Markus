class Tag < ApplicationRecord
  has_and_belongs_to_many :groupings
  belongs_to :user
  belongs_to :assessment, optional: true

  # Constants
  NUM_CSV_FIELDS = 3

  def ==(another_tag)
    description == another_tag.description &&
        name == another_tag.name
  end

  def self.from_csv(data, assignment_id)
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
        user_id: user_id,
        assessment_id: assignment_id
      }
    end
    Tag.insert_all(tag_data) unless tag_data.empty?
    result
  end

  def self.from_yml(data, assignment_id, allow_ta_upload = false)
    admins = Hash[Admin.pluck(:user_name, :id)]
    begin
      tag_data = data.map do |row|
        row = row.symbolize_keys
        author = admins[row[:user]]
        # Allow TAs with proper permissions to upload yml tag data
        if allow_ta_upload && author.nil? && !row[:user].nil?
          ta_author = Ta.find_by(user_name: row[:user])
          author = ta_author.id unless ta_author.nil? || !ta_author.grader_permission.manage_assessments
        end
        name, description, user_id = row[:name], row[:description], author
        if name.nil? || name.strip.blank? || user_id.nil?
          raise ArgumentError, I18n.t('tags.invalid_tag_data', item: row)
        end

        {
          name: name.strip,
          description: description,
          user_id: user_id,
          assessment_id: assignment_id
        }
      end
      Tag.insert_all(tag_data) unless tag_data.empty?
    rescue ActiveRecord::ActiveRecordError, ArgumentError => e
      e
    end
  end
end
