class Tag < ActiveRecord::Base

  has_and_belongs_to_many :groupings

  def ==(another_tag)
    description == another_tag.description &&
        name == another_tag.name
  end

  def self.parse_csv(file, assignment, invalid_lines, encoding)
    # Sets number of updates and encoding.
    nb_updates = 0
    file = file.utf8_encode(encoding)

    # Parses the CSV file.
    CSV.parse(file) do |row|
      # Checks to see if the current line is empty.
      next if CSV.generate_line(row).strip.empty?

      # Now, we parse the row.
      begin
        Tag.create_or_update_from_csv_row(row, assignment)
        nb_updates += 1
      rescue RuntimeError => error
        invalid_lines << row.join(',') + ': ' + error.message unless invalid_lines.nil?
      end
    end

    nb_updates
  end

  def self.create_or_update_from_csv_row(row, assignment)

  end
end
