class Result < ActiveRecord::Base

  MARKING_STATES = {
    :complete => 'complete',
    :partial => 'partial',
    :unmarked => 'unmarked'
  }
  
  belongs_to :submission
  has_many :marks
  has_many :extra_marks
  validates_presence_of :marking_state
  before_update  :unrelease_partial_results
  
  # calculate the total mark for this assignment
  def total_mark
    total = get_subtotal + get_total_extra_points
    # added_percentage
    percentage = get_total_extra_percentage   
    total = total + (percentage * total / 100)
    return total
  end

  #returns the sum of the marks not including bonuses/deductions
  def get_subtotal
    total = 0;
    marks.each do |m|
      total = total + m.get_mark
    end
    return total
  end

  #returns the sum of all the POSITIVE extra marks
  def get_positive_extra_points
    return extra_marks.positive_points.sum('extra_mark')
  end
  
  # Returns the sum of all the negative bonus marks
  def get_negative_extra_points
    return extra_marks.negative_points.sum('extra_mark')
  end
  
  def get_total_extra_points
    return get_positive_extra_points + get_negative_extra_points
  end
  
  def get_positive_extra_percentage
    return extra_marks.positive_percentage.sum('extra_mark')
  end
  
  def get_negative_extra_percentage
    return extra_marks.negative_percentage.sum('extra_mark')
  end

  def get_total_extra_percentage
    return get_positive_extra_percentage + get_negative_extra_percentage
  end
  
  # unrealses the results, and put the marking state to partial.
  def unrelease_results
    self.released_to_students = false
    self.marking_state = Result::MARKING_STATES[:partial]
    self.save
  end

  def mark_as_partial
    return if self.released_to_students == true
    self.marking_state = Result::MARKING_STATES[:partial]
    self.save
  end
  
  private
  # If this record is marked as "partial", ensure that its
  # "released_to_students" value is set to false.
  def unrelease_partial_results
    if marking_state != MARKING_STATES[:complete]
      self.released_to_students = false
    end
    return true
  end
  
  
end
