# we need repository and permission constants
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'repo', 'repository')

class Ta < User

  CSV_UPLOAD_ORDER = USER_TA_CSV_UPLOAD_ORDER
  SESSION_TIMEOUT = USER_TA_SESSION_TIMEOUT

  after_create  :grant_repository_permissions
  after_destroy :revoke_repository_permissions
  after_update  :maintain_repository_permissions

  has_many :criterion_ta_associations, dependent: :delete_all

  has_many :grade_entry_student_tas
  has_many :grade_entry_students, through: :grade_entry_student_tas

  def get_num_assigned(assignment)
    assignment.ta_memberships.where(user_id: id).size
  end

  def get_num_marked(assignment)
    n = 0
    assignment.ta_memberships.where(user_id: id).each do |x|
      if x.grouping.marking_completed?
        n += 1
      end
    end
    n
  end

  def get_num_annotations(assignment)
    n = 0
    assignment.ta_memberships.where(user_id: id).find_each do |x|
      # only grab annotations from groupings where marking is completed
      next unless x.grouping.marking_completed?
      x.grouping.submissions.each do |s|
        n += s.annotations.size
      end
    end
    n
  end

  def average_annotations(assignment)
    num_marked = get_num_marked(assignment)
    avg = 0
    if num_marked != 0
      num_annotations = get_num_annotations(assignment)
      avg = num_annotations / num_marked
    end
    avg
  end

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
end
