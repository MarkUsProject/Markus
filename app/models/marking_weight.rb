class MarkingWeight < ActiveRecord::Base
  belongs_to :marking_scheme

  def get_gradable_item
    if self.is_assignment
      gradable_item = Assignment.where(id: gradable_item_id).first
    else
      gradable_item = GradeEntryForm.where(id: gradable_item_id).first
    end
    return gradable_item
  end

  def get_weight
    return weight
  end
end
