require 'csv'
include ActionView::Helpers::TranslationHelper

class MarkusCSV
  MAX_INVALID_LINES = 10

  # Returns a CSV string representation of an array of data.
  # 'objects' is an array of data, and gen_csv is a block which
  # takes an object and returns an array of strings.
  def self.generate(objects, &gen_csv)
    CSV.generate do |csv|
      objects.each { |obj| csv << gen_csv.call(obj) }
    end
  end

  # Performs an action for each object in a collection represented by
  # a CSV string. 'input' is the input string, and parse_obj is a block which
  # takes a line and performs an action, or raises CSVInvalidLineError.
  # Returns an empty string upon success, or one of the following:
  #   1) A string listing all erroneous lines.
  #   2) A more generic error message for invalid files.
  def self.parse(input, options = {}, &parse_obj)
    invalid_lines = []
    begin
      if options[:encoding]
        input = input.utf8_encode(options[:encoding])
      end
      CSV.parse(input, options) do |row|
        begin
          parse_obj.call(row)
        rescue CSVInvalidLineError
          invalid_lines << row
        end
      end
      # Return string representation of the erroneous lines.
      if invalid_lines.empty?
        ''
      else
        t('csv_invalid_lines') + ' ' +
          invalid_lines.take(MAX_INVALID_LINES).join(', ')
      end
    rescue CSV::MalformedCSVError
      t('csv.upload.malformed_csv')
    rescue ArgumentError
      t('csv.upload.non_text_file_with_csv_extension')
    end
  end
end
