require 'csv'
include ActionView::Helpers::TranslationHelper

class MarkusCSV
  MAX_INVALID_LINES = 10

  # Returns a CSV string representation of an array of data.
  # 'objects' is an array of data, and gen_csv is a block which
  # takes an object and returns an array of strings.
  def self.generate(objects, headers=[], &gen_csv)
    CSV.generate do |csv|
      headers.each { |obj| csv << obj }
      objects.each { |obj| csv << gen_csv.call(obj) }
    end
  end

  # Performs an action for each object in a collection represented by
  # a CSV string. 'input' is the input string, and parse_obj is a block which
  # takes a line and performs an action, or raises CSVInvalidLineError.
  # Returns a result hash, containing a success message with the number of
  # successful rows parsed, as well as an error message, consisting of one
  # of the following:
  #   1) A string listing all erroneous lines.
  #   2) A more generic error message for invalid files.
  def self.parse(input, options = {}, &parse_obj)
    invalid_lines = []
    valid_line_count = 0
    result = { invalid_lines: '', valid_lines: '' }
    begin
      if options[:encoding]
        input = input.utf8_encode(options[:encoding])
      end
      CSV.parse(input, options) do |row|
        begin
          parse_obj.call(row)
          valid_line_count += 1
        rescue CSVInvalidLineError => e
          # append individual error messages to each entry
          line = row.join(',')
          unless e.message.blank? || e.message == 'CSVInvalidLineError'
            line.concat(" (#{e.message})")
          end
          invalid_lines << line
        end
      end
      # Return string representation of the erroneous lines.
      unless invalid_lines.empty?
        result[:invalid_lines] = t('csv_invalid_lines') + ' ' +
          invalid_lines.take(MAX_INVALID_LINES).join(', ')
      end
      if valid_line_count > 0
        result[:valid_lines] = I18n.t('csv_valid_lines',
                                      valid_line_count: valid_line_count)
      end
    rescue CSV::MalformedCSVError
      result[:invalid_lines] = t('csv.upload.malformed_csv')
    rescue ArgumentError => e
      result[:invalid_lines] = t('csv.upload.non_text_file_with_csv_extension')
    end
    result
  end
end
