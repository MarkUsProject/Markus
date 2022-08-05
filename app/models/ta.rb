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
    total = result.total_mark

    percent = BLANK_MARK

    # Check for NA mark or division by 0
    unless total.nil? || out_of == 0
      percent = (total / out_of) * 100
    end
    percent
  end

  # An array of all the grades for an assignment
  def percentage_grades_array(assignment)
    groupings = assignment.groupings
                          .joins(:tas)
                          .where(memberships: { role_id: id })
    grades = []

    if assignment.assign_graders_to_criteria
      criteria_ids = self.criterion_ta_associations.where(assessment_id: assignment.id).pluck(:criterion_id)
      out_of = criteria_ids.sum do |criterion_id|
        Criterion.find(criterion_id).max_mark
      end
      return [] if out_of.zero?

      mark_data = groupings.joins(current_result: :marks)
                           .where('marks.criterion_id': criteria_ids)
                           .where.not('marks.mark': nil)
                           .pluck('results.id', 'marks.mark')
                           .group_by { |x| x[0] }
      mark_data.each_value do |marks|
        next if marks.empty?

        subtotal = 0
        has_mark = false
        marks.each do |_, mark|
          subtotal += mark
          has_mark = true
        end
        grades << subtotal / out_of * 100 if has_mark
      end
    else
      out_of = assignment.max_mark
      groupings.includes(:current_result).find_each do |grouping|
        result = grouping.current_result
        unless result.nil? || result.total_mark.nil? || result.marking_state != Result::MARKING_STATES[:complete]
          percent = calculate_total_percent(result, out_of)
          unless percent == BLANK_MARK
            grades << percent
          end
        end
      end
    end
    grades
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
