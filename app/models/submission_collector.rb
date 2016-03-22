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
    end
    return SubmissionCollector.first
  end

  def start_collection_process
    SubmissionJob.perform_later
  end


  #Use the database to communicate to the child to stop, and restart itself
  #and manually collect the submission
  #The third parameter enables or disables the forking.
  def manually_collect_submission(grouping, rev_num,
                                  apply_late_penalty, async = true)

       new_submission = Submission.create_by_revision_number(grouping, rev_num)
		SingleSubmissionJob.perform_later(grouping, rev_num, apply_late_penalty, new_submission)
		return new_submission
  end

end