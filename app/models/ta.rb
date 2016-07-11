# we need repository and permission constants
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'repo', 'repository')

class Ta < User

  CSV_UPLOAD_ORDER = USER_TA_CSV_UPLOAD_ORDER
  SESSION_TIMEOUT = USER_TA_SESSION_TIMEOUT

  after_create  :grant_repository_permissions
  after_destroy :revoke_repository_permissions
  after_update  :maintain_repository_permissions

  has_many :criterion_ta_associations, dependent: :delete_all

  has_many :grade_entry_student_tas, dependent: :delete_all
  has_many :grade_entry_students, through: :grade_entry_student_tas, dependent: :delete_all

  def memberships_for_assignment(assignment)
    assignment.ta_memberships.where(user_id: id, include: { grouping: :group })
  end

  def is_assigned_to_grouping?(grouping_id)
    grouping = Grouping.find(grouping_id)
    grouping.ta_memberships.where(user_id: id).size > 0
  end

  def get_criterion_associations_by_assignment(assignment)
    if assignment.assign_graders_to_criteria
      criterion_ta_associations.select do |association|
        association.assignment == assignment
      end
    else
      []
    end
  end

  def get_criterion_associations_count_by_assignment(assignment)
    assignment.criterion_ta_associations
              .where(ta_id: id)
              .count
  end

  def get_membership_count_by_assignment(assignment)
    memberships.where(groupings: { assignment_id: assignment.id })
               .includes(:grouping)
               .count
  end

  def get_groupings_by_assignment(assignment)
    groupings.where(assignment_id: assignment.id)
             .includes(:students, :tas, :group, :assignment)
  end

  def get_membership_count_by_grade_entry_form(grade_entry_form)
    grade_entry_students.where('grade_entry_form_id = ?', grade_entry_form.id)
                        .includes(:grade_entry_form)
                        .count
  end

  def grade_distribution_array(assignment, intervals = 20)
    distribution = Array.new(intervals, 0)
    assignment.groupings.joins(:tas)
      .where(memberships: { user_id: id }).find_each do |grouping|
      submission = grouping.current_submission_used
      next if submission.nil?
      result = submission.get_latest_completed_result
      next if result.nil?
      distribution = update_distribution(distribution, result,
                                         assignment.max_mark, intervals)
    end # end of groupings loop
    distribution.to_json
  end

  def update_distribution(distribution, result, out_of, intervals)
    steps = 100 / intervals # number of percentage steps in each interval
    percentage = [100, (result.total_mark / out_of * 100).ceil].min
    interval = (percentage / steps).floor
    interval -= (percentage % steps == 0) ? 1 : 0
    distribution[interval] += 1
    distribution
  end
end
