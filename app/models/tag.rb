class Tag < ActiveRecord::Base
  has_and_belongs_to_many :groupings
  belongs_to :user

  # Constants
  CSV_FIELDS = 2

  def ==(another_tag)
    description == another_tag.description &&
        name == another_tag.name
  end

  def self.create_or_update_from_csv_row(_row, _user)
    # First, we see if the row is valid.
    if _row.length < CSV_FIELDS
      raise CSVInvalidLineError
    end

    # If get through this, we now parse the line.
    row_data = _row.clone

    # Get the tag data.
    tag_name = row_data.shift
    tag_description = row_data.shift

    raise CSVInvalidLineError if tag_name.nil? || tag_name.empty?

    # Creates a new tag object.
    tag = Tag.find_or_create_by(name: tag_name)
    tag.name = tag_name
    tag.description = tag_description
    tag.user = _user

    # Saves the tag.
    unless tag.save
      raise RuntimeError.new(tag.errors)
    end

    tag
  end

  def self.create_or_update_from_yml_key(key)
    # Get the name and description for the tag.
    tag_name = key[1]['name']
    tag_description = key[1]['description']

    # Finds or creates a tag based on the name.
    tag = Tag.find_or_create_by(name: tag_name)
    tag.description = tag_description
    tag.user = key[1]['user']['id']

    unless tag.save
      raise RuntimeError.new(tag.errors)
    end

    tag
  end
end
