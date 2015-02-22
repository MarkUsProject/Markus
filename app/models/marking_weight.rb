class MarkingWeight < ActiveRecord::Base
  attr_accessible :a_id, :marking_scheme_id, :weight
  belongs_to :marking_scheme
end
