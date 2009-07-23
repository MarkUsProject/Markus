class SubmissionRule < ActiveRecord::Base
  
  belongs_to :assignment
  has_many :periods, :dependent => :destroy
  accepts_nested_attributes_for :periods, :allow_destroy => true
  
#  validates_associated :assignment
#  validates_presence_of :assignment
  
  def can_collect_now?
    return Time.now >= calculate_collection_time
  end
  
  # Based on the assignment's due date, return the collection time for submissions
  # Return a value of type Time
  def calculate_collection_time
    raise NotImplementedError.new("SubmissionRule:  calculate_collection_time not implemented")
  end
  
  # When Students commit code after the collection time, MarkUs should warn
  # the Students with a message saying that the due date has passed, and the
  # work they're submitting will probably not be graded
  def commit_after_collection_message
    #I18n.t 'submission_rules.submission_rule.commit_after_collection_message'
    raise NotImplementedError.new("SubmissionRule:  commit_after_collection_message not implemented")
  end
  
  # When Students view the File Manager after the collection time, 
  # MarkUs should warnthe Students with a message saying that the 
  # due date has passed, and that any work they're submitting will 
  # probably not be graded
  def after_collection_message
    raise NotImplementedError.new("SubmissionRule:  after_collection_message not implemented")
  end
  
  # When we're past the due date, the File Manager for the students will display
  # a message to tell them that they're currently past the due date.
  def overtime_message
    raise NotImplementedError.new("SubmissionRule: overtime_message not implemented")
  end
  
  # Returns true or false based on whether the attached Assignment's properties
  # will work with this particular SubmissionRule
  def assignment_valid?
    raise NotImplementedError.new("SubmissionRule: assignment_valid? not implemented")
  end

  # Takes a Submission (with an attached Result), and based on the properties of 
  # this SubmissionRule, applies penalties to the Result - for example, will
  # add an ExtraMark of a negative value, or perhaps add the use of a Grace Day.
  def apply_submission_rule(submission)
    raise NotImplementedError.new("SubmissionRule:  apply_submission_rule not implemented")
  end

  def description_of_rule
    raise NotImplementedError.new("SubmissionRule:  description_of_rule not implemented")
  end
  
end
