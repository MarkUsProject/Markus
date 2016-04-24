# GradeEntryItem represents column names (i.e. question names and totals)
# in a grade entry form.
class GradeEntryItem < ActiveRecord::Base

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

    (names.size).times do |i|
      grade_entry_item = grade_entry_form.grade_entry_items.find_or_create_by(name: names[i])
      grade_entry_item.position = i+1
      grade_entry_item.out_of = totals[i]
      unless grade_entry_item.save
        raise CSV::MalformedCSVError
      end
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
  end
end
