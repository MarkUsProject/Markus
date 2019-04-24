class MarkingScheme < ApplicationRecord
  include CourseSummariesHelper
  has_many :marking_weights, dependent: :destroy
  accepts_nested_attributes_for :marking_weights

  default_scope { order('id ASC') }

  # Returns an array of all students' weighted grades that are not nil
  def students_weighted_grades_array
    return @grades_array unless @grades_array.nil?

    course_information
    all_students = Student.includes(:memberships,
                                    groupings: { current_submission_used: [:remark_result, :non_pr_results] },
                                    grade_entry_students: :grades)
    student_list = all_students.all.map do |student|
      get_student_information(student)
    end

    @grades_array = student_list.map { |s| s[:weighted_marks][self.id] }  # Note: this also returns the assigned value
  end

  # Returns a weighted grade distribution for all students' total weighted grades
  def students_weighted_grade_distribution_array(intervals = 20)
    data = students_weighted_grades_array
    data.extend(Histogram)
    histogram = data.histogram(intervals, min: 1, max: 100, bin_boundary: :min, bin_width: 100 / intervals)
    distribution = histogram.fetch(1)
    distribution[0] = distribution.first + data.count{ |x| x < 1 }
    distribution[-1] = distribution.last + data.count{ |x| x > 100 }

    distribution
  end
end
