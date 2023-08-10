require 'csv'

class MarkusCsv
  MAX_INVALID_LINES = 10
  INVALID_LINE_SEP = ' - '.freeze

  # Returns a CSV string representation of an array of data.
  # 'objects' is an array of data, and gen_csv is a block which
  # takes an object and returns an array of strings.
  def self.generate(objects, headers = [])
    CSV.generate do |csv|
      headers.each { |obj| csv << obj }
      objects.each { |obj| csv << yield(obj) }
    end
  end

  # Performs an action for each object in a collection represented by
  # a CSV string. 'input' is the input string and parse_obj is a block
  # which takes a line and performs an action, or raises CsvInvalidLineError.
  # Returns a result hash, containing a success message with the number of
  # successful rows parsed, as well as an error message, consisting of one
  # of the following:
  #   1) A string listing all erroneous lines.
  #   2) A more generic error message for invalid files.
  def self.parse(input, **options)
    invalid_lines = []
    valid_line_count = 0
    result = { invalid_lines: '', valid_lines: '' }
    header_count = options.delete(:header_count) || 0
    begin
      if options[:encoding]
        input = input.encode(Encoding::UTF_8, options[:encoding])
      end
      CSV.parse(input, **options) do |row|
        yield row
        valid_line_count += 1
      rescue CsvInvalidLineError => e
        # append individual error messages to each entry
        line = row.join(',')
        unless e.message.blank? || e.message == 'CsvInvalidLineError'
          line.concat(" (#{e.message})")
        end
        invalid_lines << line
      end
      # Return string representation of the erroneous lines.
      unless invalid_lines.empty?
        result[:invalid_lines] = I18n.t('upload_errors.invalid_rows') +
          invalid_lines.take(MAX_INVALID_LINES).join(INVALID_LINE_SEP)
      end
      if valid_line_count > header_count
        result[:valid_lines] = I18n.t('upload_success', count: valid_line_count - header_count)
      end
    rescue CSV::MalformedCSVError
      result[:invalid_lines] = I18n.t('upload_errors.malformed_csv')
    rescue ArgumentError
      result[:invalid_lines] = I18n.t('upload_errors.unparseable_csv')
    end
    result
  end
end
