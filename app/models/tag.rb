class Tag < ApplicationRecord
  has_and_belongs_to_many :groupings
  belongs_to :role
  belongs_to :assessment, optional: true

  has_one :course, through: :role
  validate :courses_should_match
  validates :name, presence: true, length: { maximum: 30 }, uniqueness: { scope: :assessment_id, conditions: -> {
    where.not(assessment_id: nil)
  } }

  # Constants
  NUM_CSV_FIELDS = 3

  def ==(other)
    description == other.description &&
        name == other.name
  end

  def self.from_csv(data, course, assignment_id)
    instructors = course.instructors.joins(:user).pluck(:user_name, 'roles.id').to_h
    tag_data = []
    result = MarkusCsv.parse(data) do |row|
      raise CsvInvalidLineError if row.length < NUM_CSV_FIELDS
      name, description, role_id = row[0], row[1], instructors[row[2]]
      if name.nil? || name.strip.blank? || role_id.nil?
        raise CsvInvalidLineError
      end

      tag_data << {
        name: name,
        description: description,
        role_id: role_id,
        assessment_id: assignment_id
      }
    end
    Tag.insert_all(tag_data) unless tag_data.empty?
    result
  end

  def self.from_yml(data, course, assignment_id, allow_ta_upload: false)
    instructors = course.instructors.joins(:user).pluck(:user_name, 'roles.id').to_h
    begin
      tag_data = data.map do |row|
        row = row.symbolize_keys
        author = instructors[row[:user]]
        # Allow TAs with proper permissions to upload yml tag data
        if allow_ta_upload && author.nil? && !row[:user].nil?
          ta_author = course.tas.joins(:user).find_by('users.user_name': row[:user])
          author = ta_author.id unless ta_author.nil? || !ta_author.grader_permission.manage_assessments
        end
        name, description, role_id = row[:name], row[:description], author
        if name.nil? || name.strip.blank? || role_id.nil?
          raise ArgumentError, I18n.t('tags.invalid_tag_data', item: row)
        end

        {
          name: name.strip,
          description: description,
          role_id: role_id,
          assessment_id: assignment_id
        }
      end
      Tag.insert_all(tag_data) unless tag_data.empty?
    rescue ActiveRecord::ActiveRecordError, ArgumentError => e
      e
    end
  end
end
