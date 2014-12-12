class Tag < ActiveRecord::Base

  has_and_belongs_to_many :groupings

  # Constants
  CSV_FIELDS = 2

  def ==(another_tag)
    description == another_tag.description &&
        name == another_tag.name
  end

  def self.parse_csv(file, user, invalid_lines, encoding)
    # Sets number of updates and encoding.
    nb_updates = 0
    file = file.utf8_encode(encoding)

    # Parses the CSV file.
    CSV.parse(file) do |row|
      # Checks to see if the current line is empty.
      next if CSV.generate_line(row).strip.empty?

      # Now, we parse the row.
      begin
        Tag.create_or_update_from_csv_row(row, user)
        nb_updates += 1
      rescue RuntimeError => error
        invalid_lines << row.join(', ') +
                         ': ' +
                         error.message unless invalid_lines.nil?
      end
    end

    nb_updates
  end

  def self.create_or_update_from_csv_row(_row, _user)
    # First, we see if the row is valid.
    if _row.length < CSV_FIELDS
      raise Il8n.t('tags.upload.invalid_line')
    end

    # If get through this, we now parse the line.
    row_data = _row.clone

    # Get the tag data.
    tag_name = row_data.shift
    tag_description = row_data.shift

    Tag.create(name: tag_name, description: tag_description, user: _user)
  end

  def self.create_or_update_from_yml_key(key)
    puts(tag_name = key[0])
  end

  def self.generate_csv_list(tags)
    # Start generating the CSV file.
    file_output = CSV.generate do |csv|
      # Go through each of the tags.
      tags.each do |tag|
        user = User.find(tag.user)

        tag_column = [tag.name,
                      tag.description,
                      user.first_name + user.last_name]

        # Add it to the CSV file.
        csv << tag_column
      end
    end
  end
end
