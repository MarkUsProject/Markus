require 'histogram/array'

# GradeEntryItem represents column names (i.e. question names and totals)
# in a grade entry form.
class GradeEntryItem < ApplicationRecord

  belongs_to :grade_entry_form
  validates_associated :grade_entry_form

  has_many :grades, dependent: :delete_all

  has_many :grade_entry_students, through: :grades

  validates_presence_of :name
  validates_uniqueness_of :name,
                          scope: :grade_entry_form_id,
                          message: I18n.t('grade_entry_forms.invalid_name')

  validates_presence_of :out_of
  validates_numericality_of :out_of,
                            greater_than_or_equal_to: 0,
                            message: I18n.t('grade_entry_forms.invalid_column_out_of')

  validates_presence_of :position
  validates_numericality_of :position, greater_than_or_equal_to: 0

  BLANK_MARK = ''

  # Determine the total mark for a particular student, as a percentage
  def calculate_total_percent(grade)
    percent = BLANK_MARK

    # Check for NA mark or division by 0
    unless grade.nil? || out_of == 0
      percent = (grade / out_of) * 100
    end
    percent
  end

  # Returns grade distribution for a grade entry item for each student
  def grade_distribution_array(intervals = 20)
    data = grades.where.not(grade: nil)
             .pluck(:grade)
             .map { |g| calculate_total_percent(g) }
    histogram = data.histogram(intervals, :min => 1, :max => 100, :bin_boundary => :min, :bin_width => 100 / intervals)
    distribution = histogram.fetch(1)
    distribution[0] = distribution.first + data.count{ |x| x < 1 }
    distribution[-1] = distribution.last + data.count{ |x| x > 100 }

    distribution
  end

  # Create new grade entry items (or update them if they already exist) using
  # the first two rows from a CSV file
  #
  # These rows are formatted as follows:
  # "",Q1,Q2,...
  # "",Q1total,Q2total,...
  #
  # (We've included "" at the beginning of each line so that it is easy
  # to upload grades directly from a spreadsheet where there would be a
  # blank column heading in the first row in the table. The "" also
  # appears at the beginning of the first two rows when downloading the
  # grades as a CSV file so that the table is formatted nicely when using
  # a program like Excel to import the CSV.)
  # TODO: Move this to GradeEntryForm
  def self.create_or_update_from_csv_rows(names, totals, grade_entry_form, overwrite)
    # The number of question names given should equal the number of question totals
    if names.size != totals.size || names.empty? || totals.empty?
      raise CSV::MalformedCSVError
    end

    # We ignore the first column.
    names.shift
    totals.shift

    grade_entries = []

    (names.size).times do |i|
      grade_entry_item = grade_entry_form.grade_entry_items.where(name: names[i]).first_or_initialize

      grade_entry_item.position = i+1
      grade_entry_item.out_of = totals[i]
      grade_entries << grade_entry_item
    end

    # Delete old questions if we want to overwrite them
    missing_items = grade_entry_form.grade_entry_items.where.not(name: names)
    if overwrite
      missing_items.destroy_all
    else
      i = names.size + 1
      missing_items.each do |item|
        item.update(position: i)
        i = i + 1
      end
    end

    return grade_entries
  end
end
