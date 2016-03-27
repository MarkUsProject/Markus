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
    SubmissionsJob.perform_later
  end


  def manually_collect_submission(grouping, rev_num,
                                  apply_late_penalty)

       new_submission = Submission.create_by_revision_number(grouping, rev_num)
		SingleSubmissionJob.perform_later(grouping, rev_num, apply_late_penalty, new_submission)
		return new_submission
  end

end