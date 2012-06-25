# FIXME: Once fixed with Ruby 1.9, we should use only csv
# TODO: All FasterCSV methods should be renamed in CSV
# The « include CSVHelper » should be removed, replaced by « require 'csv' »,
# this file deleted, and CsvHelper::Csv replaced by « CSV ».
# see http://www.ruby-doc.org/ruby-1.9/classes/CSV.html
require 'fastercsv' unless RUBY_VERSION > '1.9'
require 'csv'       if     RUBY_VERSION > '1.9'

module CsvHelper
  begin
    class Csv < CSV
    end
  rescue
    class Csv < FasterCSV
    end
  end
end
