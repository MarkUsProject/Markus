class MarkingWeight < ActiveRecord::Base
  belongs_to :marking_scheme

  def get_gradable_item
    if self.is_assignment
      Assignment.find(gradable_item_id)
    else
      GradeEntryForm.find(gradable_item_id)
    end
  end
end
