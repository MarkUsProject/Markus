# TA user for a given course.
class Ta < Role
  has_one :grader_permission, dependent: :destroy, foreign_key: :role_id, inverse_of: :ta
  before_create :create_grader_permission
  validates :grader_permission, presence: { unless: -> { self.new_record? } }
  validate :associated_user_is_an_end_user
  accepts_nested_attributes_for :grader_permission

  has_many :ta_memberships, dependent: :delete_all, foreign_key: 'role_id', inverse_of: :role

  has_many :annotation_texts, dependent: :nullify, inverse_of: :creator, foreign_key: :creator_id
  has_many :annotations, dependent: :nullify, inverse_of: :creator, foreign_key: :creator_id

  has_many :criterion_ta_associations, dependent: :delete_all, inverse_of: :ta
  has_many :criteria, through: :criterion_ta_associations

  has_many :grade_entry_student_tas, dependent: :delete_all, inverse_of: :ta
  has_many :grade_entry_students, through: :grade_entry_student_tas

  has_many :notes, dependent: :restrict_with_exception, inverse_of: :role, foreign_key: :creator_id

  BLANK_MARK = ''.freeze

  def get_groupings_by_assignment(assignment)
    groupings.where(assessment_id: assignment.id)
             .includes(:students, :tas, :group, :assignment)
  end

  # An array of all the grades for an assignment for this TA.
  # If TAs are assigned to grade criteria, returns just the subtotal
  # for the criteria the TA was assigned.
  def percentage_grades_array(assignment)
    result_ids = assignment.marked_result_ids_for(self.id)

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
