# TA user for a given course.
class Ta < Role
  has_one :grader_permission, dependent: :destroy, foreign_key: :role_id, inverse_of: :ta
  before_create :create_grader_permission
  validates :grader_permission, presence: { unless: -> { self.new_record? } }
  validate :associated_user_is_an_end_user
  accepts_nested_attributes_for :grader_permission
  has_many :criterion_ta_associations, dependent: :delete_all
  has_many :criteria, through: :criterion_ta_associations

  has_many :grade_entry_student_tas, dependent: :delete_all
  has_many :grade_entry_students, through: :grade_entry_student_tas, dependent: :delete_all

  BLANK_MARK = ''.freeze

  def get_groupings_by_assignment(assignment)
    groupings.where(assessment_id: assignment.id)
             .includes(:students, :tas, :group, :assignment)
  end

  # Determine the total mark for a particular student, as a percentage
  def calculate_total_percent(result, out_of)
    total = result.get_total_mark

    percent = BLANK_MARK

    # Check for NA mark or division by 0
    unless total.nil? || out_of == 0
      percent = (total / out_of) * 100
    end
    percent
  end

  # An array of all the grades for an assignment for this TA.
  # If TAs are assigned to grade criteria, returns just the subtotal
  # for the criteria the TA was assigned.
  def percentage_grades_array(assignment)
    result_ids = assignment.current_results
                           .joins(grouping: :tas)
                           .where(marking_state: Result::MARKING_STATES[:complete], 'roles.id': self.id)
                           .ids

    if assignment.assign_graders_to_criteria
      criterion_ids = self.criterion_ta_associations.where(assessment_id: assignment.id).pluck(:criterion_id)
      out_of = assignment.ta_criteria.where(id: criterion_ids).sum(:max_mark)
      return [] if out_of.zero?

      raw_marks = Result.get_subtotals(result_ids, criterion_ids: criterion_ids).values
    else
      out_of = assignment.max_mark
      return [] if out_of.zero?

      raw_marks = Result.get_total_marks(result_ids).values
    end

    raw_marks.map { |mark| mark * 100 / out_of }
  end

  # Returns grade distribution for a grade entry item for each student
  def grade_distribution_array(assignment, intervals = 20)
    data = percentage_grades_array(assignment)
    data.extend(Histogram)
    histogram = data.histogram(intervals, min: 1, max: 100, bin_boundary: :min, bin_width: 100 / intervals)
    distribution = histogram.fetch(1)
    distribution[0] = distribution.first + data.count { |x| x < 1 }
    distribution[-1] = distribution.last + data.count { |x| x > 100 }

    distribution
  end

  private

  def create_grader_permission
    self.grader_permission ||= GraderPermission.new
  end
end
