# FIXME: Once fixed with Ruby 1.9, we should use only csv
# TODO: All FasterCSV methods should be renamed in CSV
# The « include CSVHelper » should be removed, replaced by « require 'csv' »,
# this file deleted.
# see http://www.ruby-doc.org/ruby-1.9/classes/CSV.html
module CsvHelper
  if RUBY_VERSION > "1.9"
    require "csv"
    unless defined? FCSV
      class Object
        FCSV = CSV
        alias_method :FCSV, :CSV
      end
    end
    unless defined? FasterCSV
      class Object
        FasterCSV = CSV
        alias_method :FasterCSV, :CSV
      end
    end
  else
    require "fastercsv"
  end
end
