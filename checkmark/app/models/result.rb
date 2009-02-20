class Result < ActiveRecord::Base
  belongs_to :submission
  has_many :marks
  has_many :extra_marks
  validates_presence_of :marking_state
  
  # calculate the total mark for this assignment
  def calculate_total
    marks = Mark.find_all_by_result_id(submission_id)
    extra_marks = ExtraMark.find_all_by_result_id(submission_id);
    total = 0;
    marks.each do |m|
     criterion = RubricCriteria.find(m.criterion.object_id)
     total = total + (criterion.weight * m.mark)
    end

    extra_marks.each do |em|
      total = total + em.mark
    end
  
    return total.to_f
  end
  
end
