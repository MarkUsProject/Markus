class SubmissionRule < ApplicationRecord

  class InvalidRuleType < Exception
    def initialize(rule_name)
      super I18n.t('submission_rules.errors.not_valid_submission_rule', type: rule_name)
    end
  end

  belongs_to :assignment, inverse_of: :submission_rule
  has_many :periods, -> { order('id') }, dependent: :destroy
  accepts_nested_attributes_for :periods, allow_destroy: true

  def self.descendants
    [NoLateSubmissionRule,
     PenaltyPeriodSubmissionRule,
     PenaltyDecayPeriodSubmissionRule,
     GracePeriodSubmissionRule]
  end

  def can_collect_now?(section = nil)
    reset_collection_time if @can_collect_now.nil?
    section_id = section.nil? ? 0 : section.id
    return @can_collect_now[section_id] unless @can_collect_now[section_id].nil?
    @can_collect_now[section_id] = Time.zone.now >= get_collection_time(section)
  end

  def can_collect_all_now?
    return @can_collect_all_now unless @can_collect_all_now.nil?
    @can_collect_all_now = Time.zone.now >= assignment.latest_due_date
  end

  def can_collect_grouping_now?(grouping)
    Time.zone.now >= calculate_grouping_collection_time(grouping)
  end

  # Cache that allows us to quickly get collection time
  def get_collection_time(section=nil)
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

  def calculate_collection_time(section=nil)
    assignment.section_due_date(section) + hours_sum.hours
  end

  def calculate_grouping_collection_time(grouping)
    if !grouping.inviter.nil? && grouping.inviter.section
      SectionDueDate.due_date_for(grouping.inviter.section,
                                         assignment)
    else
      assignment.due_date + hours_sum.hours
    end
  end

  # When we're past the due date, the File Manager for the students will display
  # a message to tell them that they're currently past the due date.
  def overtime_message
    raise NotImplementedError.new('SubmissionRule: overtime_message not implemented')
  end

  # Returns true or false based on whether the attached Assignment's properties
  # will work with this particular SubmissionRule
  def assignment_valid?
    raise NotImplementedError.new('SubmissionRule: assignment_valid? not implemented')
  end

  # Takes a Submission (with an attached Result), and based on the properties of
  # this SubmissionRule, applies penalties to the Result - for example, will
  # add an ExtraMark of a negative value, or perhaps add the use of a Grace Day.
  def apply_submission_rule(submission)
    raise NotImplementedError.new('SubmissionRule:  apply_submission_rule not implemented')
  end

  def grader_tab_partial(grouping)
    raise NotImplementedError.new('SubmissionRule:  render_grader_tab not implemented')
  end

  def reset_collection_time
    @get_collection_time = Array.new
    @get_global_collection_time = nil
    @can_collect_now = Array.new
    @can_collect_all_now = nil
  end

  private

  # Over time hours could be a fraction. This is mostly used for testing
  def calculate_overtime_hours_from(from_time, section)
    overtime_hours = (from_time - assignment.section_due_date(section)) / 1.hour
    # If the overtime is less than 0, that means it was submitted early, so
    # just return 0 - otherwise, return overtime_hours.
    [0, overtime_hours].max
  end

  def hours_sum
    0
  end

end
