class Result < ApplicationRecord

  MARKING_STATES = {
    complete: 'complete',
    incomplete: 'incomplete'
  }

  belongs_to :submission
  has_one :grouping, through: :submission
  has_many :marks, dependent: :destroy
  has_many :extra_marks, dependent: :destroy
  has_many :annotations, dependent: :destroy
  has_many :peer_reviews, dependent: :destroy

  after_create :create_marks
  validates_presence_of :marking_state
  validates_inclusion_of :marking_state, in: MARKING_STATES.values

  validates_numericality_of :total_mark, greater_than_or_equal_to: 0

  before_update :unrelease_partial_results
  before_save :check_for_nil_marks

  scope :submitted_remarks_and_all_non_remarks, lambda {
    results = Result.arel_table
    where(results[:remark_request_submitted_at].eq(nil))
  }

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

  # Update the total mark attribute
  #
  # If the +assignment+ value is nil, the assignment will be determined dynamically.
  # However, passing the +assignment+ value explicitly is more efficient if we are
  # updating multiple total marks for a single assignment since it allows for
  # caching of criteria.
  # Warning: this does not check if the +assignment+ passed as an argument is actually
  # the one associate with this result.
  def update_total_mark(assignment: nil)
    update(total_mark: get_total_mark(assignment: assignment))
  end

  # Calculate the total mark for this submission
  #
  # See the documentation for update_total_mark for information about when to explicitly
  # pass the +assignment+ variable and associated warnings.
  def get_total_mark(assignment: nil)
    user_visibility = is_a_review? ? :peer : :ta
    subtotal = get_subtotal(assignment: assignment)
    extra_marks = get_total_extra_marks(user_visibility: user_visibility)
    [0, subtotal + extra_marks].max
  end

  # The sum of the marks not including bonuses/deductions
  #
  # See the documentation for update_total_mark for information about when to explicitly
  # pass the +assignment+ variable and associated warnings.
  def get_subtotal(assignment: nil)
    if marks.empty?
      0
    else
      assignment ||= submission.grouping.assignment
      if is_a_review?
        user_visibility = :peer
        assignment = assignment.pr_assignment
      else
        user_visibility = :ta
      end
      criteria = assignment.get_criteria(user_visibility).map { |c| [c.class.to_s, c.id] }
      marks_array = (marks.to_a.select { |m| criteria.member? [m.markable_type, m.markable_id] }).map &:mark
      # TODO: sum method does not work with empty arrays or with arrays containing nil values.
      #       Consider updating/replacing gem:
      #       see: https://github.com/thirtysixthspan/descriptive_statistics/issues/44
      marks_array.map! { |m| m ? m : 0 }
      marks_array.empty? ? 0 : marks_array.sum
    end
  end

  # The sum of the bonuses deductions and late penalties
  #
  # If the +max_mark+ value is nil, its value will be determined dynamically
  # based on the max_mark value of the associated assignment.
  # However, passing the +max_mark+ value explicitly is more efficient if we are
  # repeatedly calling this method where the max_mark doesn't change, such as when
  # all the results are associated with the same assignment.
  #
  # +user_visibility+ is passed to the Assignment.max_mark method to determine the
  # max_mark value only if the +max_mark+ argument is nil.
  def get_total_extra_marks(max_mark: nil, user_visibility: :ta)
    Result.get_total_extra_marks(id, max_mark: max_mark, user_visibility: user_visibility)[id] || 0
  end

  # The sum of the bonuses deductions and late penalties for multiple results.
  # This returns a hash mapping the result ids from the +result_ids+ argument to
  # the sum of all extra marks calculated for that result.
  #
  # If the +max_mark+ value is nil, its value will be determined dynamically
  # based on the max_mark value of the associated assignment.
  # However, passing the +max_mark+ value explicitly is more efficient if we are
  # repeatedly calling this method where the max_mark doesn't change, such as when
  # all the results are associated with the same assignment.
  #
  # +user_visibility+ is passed to the Assignment.max_mark method to determine the
  # max_mark value only if the +max_mark+ argument is nil.
  def self.get_total_extra_marks(result_ids, max_mark: nil, user_visibility: :ta)
    result_data = Result.joins(:extra_marks, submission: [grouping: :assignment])
                        .where(id: result_ids)
                        .pluck(:id, :extra_mark, :unit, 'assignments.id')
    extra_marks_hash = Hash.new { |h,k| h[k] = 0 }
    max_mark_hash = Hash.new
    result_data.each do |id, extra_mark, unit, assignment_id|
      if unit == 'points'
        extra_marks_hash[id] += extra_mark.round(1)
      elsif unit == 'percentage'
        if max_mark
          assignment_max_mark = max_mark
        else
          max_mark_hash[assignment_id] ||= Assignment.find(assignment_id)&.max_mark(user_visibility)
          assignment_max_mark = max_mark_hash[assignment_id]
        end
        max_mark = max_mark_hash[assignment_id]
        extra_marks_hash[id] = (extra_mark * assignment_max_mark / 100).round(1)
      end
    end
    extra_marks_hash
  end

  # The sum of the bonuses and deductions, other than late penalty
  def get_total_extra_points
    extra_marks.points.map(&:extra_mark).reduce(0, :+).round(1)
  end

  # The sum of all the positive extra marks
  def get_positive_extra_points
    extra_marks.positive.points.map(&:extra_mark).reduce(0, :+).round(1)
  end

  # The sum of all the negative extra marks
  def get_negative_extra_points
    extra_marks.negative.points.map(&:extra_mark).reduce(0, :+).round(1)
  end

  # Percentage deduction for late penalty
  def get_total_extra_percentage
    extra_marks.percentage.map(&:extra_mark).reduce(0, :+).round(1)
  end

  # Point deduction for late penalty
  def get_total_extra_percentage_as_points(user_visibility = :ta)
    (get_total_extra_percentage * submission.assignment.max_mark(user_visibility) / 100).round(1)
  end

  # un-releases the result
  def unrelease_results
    self.released_to_students = false
    self.save
  end

  def mark_as_partial
    return if self.released_to_students
    self.marking_state = Result::MARKING_STATES[:incomplete]
    self.save
  end

  def is_a_review?
    !peer_review_id.nil?
  end

  def is_review_for?(user, assignment)
    grouping = user.grouping_for(assignment.id)
    pr = PeerReview.find_by(result_id: self.id)
    !pr.nil? && submission.grouping == grouping
  end

  def create_marks
    assignment = self.submission.assignment
    assignment.get_criteria(:ta).each do |criterion|
      criterion.marks.find_or_create_by(result_id: id)
    end
    self.update_total_mark
  end

  # Returns a hash of all marks for this result.
  # TODO: make it include extra marks as well.
  def mark_hash
    Hash[
      marks.map do |mark|
        ["criterion_#{mark.markable_type}_#{mark.markable_id}",
         mark.mark]
      end
    ]
  end

  private
  # If this record is marked as "partial", ensure that its
  # "released_to_students" value is set to false.
  def unrelease_partial_results
    unless is_a_review?
      if marking_state != MARKING_STATES[:complete]
        self.released_to_students = false
      end
    end
    true
  end

  def check_for_nil_marks(user_visibility = :ta)
    # This check is only required when the marking state is complete.
    return true unless marking_state == Result::MARKING_STATES[:complete]

    # peer review result is a special case because when saving a pr result
    # we can't pass in a parameter to the before_save filter, so we need
    # to manually determine the visibility. If it's a pr result, we know we
    # want the peer-visible criteria
    visibility = is_a_review? ? :peer : user_visibility

    criteria = submission.assignment.get_criteria(visibility).map { |c| [c.class.to_s, c.id] }
    nil_marks = false
    num_marks = 0
    marks.each do |mark|
      if criteria.member? [mark.markable_type, mark.markable_id]
        num_marks += 1
        if mark.mark.nil?
          nil_marks = true
          break
        end
      end
    end

    if nil_marks || num_marks < criteria.count
      errors.add(:base, I18n.t('results.criterion_incomplete_error'))
      throw(:abort)
    end
    true
  end
end
