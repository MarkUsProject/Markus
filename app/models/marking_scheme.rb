class MarkingScheme < ApplicationRecord
  include CourseSummariesHelper
  has_many :marking_weights, dependent: :destroy
  accepts_nested_attributes_for :marking_weights

  default_scope { order('id ASC') }

  # Returns an array of all students' weighted grades that are not nil
  def students_weighted_grades_array(current_user)
    return @grades_array unless @grades_array.nil?

    all_grades = get_table_json_data(current_user)
    @grades_array = all_grades.map { |s| s[:weighted_marks][self.id] } # Note: this also returns the assigned value
    p @grades_array
    @grades_array
  end

  # Returns a weighted grade distribution for all students' total weighted grades
  def students_weighted_grade_distribution_array(current_user, intervals = 20)
    data = students_weighted_grades_array(current_user)
    data.extend(Histogram)
    histogram = data.histogram(intervals, min: 1, max: 100, bin_boundary: :min, bin_width: 100 / intervals)
    distribution = histogram.fetch(1)
    distribution[0] = distribution.first + data.count{ |x| x < 1 }
    distribution[-1] = distribution.last + data.count{ |x| x > 100 }

    distribution
  end
end
