
# We always assume the following fields exists:
# => :user_name, :user_number, :last_name, :first_name
# If there are added columns, add the default values to default_values
class User < ActiveRecord::Base
  
  # Group relationships
  has_many  :memberships
  has_many  :groups,  :through => :memberships
  has_many  :submissions, :class_name => 'UserSubmission'
  
  
  validates_presence_of     :user_name, :user_number, :last_name, :first_name
  validates_uniqueness_of   :user_number, :user_name
  
  validates_format_of       :role,          :with => /student|admin|ta/
  #validates_format_of       :last_name, :first_name,    
  #  :with => /^(\w)+$/, :message => "should be alphanumeric"
  
  # student/faculty number validation
  validates_format_of       :user_number,   :with =>/\d{9}/,
    :message => "should all be 9 digits."
  
  validates_numericality_of :grace_days, :only_integer => true, 
    :greater_than_or_equal_to => 0, :allow_nil => true
    
  # role constants
  # NOTE (from Severin): Names of role constants are pulled into view. 
  #                      Naming them with correct spelling might make sense.
  STUDENT = 'student'
  ADMIN = 'admin'
  TA = 'ta'
  
  GRACE_DAYS = 1  # TODO add to config when creating course, hardcoded for now, must be >= 0
  
  # Authentication------------------------------------------------------
  
  # Verifies that the user has a registered login and that its 
  # password corresponds to the given login.
  # Returns user object representing the user with the given login.
  def self.authenticate(login, password)
    # call actual method for authentication before 
    # fetching login in database to see if it is registered.
    find_by_user_name(login) if verify(login, password) # Windows can't run bash
    # find_by_user_name(login)
  end
  
  # Authenticates login against its password 
  # through a script validate file.
  def self.verify(login, password)
    pipe = IO.popen(VALIDATE_FILE, "w+")
    
    # TODO sanitize
    args = %{#{login}\n#{password}\n}
    pipe.write(args)
    pipe.close
    
    return $?.exitstatus == 0
  end
  
  # Group methods ------------------------------------------------------
  
  
  # Returns the group given a specified assignment id. Returns nil if no 
  # group exists for this user with the given assignment.
  def group_for(aid)
    groups.first(:include => :assignments, 
      :conditions => ["assignments.id = ? and memberships.status != 'rejected'", aid])
  end
  
  
  # Helper methods -----------------------------------------------------
    
  def admin?
    role == ADMIN
  end

  def ta?
    role == TA
  end
  
  def student?
    role == STUDENT
  end

  # Returns an array of users with TA role
  def self.tas
    # dynamic find_all_by_<attribute name> in ActiveRecords
    find_all_by_role(TA)
  end

  # Returns a hash of all the default attribute values for a TA user
  def self.get_default_ta_attrs
    {:role => TA}
  end
  
  # Returns an array of users with student role
  def self.students
    find_all_by_role(STUDENT)
  end
  
  # Returns a hash of all the default attribute values for a student user
  def self.get_default_student_attrs
    {:role => STUDENT, :grace_days => GRACE_DAYS}
  end
  
  # Classlist parser ---------------------------------------------------
  
  # Creates and saves a new user using provided attribute values.
  # If the attribute value for user number already exists in the database,
  # then the existing record is overwritten only with the supplied values.
  # Returns the new user created or updated, or nil if no user has neither 
  # been created nor updated.
  def self.update_on_duplicate(hash_values, role=User::STUDENT)
    nil unless hash_values.has_key?(:user_number)
    u = find_or_create_by_user_number(hash_values)
    u.role = role
    u.attributes = hash_values
    u.save ? u : nil
  end
  
  # Submissions methods ------------------------------------------------------
  
  def submission_for(aid)
    #TODO - doesn't work
    submissions.first(:conditions => ["assignment_id = ?", aid])
  end

end






