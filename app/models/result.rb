class Result < ActiveRecord::Base

  MARKING_STATES = {
    complete: 'complete',
    partial: 'partial',
    unmarked: 'unmarked'
  }

  belongs_to :submission
  has_many :marks
  has_many :extra_marks

  validates_presence_of :marking_state
  validates_inclusion_of :marking_state, in: MARKING_STATES.values

  validates_numericality_of :total_mark, greater_than_or_equal_to: 0

  before_update :unrelease_partial_results

  before_save :check_for_nil_marks

  # Returns a list of total marks for each student whose submissions are graded
  # for the assignment specified by +assignment_id+, sorted in ascending order.
  # This includes duplicated marks for each student in the same group (marks
  # are given for a group, so each student in the same group gets the same
  # mark).
  def self.student_marks_by_assignment(assignment_id)
    # Need to get a list of total marks of students' latest results (i.e., not
    # including old results after having remarked results). This is a typical
    # greatest-n-per-group problem and can be implemented using a subquery
    # join.
    subquery = Result.select('max(results.id) max_id')
      .joins(submission: {grouping: {student_memberships: :user}})
      .where(groupings: {assignment_id: assignment_id},
             users: {hidden: false},
             submissions: {submission_version_used: true},
             marking_state: Result::MARKING_STATES[:complete])
      .group('users.id')
    Result.joins("JOIN (#{subquery.to_sql}) s ON id = s.max_id")
      .order(:total_mark).pluck(:total_mark)
  end

  # calculate the total mark for this assignment
  def update_total_mark
    total = get_subtotal + get_total_extra_points
    # added_percentage
    percentage = get_total_extra_percentage
    total = total + (percentage * submission.assignment.total_mark / 100)
    self.total_mark = total
    self.save
  end

  #returns the sum of the marks not including bonuses/deductions
  def get_subtotal
    total = 0.0
    self.marks.all(include: [:markable]).each do |m|
      total = total + m.get_mark
    end
    total
  end

  #returns the sum of all the POSITIVE extra marks
  def get_positive_extra_points
    extra_marks.positive.points.sum('extra_mark')
  end

  # Returns the sum of all the negative bonus marks
  def get_negative_extra_points
    extra_marks.negative.points.sum('extra_mark')
  end

  def get_total_extra_points
    return 0.0 if extra_marks.empty?
    get_positive_extra_points + get_negative_extra_points
  end

  def get_positive_extra_percentage
    extra_marks.positive.percentage.sum('extra_mark')
  end

  def get_negative_extra_percentage
    extra_marks.negative.percentage.sum('extra_mark')
  end

  def get_total_extra_percentage
    return 0.0 if extra_marks.empty?
    get_positive_extra_percentage + get_negative_extra_percentage
  end

  def get_total_extra_percentage_as_points
    get_total_extra_percentage * submission.assignment.total_mark / 100
  end

  # un-releases the result
  def unrelease_results
    self.released_to_students = false
    self.save
  end

  def mark_as_partial
    return if self.released_to_students
    self.marking_state = Result::MARKING_STATES[:partial]
    self.save
  end

  private
  # If this record is marked as "partial", ensure that its
  # "released_to_students" value is set to false.
  def unrelease_partial_results
    if marking_state != MARKING_STATES[:complete]
      self.released_to_students = false
    end
    true
  end

  def check_for_nil_marks
    # Check that the marking state is not no mark is nil or
    if marks.where(mark: nil).first &&
          marking_state == Result::MARKING_STATES[:complete]
      errors.add(:base, I18n.t('common.criterion_incomplete_error'))
      return false
    end
    true
  end
end
