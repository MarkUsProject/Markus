class ExtraMark < ActiveRecord::Base
  # When a mark is created, or updated, we need to make sure that that
  # Result that it belongs to has a marking_state of "partial".
  UNITS = {
    :percentage => 'percentage',
    :points => 'points'
  }

  scope :points, :conditions => {:unit => ExtraMark::UNITS[:points]}
  scope :percentage, :conditions => {:unit => ExtraMark::UNITS[:percentage]}

  scope :positive, :conditions => ['extra_mark > 0']
  scope :negative, :conditions => ['extra_mark < 0']

  before_save :ensure_not_released_to_students
  before_update :ensure_not_released_to_students

  belongs_to :result
  validates_presence_of :unit
  validates_format_of   :unit,          :with => /percentage|points/
  validates_presence_of :result_id
  validates_numericality_of :extra_mark, :message => 'Mark must be an number'
  validates_numericality_of :result_id, :only_integer => true, :greater_than => 0, :message => 'result_id must be an id that is an integer greater than 0'

  def ensure_not_released_to_students
    !result.released_to_students
  end
end
