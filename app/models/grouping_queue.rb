#
# NOTE: This is not a Queue Data Structure
#
class GroupingQueue < ApplicationRecord
  belongs_to :submission_collector, dependent: :destroy
  has_many :groupings

  validates_inclusion_of :priority_queue, in: [true, false]
end
