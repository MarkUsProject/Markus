require 'descriptive_statistics'
require 'histogram/array'

class MarkingScheme < ActiveRecord::Base
  has_many :marking_weights, dependent: :destroy
  accepts_nested_attributes_for :marking_weights

  # Get the total weights of all marking weights
  def total_weights
    total = marking_weights.sum(:weight).round(2)

    total
  end

  # Adds new_value to the key's current_value in hash
  def add_hash_value(hash, key, new_value)
    if hash.key?(key)
      hash[key] += new_value
    else
      hash[key] = new_value
    end
  end

  # Returns an array of all students' weighted grades that are not nil
  def students_weighted_grades_array
    student_marks = Hash.new

    Student.all.each do |student|
      marking_weights.each do |mw|
        gradable_item = mw.get_gradable_item
        if mw.is_assignment && !gradable_item.max_mark.nil? && gradable_item.max_mark != 0
          grouping = student.accepted_grouping_for(gradable_item.id)
          unless grouping.nil?
            result = grouping.current_result
            unless result.nil? || result.total_mark.nil? || result.marking_state != Result::MARKING_STATES[:complete]
              weighted_mark = result.total_mark / gradable_item.max_mark * mw.weight
              add_hash_value(student_marks, student, weighted_mark)
            end
          end
        elsif !mw.is_assignment && !gradable_item.out_of_total.nil? && gradable_item.out_of_total != 0
          grade_entry_student = find_grade_entry_student(gradable_item, student)
          unless grade_entry_student.nil?
            result = grade_entry_student.total_grade
            unless result.nil?
              weighted_mark = result / gradable_item.out_of_total * mw.weight
              add_hash_value(student_marks, student, weighted_mark)
            end
          end
        end
      end
    end

    student_marks.values
  end

  # Find the grade entry student that belongs to the grade entry form which is represented by a marking weight
  def find_grade_entry_student(gradable_item, student)
    GradeEntryStudent.where(user_id: student.id, grade_entry_form_id: gradable_item.id).first
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
    weighted_average = 0

    marking_weights.each do |marking_weight|
      gradable_item = marking_weight.get_gradable_item
      if !total_weights.nil? && total_weights != 0
        if marking_weight.is_assignment && !gradable_item.results_average.nil?
          weighted_avg = gradable_item.results_average * marking_weight.weight / total_weights
          weighted_average += weighted_avg
        elsif !marking_weight.is_assignment && !gradable_item.calculate_released_average.nil?
          weighted_avg = gradable_item.calculate_released_average * marking_weight.weight / total_weights
          weighted_average += weighted_avg
        end
      end
    end

    weighted_average
  end

  # Calculates the overall weighted median mark for the class
  def calculate_released_weighted_median
    weighted_median = 0

    marking_weights.each do |marking_weight|
      gradable_item = marking_weight.get_gradable_item
      if !total_weights.nil? && total_weights != 0
        if marking_weight.is_assignment && !gradable_item.results_median.nil?
          weighted_med = gradable_item.results_median * marking_weight.weight / total_weights
          weighted_median += weighted_med
        elsif !marking_weight.is_assignment && !gradable_item.calculate_released_median.nil?
          weighted_med = gradable_item.calculate_released_median * marking_weight.weight / total_weights
          weighted_median += weighted_med
        end
      end
    end

    weighted_median
  end
end
