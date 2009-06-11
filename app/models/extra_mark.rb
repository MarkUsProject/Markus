class ExtraMark < ActiveRecord::Base
  # When a mark is created, or updated, we need to make sure that that
  # Result that it belongs to has a marking_state of "partial".
  after_save :ensure_result_marking_state_partial
  after_update :ensure_result_marking_state_partial
  belongs_to :result
  validates_presence_of :result_id
  validates_numericality_of :extra_mark, :message => "Mark must be an number"
  validates_numericality_of :result_id, :only_integer => true, :greater_than => 0, :message => "result_id must be an id that is an integer greater than 0"
  
  def ensure_result_marking_state_partial
    if result.marking_state != Result::MARKING_STATES[:partial]
      result.marking_state = Result::MARKING_STATES[:partial]
      result.save
      
    end
  end
end
