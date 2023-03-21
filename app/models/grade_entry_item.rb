# GradeEntryItem represents column names (i.e. question names and totals)
# in a grade entry form.
class GradeEntryItem < ApplicationRecord
  belongs_to :grade_entry_form, inverse_of: :grade_entry_items, foreign_key: :assessment_id

  has_one :course, through: :grade_entry_form

  has_many :grades, dependent: :delete_all

  has_many :grade_entry_students, through: :grades

  validates :name, presence: true
  validates :name,
            uniqueness: { scope: :assessment_id }

  validates :out_of, presence: true
  validates :out_of,
            numericality: { greater_than_or_equal_to: 0 }

  validates :position, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  BLANK_MARK = ''.freeze

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
    data = grades_array.map { |g| calculate_total_percent(g) }
    data.extend(Histogram)
    histogram = data.histogram(intervals, min: 1, max: 100, bin_boundary: :min, bin_width: 100 / intervals)
    distribution = histogram.fetch(1)
    distribution[0] = distribution.first + data.count { |x| x < 1 }
    distribution[-1] = distribution.last + data.count { |x| x > 100 }

    distribution
  end

  # Returns the raw average grade of marks given for this grade item based on the marks given by self.grades_array
  def average
    return 0 if self.out_of.zero?

    marks = grades_array
    marks.empty? ? 0 : DescriptiveStatistics.mean(marks)
  end

  # Returns the raw median grade of marks given for this grade item based on the marks given by self.grades_array
  def median
    return 0 if self.out_of.zero?

    marks = grades_array
    marks.empty? ? 0 : DescriptiveStatistics.median(marks)
  end

  # Returns the raw standard deviation of marks given for this grade item based on the marks given by self.grades_array
  def standard_deviation
    return 0 if self.out_of.zero?

    marks = grades_array
    marks.empty? ? 0 : DescriptiveStatistics.standard_deviation(marks)
  end

  def grades_array
    return @grades_array if defined? @grades_array
    @grades_array = self.grades.where.not(grade: nil).pluck(:grade)
  end
end
