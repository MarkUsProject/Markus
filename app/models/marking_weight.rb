class MarkingWeight < ActiveRecord::Base
  attr_accessible :gradable_item_id, :marking_scheme_id, :weight, :is_assignment
  belongs_to :marking_scheme
end
