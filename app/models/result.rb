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

  has_one :course, through: :submission

  after_create :create_marks
  validates_presence_of :marking_state
  validates_inclusion_of :marking_state, in: MARKING_STATES.values

  validates_numericality_of :total_mark, greater_than_or_equal_to: 0

  validates_inclusion_of :released_to_students, in: [true, false]

  before_update :check_for_released
  before_save :check_for_nil_marks

  # Update the total mark attribute
  def update_total_mark
    update(total_mark: get_total_mark)
  end

  # Update the total_mark attributes for the results with id in +result_ids+
  def self.update_total_marks(result_ids, user_visibility: :ta_visible)
    total_marks = Result.get_total_marks(result_ids, user_visibility: user_visibility)
    unless total_marks.empty?
      Result.upsert_all(total_marks.map { |r_id, total_mark| { id: r_id, total_mark: total_mark } })
    end
  end

  # Calculate the total mark for this submission
  def get_total_mark
    user_visibility = is_a_review? ? :peer_visible : :ta_visible
    Result.get_total_marks([self.id], user_visibility: user_visibility)[self.id]
  end

  # Return a hash mapping each id in +result_ids+ to the total mark for the result with that id.
  def self.get_total_marks(result_ids, user_visibility: :ta_visible)
    subtotals = Result.get_subtotals(result_ids, user_visibility: user_visibility)
    extra_marks = Result.get_total_extra_marks(result_ids, user_visibility: user_visibility)
    subtotals.map { |r_id, subtotal| [r_id, [0, (subtotal || 0) + (extra_marks[r_id] || 0)].max] }.to_h
  end

  # The sum of the marks not including bonuses/deductions
  def get_subtotal
    if is_a_review?
      user_visibility = :peer_visible
    else
      user_visibility = :ta_visible
    end
    Result.get_subtotals([self.id], user_visibility: user_visibility)[self.id]
  end

  def self.get_subtotals(result_ids, user_visibility: :ta_visible)
    marks = Mark.joins(:criterion)
                .where(result_id: result_ids)
                .where("criteria.#{user_visibility}": true)
                .group(:result_id)
                .sum(:mark)
    result_ids.map { |r_id| [r_id, marks[r_id] || 0] }.to_h
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
  def get_total_extra_marks(max_mark: nil, user_visibility: :ta_visible)
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
  def self.get_total_extra_marks(result_ids, max_mark: nil, user_visibility: :ta_visible)
    result_data = Result.joins(:extra_marks, submission: [grouping: :assignment])
                        .where(id: result_ids)
                        .pluck(:id, :extra_mark, :unit, 'assessments.id')
    extra_marks_hash = Hash.new { |h, k| h[k] = nil }
    max_mark_hash = Hash.new
    result_data.each do |id, extra_mark, unit, assessment_id|
      if extra_marks_hash[id].nil?
        extra_marks_hash[id] = 0
      end
      if unit == 'points'
        extra_marks_hash[id] += extra_mark.round(2)
      elsif unit == 'percentage'
        if max_mark
          assignment_max_mark = max_mark
        else
          max_mark_hash[assessment_id] ||= Assignment.find(assessment_id)&.max_mark(user_visibility)
          assignment_max_mark = max_mark_hash[assessment_id]
        end
        max_mark = max_mark_hash[assessment_id]
        extra_marks_hash[id] += (extra_mark * assignment_max_mark / 100).round(2)
      end
    end
    extra_marks_hash
  end

  # The sum of the bonuses and deductions, other than late penalty
  def get_total_extra_points
    extra_marks.points.map(&:extra_mark).reduce(0, :+).round(2)
  end

  # Percentage deduction for late penalty
  def get_total_extra_percentage
    extra_marks.percentage.map(&:extra_mark).reduce(0, :+).round(2)
  end

  # Point deduction for late penalty
  def get_total_extra_percentage_as_points(user_visibility = :ta_visible)
    (get_total_extra_percentage * submission.assignment.max_mark(user_visibility) / 100).round(2)
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
    assignment.ta_criteria.each do |criterion|
      criterion.marks.find_or_create_by(result_id: id)
    end
    self.update_total_mark
  end

  # Returns a hash of all marks for this result.
  # TODO: make it include extra marks as well.
  def mark_hash
    Hash[
      marks.map do |mark|
        [mark.criterion_id, mark.mark]
      end
    ]
  end

  private

  # Do not allow the marking state to be changed to incomplete if the result is released
  def check_for_released
    if released_to_students && marking_state_changed?(to: Result::MARKING_STATES[:incomplete])
      errors.add(:base, I18n.t('results.marks_released'))
      throw(:abort)
    end
    true
  end

  def check_for_nil_marks(user_visibility = :ta_visible)
    # This check is only required when the marking state is complete.
    return true unless marking_state == Result::MARKING_STATES[:complete]

    # peer review result is a special case because when saving a pr result
    # we can't pass in a parameter to the before_save filter, so we need
    # to manually determine the visibility. If it's a pr result, we know we
    # want the peer-visible criteria
    visibility = is_a_review? ? :peer_visible : user_visibility

    criteria = submission.assignment.criteria.where(visibility => true).ids
    nil_marks = false
    num_marks = 0
    marks.each do |mark|
      if criteria.member? mark.criterion_id
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
