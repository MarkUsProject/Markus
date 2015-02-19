class MarkingWeight < ActiveRecord::Base
  attr_accessible :a_id, :ms_id, :weight
  belongs_to :marking_scheme
end
