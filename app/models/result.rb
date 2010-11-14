class Result < ActiveRecord::Base

  MARKING_STATES = {
    :complete => 'complete',
    :partial => 'partial',
    :unmarked => 'unmarked'
  }

  belongs_to :submission
  has_many :marks
  has_many :extra_marks
  has_one :remarked_submission, :foreign_key => :remark_result_id

  validates_presence_of :marking_state
  validates_inclusion_of :marking_state, :in => [Result::MARKING_STATES[:complete],
    Result::MARKING_STATES[:partial],   Result::MARKING_STATES[:unmarked]]
  validates_numericality_of :total_mark, :greater_than_or_equal_to => 0
  before_update  :unrelease_partial_results

  # calculate the total mark for this assignment
  def update_total_mark
    total = get_subtotal + get_total_extra_points
    # added_percentage
    percentage = get_total_extra_percentage   
    total = total + (percentage * submission.assignment.total_mark / 100)
    self.total_mark = total
    self.save
  end

  #returns the sum of the marks not including bonuses/deductions
  def get_subtotal
    total = 0.0
    self.marks.find(:all, :include => [:markable]).each do |m|
      total = total + m.get_mark
    end
    return total
  end

  #returns the sum of all the POSITIVE extra marks
  def get_positive_extra_points
    return extra_marks.positive.points.sum('extra_mark')
  end
  
  # Returns the sum of all the negative bonus marks
  def get_negative_extra_points
    return extra_marks.negative.points.sum('extra_mark')
  end
  
  def get_total_extra_points
    return 0.0 if extra_marks.empty?
    return get_positive_extra_points + get_negative_extra_points
  end
  
  def get_positive_extra_percentage
    return extra_marks.positive.percentage.sum('extra_mark')
  end
  
  def get_negative_extra_percentage
    return extra_marks.negative.percentage.sum('extra_mark')
  end

  def get_total_extra_percentage
    return 0.0 if extra_marks.empty?    
    return get_positive_extra_percentage + get_negative_extra_percentage
  end
  
  def get_total_extra_percentage_as_points
    return (get_total_extra_percentage * submission.assignment.total_mark / 100)
  end
  
  # un-releases the result
  def unrelease_results
    self.released_to_students = false
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
