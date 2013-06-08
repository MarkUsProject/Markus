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

  has_many :grouping_queues, :dependent => :destroy

  validates_numericality_of :child_pid, :only_integer => true,
    :allow_nil => true

  validates_inclusion_of :stop_child, :in => [true, false]

  #Always use the instance method to get an object of this class, never call
  #new or create directly
  def self.instance
    if SubmissionCollector.first.nil?
      temp = SubmissionCollector.create
      temp.init_queues
    end
    return SubmissionCollector.first
  end

  #Get two fresh grouping_queues
  def init_queues
    self.grouping_queues.clear
    self.grouping_queues.create(:priority_queue => false)
    self.grouping_queues.create(:priority_queue => true)
  end

  #Add all the groupings belonging to assignment to the grouping queue
  def push_groupings_to_queue(groupings)
    priority_queue = grouping_queues.find_by_priority_queue(true).groupings
    regular_queue = grouping_queues.find_by_priority_queue(false).groupings

    groupings.each do |grouping|
      unless regular_queue.include?(grouping) ||
          priority_queue.include?(grouping)
        grouping.is_collected = false
        regular_queue.push(grouping)
      end
    end
    start_collection_process
  end

  def push_grouping_to_priority_queue(grouping)
    priority_queue = grouping_queues.find_by_priority_queue(true).groupings
    regular_queue = grouping_queues.find_by_priority_queue(false).groupings

    regular_queue.delete(grouping) if regular_queue.include?(grouping)
    unless priority_queue.include?(grouping)
      grouping.is_collected = false
      priority_queue.push(grouping)
    end
    start_collection_process
  end

  #Remove grouping from the grouping queue if it exists there.
  def remove_grouping_from_queue(grouping)
    return if grouping.nil? || grouping.grouping_queue.nil?
    grouping.grouping_queue.groupings.delete(grouping)
    grouping.grouping_queue = nil
    grouping.save
    return grouping
  end

  #Get the next grouping for which to collect the submission, or return nil
  #if there are no more groupings.
  def get_next_grouping_for_collection
    priority_queue = grouping_queues.find_by_priority_queue(true).groupings
    regular_queue = grouping_queues.find_by_priority_queue(false).groupings

    current_grouping = priority_queue.first || regular_queue.first
    return current_grouping
  end

  #Fork-off a new process resposible for collecting all submissions
  def start_collection_process

    #Since windows doesn't support fork, the main process will have to collect
    #the submissions.
    if RUBY_PLATFORM =~ /(:?mswin|mingw)/ # should match for Windows only
      while collect_next_submission
      end
      return
    end

    m_logger = MarkusLogger.instance

    #Check to see if there is still a process running
    m_logger.log('Checking to see if there is already a submission collection' +
                 ' process running')
    begin
      unless self.child_pid.nil?
        Process.waitpid(self.child_pid, Process::WNOHANG)
        #If child is still running do nothing, otherwise reset the child_pid
        if $?.nil?
          m_logger.log('Submission collection process still running, doing nothing')
          return
        else
          self.child_pid = nil
          self.save
        end
      end

    #If for some reason there is no process with id self.child_pid, simply
    #proceed by forking a new process as usual.
    rescue Errno::ESRCH, Errno::ECHILD => e
    end

    #We have to re-establish a separate database connection for each process
    db_connection = ActiveRecord::Base.remove_connection

    pid = fork do
      begin
        ActiveRecord::Base.establish_connection(db_connection)
        m_logger.log('Submission collection process established database' +
                     ' connection successfully')
        #Any custom tasks to be performed by the child can be given as a block
        if block_given?
          m_logger.log('Submission collection process now evaluating provided code block')
          yield
          m_logger.log('Submission collection process done evaluating provided code block')
        end

        while collect_next_submission
          if SubmissionCollector.first.stop_child
            m_logger.log('Submission collection process now exiting because it was ' +
                         'asked to stop by its parent')
            exit!(0)
          end
        end
        m_logger.log('Submission collection process done')
        exit!(0)
      ensure
        ActiveRecord::Base.remove_connection
      end
    end
    #parent
    if pid
      ActiveRecord::Base.establish_connection(db_connection)
      self.child_pid = pid
      self.save
    end
  end

  #Collect the next submission or return nil if there are none to be collected
  def collect_next_submission
    grouping = get_next_grouping_for_collection
    return if grouping.nil?
    assignment = grouping.assignment
    m_logger = MarkusLogger.instance
    m_logger.log("Now collecting: #{assignment.short_identifier} for grouping: " +
                 "'#{grouping.id}'")
    time = assignment.submission_rule.calculate_collection_time.localtime
    # Create a new Submission by timestamp.
    # A Result is automatically attached to this Submission, thanks to some
    # callback logic inside the Submission model
    new_submission = Submission.create_by_timestamp(grouping, time)
    # Apply the SubmissionRule
    new_submission = assignment.submission_rule.apply_submission_rule(
      new_submission)
    #convert any pdf submission files to jpgs
    new_submission.submission_files.each do |subm_file|
      subm_file.convert_pdf_to_jpg if subm_file.is_pdf?
    end
    grouping.is_collected = true
    remove_grouping_from_queue(grouping)
    grouping.save
  end

  #Use the database to communicate to the child to stop, and restart itself
  #and manually collect the submission
  def manually_collect_submission(grouping, rev_num)

    #Since windows doesn't support fork, the main process will have to collect
    #the submissions.
    if RUBY_PLATFORM =~ /(:?mswin|mingw)/ # should match for Windows only
      grouping.is_collected = false
      remove_grouping_from_queue(grouping)
      grouping.save
      new_submission = Submission.create_by_revision_number(grouping, rev_num)
      new_submission.submission_files.each do |subm_file|
        subm_file.convert_pdf_to_jpg if subm_file.is_pdf?
      end
      grouping.is_collected = true
      grouping.save
      return
    end

    #Make the child process exit safely, to avoid both parent and child process
    #from calling the Magick::Image.from_blob function, this breaks future calls
    #of the method by the child.
    safely_stop_child

    #remove the grouping from the grouping_queue so it isnt collected again
    grouping.is_collected = false
    remove_grouping_from_queue(grouping)
    grouping.save

    new_submission = Submission.create_by_revision_number(grouping, rev_num)

    #This is to help determine the progress of the method.
    self.safely_stop_child_exited = true
    self.save

    #Let the child process handle conversion, as things go wrong when both
    #parent and child do this.
    start_collection_process do
      if MarkusConfigurator.markus_config_pdf_support
        new_submission.submission_files.each do |subm_file|
          subm_file.convert_pdf_to_jpg if subm_file.is_pdf?
        end
        grouping.is_collected = true
        grouping.save
      end
    end
    #setting is_collected here will prevent an sqlite lockout error when pdfs
    #aren't supported
    unless MarkusConfigurator.markus_config_pdf_support
      grouping.is_collected = true
      grouping.save
    end

  end

  def safely_stop_child
    unless self.child_pid.nil?
      begin
        self.stop_child = true
        self.save
        Process.waitpid(self.child_pid)
      #Ignore case where no process with child_pid exists
      rescue Errno::ESRCH, Errno::ECHILD => e
      ensure
        self.stop_child = false
        self.child_pid = nil
        self.save
      end
    end
  end

end
