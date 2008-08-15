
# We always assume the following fields exists:
# => :user_name, :user_number, :last_name, :first_name
# If there are added columns, add the default values to default_values
class User < ActiveRecord::Base
  
  validates_presence_of     :user_name, :user_number, :last_name, :first_name
  validates_uniqueness_of   :user_number, :user_name
  
  validates_format_of       :role,          :with => /student|admin|ta/
  
  # student/faculty number validation
  validates_format_of       :user_number,   :with =>/\d{9}/,
    :message => "should all be 9 digits."
    
  # role constants
  STUDENT = 'student'
  ADMIN = 'admin'
  TA = 'ta'
                          
  
  # Authentication------------------------------------------------------
  
  # Verifies that the user has a registered login and that its 
  # password corresponds to the given login.
  # Returns user object representing the user with the given login.
  def self.authenticate(login, password)
    # call actual method for authentication before 
    # fetching login in database to see if it is registered.
    find_by_user_name(login) if verify(login, password)
  end
  
  # Responsible for the actual authentication of login against 
  # its password. This is done by 
  def self.verify(login, password)
    pipe = IO.popen(VALIDATE_FILE, "w+")
    
    # TODO sanitize
    args = %{#{login}\n#{password}\n}
    pipe.write(args)
    pipe.close
    
    return $?.exitstatus == 0
  end
  
  # Helper methods -----------------------------------------------------
  
    
  def admin?
    role == ADMIN
  end
  
  def student?
    role == STUDENT
  end
  
  # Returns an array of users with student role
  def self.students
    find_all_by_role(STUDENT)
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
  
  # Returns a hash of all the default attribute values for a student user
  def self.get_default_student_attrs
    {:role => STUDENT}
  end
  
end