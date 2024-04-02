# Assessment is an abstract model used for single-table-inheritance with Assignment and GradeEntryForm
# It can represent any form of graded work (assignment, test, lab, exam...etc.)
class Assessment < ApplicationRecord
  scope :assignments, -> { where(type: 'Assignment') }
  scope :grade_entry_forms, -> { where(type: 'GradeEntryForm') }

  has_many :marking_weights, dependent: :destroy
  has_many :tags, dependent: :destroy
  belongs_to :course, inverse_of: :assessments

  has_many :assessment_section_properties,
           dependent: :destroy,
           inverse_of: :assessment,
           class_name: 'AssessmentSectionProperties'
  accepts_nested_attributes_for :assessment_section_properties

  has_many :lti_line_items, dependent: :destroy

  # Call custom validator in order to validate the :due_date attribute
  # date: true maps to DateValidator (custom_name: true maps to CustomNameValidator)
  # Look in lib/validators/* for more info
  validates :due_date, date: true

  validates :short_identifier, uniqueness: { scope: :course_id }
  validates :short_identifier, presence: true
  validate :short_identifier_unchanged, on: :update
  validates :description, presence: true
  validates :is_hidden, inclusion: { in: [true, false] }
  validates :short_identifier, format: { with: /\A[a-zA-Z0-9\-_]+\z/,
                                         message: 'short_identifier must only contain alphanumeric, hyphen, or ' \
                                                  'underscore' }

  def self.type
    %w[Assignment GradeEntryForm]
  end

  def short_identifier_unchanged
    return unless short_identifier_changed?
    errors.add(:short_id_change, 'short identifier should not be changed once an assessment has been created')
    false
  end

  def upcoming(*)
    return true if self.due_date.nil?
    self.due_date > Time.current
  end

  # Returns grade distribution histogram bins of the grades for this assessment, using the grades in
  # self.completed_result_marks.
  def grade_distribution_array(intervals = 20)
    data = percentage_grades_array
    data.extend(Histogram)
    histogram = data.histogram(intervals, min: 1, max: 100, bin_boundary: :min, bin_width: 100 / intervals)
    distribution = histogram.fetch(1)
    distribution[0] = distribution.first + data.count { |x| x < 1 }
    distribution[-1] = distribution.last + data.count { |x| x > 100 }

    distribution
  end

  # Returns n array of all the grades, as percentages, for this assessment, using the grades in
  # self.completed_result_marks. Returns an empty array if self.max_mark is 0.
  def percentage_grades_array
    return [] if self.max_mark.zero?

    factor = 100 / self.max_mark
    self.completed_result_marks.map { |mark| mark * factor }
  end

  # Returns the average grade for this assessment, using all grades in self.completed_result_marks.
  # If +points+ is true, this returns the raw average point grade for this assessment.
  # Otherwise, the average percentage grade for this assessment is returned.
  def results_average(points: false)
    return 0 if self.max_mark.zero?

    marks = self.completed_result_marks
    if marks.empty?
      0
    else
      point_average = DescriptiveStatistics.mean(marks)
      points ? point_average : (point_average * 100 / self.max_mark).round(2).to_f
    end
  end

  # Returns the median grade for this assessment, using all grades in self.completed_result_marks.
  # If +points+ is true, this returns the raw median point grade for this assessment.
  # Otherwise, the median percentage grade for this assessment is returned.
  def results_median(points: false)
    return 0 if self.max_mark.zero?

    marks = self.completed_result_marks
    if marks.empty?
      0
    else
      point_median = DescriptiveStatistics.median(marks)
      points ? point_median : (point_median * 100 / self.max_mark).round(2).to_f
    end
  end

  # Returns the number of grades under 50% for this assessment, using all grades in self.completed_result_marks.
  def results_fails
    out_of = self.max_mark
    self.completed_result_marks.count { |mark| mark < out_of / 2.0 }
  end

  # Returns the number of grades equal to 0 for this assessment, using all grades in self.completed_result_marks.
  def results_zeros
    self.completed_result_marks.count(&:zero?)
  end

  # Returns the standard deviation for this assessment, using all grades in self.completed_result_marks.
  def results_standard_deviation
    return 0 if self.max_mark.zero?

    marks = self.completed_result_marks
    if marks.empty?
      0
    else
      DescriptiveStatistics.standard_deviation(marks)
    end
  end
end
