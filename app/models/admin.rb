# we need repository permission constants
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'repo', 'repository')
class Admin < User
  SESSION_TIMEOUT = USER_ADMIN_SESSION_TIMEOUT

  after_create  :grant_repository_permissions
  after_destroy :revoke_repository_permissions
  after_update  :maintain_repository_permissions

  # for an admin, we just want all the assignment groupings submitted
  def get_num_assigned(assignment)
    assignment.groupings.size
  end

  # for an admin, we want all the assignment groupings marked completed
  def get_num_marked(assignment)
    n = assignment.groupings.count(marking_completed: true)
    n
  end

  def get_num_annotations(assignment)
    n = 0
    assignment.groupings.each do |x|
      # only grab annotations from groupings where marking is completed
      next unless x.marking_completed?
      x.submissions.each do |s|
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
      avg = num_annotations.to_f / num_marked
    end
    avg.round(2)
  end
end
