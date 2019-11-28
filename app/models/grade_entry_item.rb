# GradeEntryItem represents column names (i.e. question names and totals)
# in a grade entry form.
class GradeEntryItem < ApplicationRecord

  belongs_to :grade_entry_form, inverse_of: :grade_entry_items, foreign_key: :assessment_id

  has_many :grades, dependent: :delete_all

  has_many :grade_entry_students, through: :grades

  validates_presence_of :name
  validates_uniqueness_of :name,
                          scope: :assessment_id

  validates_presence_of :out_of
  validates_numericality_of :out_of,
                            greater_than_or_equal_to: 0

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
    data.extend(Histogram)
    histogram = data.histogram(intervals, :min => 1, :max => 100, :bin_boundary => :min, :bin_width => 100 / intervals)
    distribution = histogram.fetch(1)
    distribution[0] = distribution.first + data.count{ |x| x < 1 }
    distribution[-1] = distribution.last + data.count{ |x| x > 100 }

    distribution
  end
end
