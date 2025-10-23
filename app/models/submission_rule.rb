class SubmissionRule < ApplicationRecord
  class InvalidRuleType < RuntimeError
    def initialize(rule_name)
      super(I18n.t('submission_rules.errors.not_valid_submission_rule', type: rule_name))
    end
  end

  belongs_to :assignment, inverse_of: :submission_rule, foreign_key: :assessment_id
  has_one :course, through: :assignment
  has_many :periods, dependent: :destroy, inverse_of: :submission_rule
  accepts_nested_attributes_for :periods, allow_destroy: true
  validates_associated :periods
  validates :assignment, uniqueness: true
  validates :penalty_type,
            inclusion: { in: [ExtraMark::PERCENTAGE, ExtraMark::POINTS, ExtraMark::PERCENTAGE_OF_MARK, nil] },
            allow_nil: true

  def self.descendants
    [NoLateSubmissionRule,
     PenaltyPeriodSubmissionRule,
     PenaltyDecayPeriodSubmissionRule,
     GracePeriodSubmissionRule]
  end

  def can_collect_all_now?
    return @can_collect_all_now unless @can_collect_all_now.nil?
    @can_collect_all_now = Time.current >= assignment.latest_due_date
  end

  def can_collect_grouping_now?(grouping)
    Time.current >= calculate_grouping_collection_time(grouping)
  end

  # Cache that allows us to quickly get collection time
  def get_collection_time(section = nil)
    if section.nil?
      return @get_global_collection_time unless @get_global_collection_time.nil?
      @get_global_collection_time = calculate_collection_time
    else
      reset_collection_time if @get_collection_time.nil?
      unless @get_collection_time[section.id].nil?
        return @get_collection_time[section.id]
      end
      @get_collection_time[section.id] = calculate_collection_time(section)
    end
  end

  def calculate_collection_time(section = nil)
    general_ddl = assignment.section_due_date(section) + hours_sum.hours
    if assignment.is_timed
      general_ddl + assignment.assignment_properties.duration
    else
      general_ddl
    end
  end

  # Return the time after which +grouping+ can be collected.
  # This is calculated by adding any penalty periods to this grouping's due date.
  #
  # If this grouping belongs to a timed_assignment and the student has not started
  # the assignment yet, the collection date it the due date without any additions.
  # This is because a student must start the assignment before the due date so their
  # (empty) submission can be collected as soon as the due date has passed if they have
  # not started.
  def calculate_grouping_collection_time(grouping)
    return grouping.due_date if assignment.is_timed && grouping.start_time.nil?

    add = grouping.extension.nil? || grouping.extension.apply_penalty ? hours_sum.hours : 0
    grouping.due_date + add
  end

  # When we're past the due date, the File Manager for the students will display
  # a message to tell them that they're currently past the due date.
  def overtime_message(grouping)
    raise NotImplementedError
  end

  # Takes a Submission (with an attached Result), and based on the properties of
  # this SubmissionRule, applies penalties to the Result - for example, will
  # add an ExtraMark of a negative value, or perhaps add the use of a Grace Day.
  def apply_submission_rule(submission)
    raise NotImplementedError
  end

  def reset_collection_time
    @get_collection_time = []
    @get_global_collection_time = nil
    @can_collect_all_now = nil
  end

  private

  # Over time hours could be a fraction. This is mostly used for testing
  def calculate_overtime_hours_from(from_time, grouping)
    overtime_hours = (from_time - grouping.due_date) / 1.hour
    # If the overtime is less than 0, that means it was submitted early, so
    # just return 0 - otherwise, return overtime_hours.
    [0, overtime_hours].max
  end

  def hours_sum
    0
  end
end
