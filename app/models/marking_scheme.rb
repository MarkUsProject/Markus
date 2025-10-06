class MarkingScheme < ApplicationRecord
  include CourseSummariesHelper

  has_many :marking_weights, dependent: :destroy
  accepts_nested_attributes_for :marking_weights
  validates :name, uniqueness: { scope: :course_id }

  belongs_to :course

  default_scope { order(:id) }

  # Returns an array of all students' weighted grades that are not nil
  def students_weighted_grades_array(current_role)
    return @grades_array unless @grades_array.nil?

    all_grades = get_table_json_data(current_role)
    @grades_array = all_grades.map { |s| s[:weighted_marks][self.id][:mark] } # NOTE: this returns the assigned value
  end

  # Returns a weighted grade distribution for all students' total weighted grades
  def students_weighted_grade_distribution_array(current_role, intervals = 20)
    data = students_weighted_grades_array(current_role)
    max = [data.max, intervals].max

    data.extend(Histogram)
    histogram = data.histogram(intervals, min: 0, max: max, bin_boundary: :min, bin_width: max / intervals)
    distribution = histogram.fetch(1)
    distribution[0] = distribution.first + data.count { |x| x < 0 }
    distribution[-1] = distribution.last + data.count { |x| x > max }

    { data: distribution, max: max }
  end

  def students_grade_distribution(current_role, intervals = 20)
    data = students_weighted_grades_array(current_role)
    max = [data.max, 100].max

    data.extend(Histogram)
    histogram = data.histogram(intervals, min: 0, max: max, bin_boundary: :min, bin_width: max / intervals)
    distribution = histogram.fetch(1)
    distribution[0] += data.count { |x| x < 0 }
    distribution[-1] += data.count { |x| x > max }

    distribution
  end
end
