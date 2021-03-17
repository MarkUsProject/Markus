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

  # Returns a list of total marks for each student whose submissions are graded
  # for the assignment specified by +assessment_id+, sorted in ascending order.
  # This includes duplicated marks for each student in the same group (marks
  # are given for a group, so each student in the same group gets the same
  # mark).
  def student_marks_by_assignment
    # Need to get a list of total marks of students' latest results (i.e., not
    # including old results after having remarked results). This is a typical
    # greatest-n-per-group problem and can be implemented using a subquery
    # join.
    if defined? @marks_by_assignment
      return @marks_by_assignment
    end

    subquery = Result.select('max(results.id) max_id')
                     .joins(submission: { grouping: { student_memberships: :user } })
                     .where(groupings: { assessment_id: self.id },
                            users: { hidden: false },
                            submissions: { submission_version_used: true },
                            marking_state: Result::MARKING_STATES[:complete])
                     .group('users.id')
    marks = Result.joins("JOIN (#{subquery.to_sql}) s ON id = s.max_id")
                  .order(:total_mark).pluck(:total_mark)
    @marks_by_assignment = marks
    marks

  end

  def results_fails
    marks = student_marks_by_assignment
    # No marks released for this assignment.
    return false if marks.empty?
    marks.count { |mark| mark < max_mark / 2.0 }
  end

  def results_zeros
    marks = student_marks_by_assignment
    # No marks released for this assignment.
    return false if marks.empty?
    marks.count(&:zero?)
  end
end
