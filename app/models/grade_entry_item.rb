# GradeEntryItem represents column names (i.e. question names and totals)
# in a grade entry form.
class GradeEntryItem < ActiveRecord::Base
  belongs_to  :grade_entry_form

  has_many   :grades, :dependent => :destroy
  has_many   :grade_entry_students, :through => :grades

  validates_presence_of   :name
  validates_presence_of   :out_of

  validates_associated    :grade_entry_form

  validates_numericality_of :out_of, :greater_than_or_equal_to => 0,
                            :message => I18n.t('grade_entry_forms.invalid_column_out_of')
  validates_uniqueness_of   :name, :scope => :grade_entry_form_id,
                            :message => I18n.t('grade_entry_forms.invalid_name')

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
  def self.create_or_update_from_csv_rows(names, totals, grade_entry_form)
    # The number of question names given should equal the number of question totals
    if names.size != totals.size
      raise I18n.t('grade_entry_forms.csv.incomplete_header')
    end

    # Make sure the first elements in names and totals are ""
    unless names.shift == '' and totals.shift == ''
      raise I18n.t('grade_entry_forms.csv.incomplete_header')
    end

    # Process the question names and totals
    (0..(names.size - 1)).each do |i|
      grade_entry_item = grade_entry_form.grade_entry_items.find_or_create_by_name(names[i])
      grade_entry_item.out_of = totals[i]
      unless grade_entry_item.save
        raise RuntimeError.new(grade_entry_item.errors)
      end
    end
  end

end
