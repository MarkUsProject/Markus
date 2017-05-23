class MarkingScheme < ActiveRecord::Base
  has_many :marking_weights, dependent: :destroy
  accepts_nested_attributes_for :marking_weights

  # Gets the marking weights for all assignments in the correct order
  def get_assignments_marking_weights(assignments)
    assignments_mw = marking_weights.where(is_assignment: true)

    assignments.each_with_index do |a, index|
      assignments_mw.each_with_index do |mw, i|
        if mw.get_gradable_item.id == a.id
          temp = assignments_mw[index]
          assignments_mw[index] = mw
          assignments_mw[i] = temp
        end
      end
    end

    return assignments_mw
  end

  # Gets the marking weights for all grade entry forms in the correct order
  def get_gefs_marking_weights(gefs)
    gefs_mw = marking_weights.where(is_assignment: false)

    gefs.each_with_index do |gef, index|
      gefs_mw.each_with_index do |mw, i|
        if mw.get_gradable_item.id == gef.id
          temp = gefs_mw[index]
          gefs_mw[index] = mw
          gefs_mw[i] = temp
        end
      end
    end

    return gefs_mw
  end

  # Calculates the weighted average mark for all assignments and grade entry forms
  def calculate_released_weighted_average
    return calculate_released_assignments_average + calculate_released_gef_average
  end

  # Calculates the weighted average mark for all assignments
  def calculate_released_assignments_average
    weighted_average = 0
    assignments_mw = marking_weights.where(is_assignment: true)

    assignments_mw.each do |marking_weight|
      gradable_item = marking_weight.get_gradable_item
      if !gradable_item.results_average.nil?
        weighted_avg = gradable_item.results_average * marking_weight.weight / 100
        weighted_average += weighted_avg
      end
    end

    return weighted_average
  end

  # Calculates the weighted average mark for all grade entry forms
  def calculate_released_gef_average
    weighted_average = 0
    gefs_mw = marking_weights.where(is_assignment: false)

    gefs_mw.each do |marking_weight|
      gradable_item = marking_weight.get_gradable_item
      if !gradable_item.calculate_released_average.nil?
        weighted_avg = gradable_item.calculate_released_average * marking_weight.weight / 100
        weighted_average += weighted_avg
      end
    end

    return weighted_average
  end

  # Calculates the weighted median mark for all assignments and grade entry forms
  def calculate_released_weighted_median
    return calculate_released_assignments_median + calculate_released_gef_median
  end

  # Calculates the weighted median mark for all assignments
  def calculate_released_assignments_median
    weighted_median = 0
    assignments_mw = marking_weights.where(is_assignment: true)

    assignments_mw.each do |marking_weight|
      gradable_item = marking_weight.get_gradable_item
      if !gradable_item.results_median.nil?
        weighted_med = gradable_item.results_median * marking_weight.weight / 100
        weighted_median += weighted_med
      end
    end

    return weighted_median
  end

  # Calculates the weighted median mark for all grade entry forms
  def calculate_released_gef_median
    weighted_median = 0
    gefs_mw = marking_weights.where(is_assignment: false)

    gefs_mw.each do |marking_weight|
      gradable_item = marking_weight.get_gradable_item
      if !gradable_item.calculate_released_median.nil?
        weighted_med = gradable_item.calculate_released_median * marking_weight.weight / 100
        weighted_median += weighted_med
      end
    end

    return weighted_median
  end
end
