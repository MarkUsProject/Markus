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

    #Since windows doesn't support fork, the main process will have to collect
    #the submissions.
    if !async || RUBY_PLATFORM =~ /(:?mswin|mingw)/ # match for Windows
       new_submission = Submission.create_by_revision_number(grouping, rev_num)
#      grouping.is_collected = false
#       remove_grouping_from_queue(grouping)
#       grouping.save
#       new_submission = Submission.create_by_revision_number(grouping, rev_num)
#       apply_penalty_or_add_grace_credits(grouping,
#                                          apply_late_penalty,
#                                          new_submission)
#       grouping.is_collected = true
#       grouping.save
#       return new_submission
		::SingleSub.perform_later(grouping, rev_num, apply_late_penalty, new_submission)
		return new_submission
    end

    #Make the child process exit safely, to avoid both parent and child process
    #from calling the Magick::Image.from_blob function, this breaks future calls
    #of the method by the child.
    #safely_stop_child

    #remove the grouping from the grouping_queue so it isnt collected again
    grouping.is_collected = false
    grouping.save

    new_submission = Submission.create_by_revision_number(grouping, rev_num)
    apply_penalty_or_add_grace_credits(grouping,
                                       apply_late_penalty,
                                       new_submission)

    #This is to help determine the progress of the method.
    self.safely_stop_child_exited = true
    self.save

    #Let the child process handle conversion, as things go wrong when both
    #parent and child do this.
    start_collection_process do
        grouping.is_collected = true
        grouping.save
    end
    #setting is_collected here will prevent an sqlite lockout error when pdfs
    #aren't supported
      grouping.is_collected = true
      grouping.save

  end

#   def safely_stop_child
#     unless self.child_pid.nil?
#       begin
#         self.stop_child = true
#         self.save
#         Process.waitpid(self.child_pid)
#       #Ignore case where no process with child_pid exists
#       rescue Errno::ESRCH, Errno::ECHILD
#       ensure
#         self.stop_child = false
#         self.child_pid = nil
#         self.save
#       end
#     end
#   end

end
