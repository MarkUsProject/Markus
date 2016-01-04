require 'csv'

class MarkusCSV

  # Return a CSV string representation of an array of data.
  # objects is an array of data, and gen_csv is a block which
  # takes an object and returns an array of strings.
  def self.generate(objects, &gen_csv)
    CSV.generate do |csv|
      objects.each { |obj| csv << gen_csv.call(obj) }
    end
  end
end
