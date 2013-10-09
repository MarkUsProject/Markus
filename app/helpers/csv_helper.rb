# FIXME: Once fixed with Ruby 1.9, we should use only csv
# TODO: All FasterCSV methods should be renamed in CSV
# The « include CSVHelper » should be removed, replaced by « require 'csv' »,
# this file deleted, and CsvHelper::Csv replaced by « CSV ».
# see http://www.ruby-doc.org/ruby-1.9/classes/CSV.html
require 'fastercsv' unless RUBY_VERSION > '1.9'
require 'csv'       if     RUBY_VERSION > '1.9'

def class_defined(klass)
  begin
    klass = Module.const_get(klass)
    return klass.is_a?(Class)
  rescue NameError
    return false
  end
end

module CsvHelper
  if class_defined('CSV')
    CsvHelper.const_set :Csv, CSV
  else
    CsvHelper.const_set :Csv, FasterCSV
  end
end
