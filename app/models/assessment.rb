# Assessment is an abstract model used for single-table-inheritance with Assignment and GradeEntryForm
# It can represent any form of graded work (assignment, test, lab, exam...etc.)
class Assessment < ApplicationRecord
  scope :assignments, -> { where(type: 'Assignment') }
  scope :grade_entry_forms, -> { where(type: 'GradeEntryForm') }

  has_many :marking_weights, dependent: :destroy

  # Call custom validator in order to validate the :due_date attribute
  # date: true maps to DateValidator (custom_name: true maps to CustomNameValidator)
  # Look in lib/validators/* for more info
  validates :due_date, date: true

  validates_uniqueness_of :short_identifier, case_sensitive: true
  validates_presence_of :short_identifier
  validate :short_identifier_unchanged, on: :update
  validates_presence_of :description
  validates_inclusion_of :is_hidden, in: [true, false]
  validates_presence_of :notes_count

  def self.type
    %w[Assignment GradeEntryForm]
  end

  def short_identifier_unchanged
    return unless short_identifier_changed?
    errors.add(:short_id_change, 'short identifier should not be changed once an assessment has been created')
    false
  end

  def upcoming(*)
    return true if self.due_date.nil?
    self.due_date > Time.current
  end
end
