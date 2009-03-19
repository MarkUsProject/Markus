class Result < ActiveRecord::Base
  belongs_to :submission
  has_many :marks
  has_many :extra_marks
  validates_presence_of :marking_state
  
  # calculate the total mark for this assignment
  def calculate_total
    total = get_subtotal
    extra_marks = ExtraMark.find_all_by_result_id(id);
    
    extra_marks.each do |em|
      total = total + em.mark
    end
    self.total_mark = total
    self.save
    return total
  end

  def get_subtotal
    marks = Mark.find_all_by_result_id(id)
    total = 0;
    marks.each do |m|
      total = total + m.get_mark
    end

    return total
  end
  
end
