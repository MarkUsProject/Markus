# The abstract base class that defines common behavior for all types of
# criterion.
class Criterion < ApplicationRecord
  belongs_to :assignment, foreign_key: :assessment_id, inverse_of: :criteria
  before_validation :update_assigned_groups_count
  after_create :update_result_marking_states
  after_update :update_results_with_change

  has_one :course, through: :assignment

  has_many :marks, dependent: :destroy
  accepts_nested_attributes_for :marks

  validates :assigned_groups_count, presence: true
  validates :assigned_groups_count, numericality: true

  has_many :criterion_ta_associations, dependent: :destroy
  has_many :tas, through: :criterion_ta_associations
  has_many :test_groups

  validates :name, presence: true
  validates :name, uniqueness: { scope: :assessment_id }

  validates :bonus, inclusion: { in: [true, false] }

  validates :max_mark, presence: true
  validates :max_mark, numericality: { greater_than: 0 }

  has_many :criteria_assignment_files_joins,
           dependent: :destroy
  has_many :assignment_files,
           through: :criteria_assignment_files_joins
  accepts_nested_attributes_for :criteria_assignment_files_joins, allow_destroy: true

  validate :results_unreleased?
  validate :visible?

  has_many :levels, -> { order(:mark) }, inverse_of: :criterion, dependent: :destroy, autosave: true
  accepts_nested_attributes_for :levels, allow_destroy: true

  def update_assigned_groups_count
    result = criterion_ta_associations.flat_map do |cta|
      cta.ta.get_groupings_by_assignment(assignment)
    end
    self.assigned_groups_count = result.uniq.length
  end

  # Assigns a random TA from a list of TAs specified by +ta_ids+ to each
  # criterion in a list of criteria specified by +criterion_ids+. The criteria
  # must belong to the given assignment +assignment+.
  def self.randomly_assign_tas(criterion_ids, ta_ids, assignment)
    assign_tas(criterion_ids, ta_ids, assignment) do |c_ids, t_ids|
      # Assign TAs in a round-robin fashion to a list of random criteria.
      shuffled_criterion_ids = c_ids.shuffle
      shuffled_criterion_ids.zip(t_ids.cycle).map(&:flatten)
    end
  end

  # Assigns all TAs in a list of TAs specified by +ta_ids+ to each criterion in
  # a list of criteria specified by +criterion_ids+. The criteria must belong
  # to the given assignment +assignment+.
  def self.assign_all_tas(criterion_ids, ta_ids, assignment)
    assign_tas(criterion_ids, ta_ids, assignment) do |c_ids, t_ids|
      c_ids.product(t_ids)
    end
  end

  # Assigns TAs to criteria using a caller-specified block. The block is given
  # a list of criterion IDs and a list of TA IDs and must return a list of
  # criterion-ID-TA-ID pair that represents the TA assignment.
  #
  #   # Assign the TA with ID 3 to the criterion with ID 1 and the TA
  #   # with ID 4 to the criterion with ID 2.
  #   assign_tas([1, 2], [3, 4], a) do |criterion_ids, ta_ids|
  #     criterion_ids.zip(ta_ids)  # => [[1, 3], [2, 4]]
  #   end
  #
  # The criteria must belong to the given assignment +assignment+.
  def self.assign_tas(criterion_ids, ta_ids, assignment)
    ta_ids = Array(ta_ids)

    # Only use IDs that identify existing model instances.
    ta_ids = Ta.where(id: ta_ids).ids
    # Get all existing criterion-TA associations to avoid violating the unique
    # constraint.
    existing_values = CriterionTaAssociation
                      .where(criterion_id: criterion_ids,
                             ta_id: ta_ids)
                      .pluck(:criterion_id, :ta_id)

    # Delegate the assign function to the caller-specified block and remove
    # values that already exist in the database.
    new_values = yield(criterion_ids, ta_ids)
    values = new_values - existing_values

    mappings = values.map { |value| { criterion_id: value[0], ta_id: value[1], assessment_id: assignment.id } }
    CriterionTaAssociation.insert_all(mappings) unless mappings.empty?

    Grouping.update_criteria_coverage_counts(assignment)
    update_assigned_groups_counts(assignment)
  end

  # Unassigns TAs from groupings. +criterion_ta_ids+ is a list of TA
  # membership IDs that specifies the unassignment to be done. The memberships
  # and groupings must belong to the given assignment +assignment+.
  def self.unassign_tas(criterion_ta_ids, assignment)
    CriterionTaAssociation.where(id: criterion_ta_ids).delete_all

    Grouping.update_criteria_coverage_counts(assignment)
    update_assigned_groups_counts(assignment)
  end

  # Updates the +assigned_groups_count+ field of all criteria that belong to
  # an assignment with ID +assignment_id+.
  def self.update_assigned_groups_counts(assignment)
    counts = CriterionTaAssociation
             .from(
               # subquery
               assignment.criterion_ta_associations
                         .joins(ta: :groupings)
                         .where('groupings.assessment_id': assignment.id)
                         .select('criterion_ta_associations.criterion_id',
                                 'groupings.id')
                         .distinct
             )
             .group('subquery.criterion_id')
             .count

    records = assignment.criteria
                        .pluck_to_hash
                        .map do |h|
      { **h.symbolize_keys, assigned_groups_count: counts[h['id']] || 0 }
    end

    Criterion.upsert_all(records) unless records.empty?
  end

  def update_results_with_change
    max_mark_changed = previous_changes.key?('max_mark') && !previous_changes[:max_mark].first.nil?
    return unless max_mark_changed || previous_changes.key?('bonus')
    scale_marks if max_mark_changed
  end

  # When max_mark of criterion is changed, all associated marks should have their mark value scaled to the change.
  def scale_marks
    max_mark_was = previous_changes[:max_mark].first
    # results with specific assignment
    results = Result.includes(submission: :grouping)
                    .where(groupings: { assessment_id: assessment_id })
    all_marks = marks.where.not(mark: nil).where(result_id: results.ids)
    # all associated marks should have their mark value scaled to the change.
    updated_marks = {}
    all_marks.each do |mark|
      updated_marks[mark.id] = mark.scale_mark(max_mark, max_mark_was, update: false)
    end
    unless updated_marks.empty?
      Mark.upsert_all(all_marks.pluck_to_hash.map { |h| { **h.symbolize_keys, mark: updated_marks[h['id'].to_i] } })
    end
  end

  def results_unreleased?
    return true if self.assignment&.released_marks.blank?

    errors.add(:base, :cannot_update_criterion)
    false
  end

  # Returns an array of all marks for this criteria that are not nil and are for a completed submission
  def grades_array
    return @grades_array if defined? @grades_array
    results = self.assignment.current_results
                  .where(marking_state: Result::MARKING_STATES[:complete])
    @grades_array = self.marks.where.not(mark: nil).where(result_id: results.ids).pluck(:mark)
  end

  def grade_distribution_array(intervals = 20)
    data = grades_array.map { |mark| mark / self.max_mark * 100 }
    data.extend(Histogram)
    histogram = data.histogram(intervals, min: 1, max: 100, bin_boundary: :min, bin_width: 100 / intervals)
    distribution = histogram.fetch(1)
    distribution[0] = distribution.first + data.count { |x| x < 1 }
    distribution[-1] = distribution.last + data.count { |x| x > 100 }

    distribution
  end

  # Returns the raw average grade of marks given for this criteria based on the marks given by self.grades_array
  def average
    return 0 if self.max_mark.zero?

    marks = grades_array
    marks.empty? ? 0 : DescriptiveStatistics.mean(marks)
  end

  # Returns the raw median grade of marks given for this criteria based on the marks given by self.grades_array
  def median
    return 0 if self.max_mark.zero?

    marks = grades_array
    marks.empty? ? 0 : DescriptiveStatistics.median(marks)
  end

  # Returns the raw standard deviation of marks given for this criteria based on the marks given by self.grades_array
  def standard_deviation
    return 0 if self.max_mark.zero?

    marks = grades_array
    marks.empty? ? 0 : DescriptiveStatistics.standard_deviation(marks)
  end

  # Configures +assignment+ with the uploaded criteria +data+
  # Returns the number of successful criteria uploaded
  def self.upload_criteria_from_yaml(assignment, data)
    assignment.criteria.destroy_all

    # Create criteria based on the parsed data.
    successes = 0
    pos = 1
    crit_format_errors = []
    data.each do |criterion_yml|
      type = criterion_yml[1]['type']
      begin
        if type&.casecmp('rubric') == 0
          criterion = RubricCriterion.load_from_yml(criterion_yml)
        elsif type&.casecmp('flexible') == 0
          criterion = FlexibleCriterion.load_from_yml(criterion_yml)
        elsif type&.casecmp('checkbox') == 0
          criterion = CheckboxCriterion.load_from_yml(criterion_yml)
        else
          raise RuntimeError
        end

        criterion.assessment_id = assignment.id
        criterion.position = pos
        criterion.save!
        pos += 1
        successes += 1
      rescue ActiveRecord::RecordInvalid, RuntimeError # E.g., both visibility options are false.
        crit_format_errors << criterion_yml[0]
      end
    end
    unless crit_format_errors.empty?
      raise "#{I18n.t('criteria.errors.invalid_format')} #{crit_format_errors.join(', ')}"
    end
    self.reset_marking_states(assignment.id)
    successes
  end

  # Resets the marking state for all results for the given assignment with id +assessment_id+.
  def self.reset_marking_states(assessment_id)
    Result.joins(submission: :grouping)
          .where('submissions.submission_version_used': true, 'groupings.assessment_id': assessment_id)
          .find_each do |result|
      result.update(marking_state: Result::MARKING_STATES[:incomplete])
    end
  end

  private

  # Checks if the criterion is visible to either the ta or the peer reviewer.
  def visible?
    if ta_visible || peer_visible
      true
    else
      errors.add(:base, I18n.t('activerecord.errors.models.criterion.visibility_error'))
      false
    end
  end

  def update_result_marking_states
    UpdateResultsMarkingStatesJob.perform_later(assessment_id, :incomplete)
  end
end
