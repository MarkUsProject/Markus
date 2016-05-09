# A signleton class responsible for collecting submissions from groupings.
#
# The SubmissionCollector keeps track of groupings it needs to collect
# submissions from via two queues, one regular queue to keep track of groupings
# whose submissions need to be collected. The second queue is the priority
# queue, whose members' submissions get collected ahead of the ones in the
# regular queue.
#
# The actual creation of the submissions for the grouping is done inside a
# forked process due to the length of time taken to collect submissions with
# pdf files in them.
#
# The collector updates the groupings to let them know if they are in queue for
# collection, in order to figure out if their current submission is the latest
# one, or theres a newer one waiting to be collected.
#
# Both queues are stored in the database to allow for easy parent-child
# process communication bypassing the need for pipes or signals.
class SubmissionCollector < ActiveRecord::Base

  has_many :grouping_queues, dependent: :destroy

  validates_numericality_of :child_pid,
                            only_integer: true,
                            allow_nil: true

  validates_inclusion_of :stop_child, in: [true, false]

  #Always use the instance method to get an object of this class, never call
  #new or create directly
  def self.instance
    if SubmissionCollector.first.nil?
      temp = SubmissionCollector.create
      temp.init_queues
    end
    return SubmissionCollector.first
  end

  # Undo one level of submissions
  def uncollect_submissions(assignment)
    submissions = assignment.submissions
    old_submissions = submissions.where(submission_version_used: true)
    ActiveRecord::Base.transaction do
      old_submissions.each do |submission|
        grouping = submission.grouping
        grouping.update_attributes(grouping_queue_id: nil, is_collected: false)
        # version = submission.submission_version
        # grouping = submission.grouping
        # if version == 1
        #   grouping.assign_attributes(is_collected: false)
        # else
        #   prev_rev = submissions.where(submission_version: version - 1,
        #                                grouping_id: grouping.id).first
        #   prev_rev.update_attributes(submission_version_used: true)
        # end
        # grouping.update_attributes(grouping_queue_id: nil)
      end
      old_submissions.destroy_all
    end
  end
end
