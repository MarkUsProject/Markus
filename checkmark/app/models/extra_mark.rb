class ExtraMark < ActiveRecord::Base
  belongs_to :result
  validates_presence_of :result_id
  validates_numericality_of :mark, :message => "Mark must be an number"
  validates_numericality_of :result_id, :only_integer => true, :greater_than => 0, :message => "result_id must be an id that is an integer greater than 0"
end
