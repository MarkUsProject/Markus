module GraderRole
  extend ActiveSupport::Concern

  included do
    has_many :criterion_ta_associations, dependent: :delete_all, foreign_key: :ta_id, inverse_of: :ta
    has_many :criteria, through: :criterion_ta_associations
  end

  def get_groupings_by_assignment(assignment)
    groupings.where(assessment_id: assignment.id)
             .includes(:students, :tas, :group, :assignment)
  end

  # Return all grades for an assignment that were assigned to this grader.
  def percentage_grades_array(assignment)
    result_ids = assignment.marked_result_ids_for(self.id)

    if assignment.assign_graders_to_criteria
      criterion_ids = criterion_ta_associations.where(assessment_id: assignment.id).pluck(:criterion_id)
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

  def grade_distribution_array(assignment, intervals = 20)
    data = percentage_grades_array(assignment)
    data.extend(Histogram)
    histogram = data.histogram(intervals, min: 1, max: 100, bin_boundary: :min, bin_width: 100 / intervals)
    distribution = histogram.fetch(1)
    distribution[0] = distribution.first + data.count { |x| x < 1 }
    distribution[-1] = distribution.last + data.count { |x| x > 100 }

    distribution
  end
end
