require 'descriptive_statistics'
require 'histogram/array'

class MarkingScheme < ActiveRecord::Base
  has_many :marking_weights, dependent: :destroy
  accepts_nested_attributes_for :marking_weights

  # Get the total weights of all marking weights
  def total_weights
    marking_weights.sum(:weight).round(2)
  end

  # Returns an array of all students' weighted grades that are not nil
  def students_weighted_grades_array
    student_marks = Hash.new(0)

    students = Student.includes({accepted_groupings: [:assignment, :current_result]}, :grade_entry_students)

    marking_weights.each do |mw|
      gradable_item = mw.get_gradable_item
      students.each do |student|
        if mw.is_assignment && !gradable_item.max_mark.nil? && gradable_item.max_mark != 0
          grouping = student.accepted_grouping_for(gradable_item.id) #########################################################
          unless grouping.nil?
            result = grouping.current_result
            unless result.nil? || result.total_mark.nil? || result.marking_state != Result::MARKING_STATES[:complete]
              weighted_mark = result.total_mark / gradable_item.max_mark * mw.weight
              student_marks[student] += weighted_mark
            end
          end
        elsif !mw.is_assignment && !gradable_item.out_of_total.nil? && gradable_item.out_of_total != 0
          grade_entry_student = GradeEntryStudent.find_by(user: student, grade_entry_form: gradable_item) #######
          unless grade_entry_student.nil?
            result = grade_entry_student.total_grade
            unless result.nil?
              weighted_mark = result / gradable_item.out_of_total * mw.weight
              student_marks[student] += weighted_mark
            end
          end
        end
      end
    end

    student_marks.values
  end

  # Returns a weighted grade distribution for all students' total weighted grades
  def students_weighted_grade_distribution_array(intervals = 20)
    data = students_weighted_grades_array
    histogram = data.histogram(intervals, min: 1, max: 100, bin_boundary: :min, bin_width: 100 / intervals)
    distribution = histogram.fetch(1)
    distribution[0] = distribution.first + data.count{ |x| x < 1 }
    distribution[-1] = distribution.last + data.count{ |x| x > 100 }

    distribution
  end

  # Calculates the overall weighted average mark for the class
  def calculate_released_weighted_average
    students_weighted_grades_array.mean
  end

  # Calculates the overall weighted median mark for the class
  def calculate_released_weighted_median
    students_weighted_grades_array.median
  end
end
