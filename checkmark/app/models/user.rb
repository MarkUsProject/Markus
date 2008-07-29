class User < ActiveRecord::Base
  
  validates_presence_of     :user_name
  validates_uniqueness_of   :user_name
  validates_uniqueness_of   :user_number
  
  validates_format_of       :role,          :with => /student|admin|ta/
  
  # student/faculty number validation
  validates_format_of       :user_number,   :with =>/[0-9]/,
                            :message => "Student number should be %d digits."
  validates_length_of       :user_number,   :is => 9,  
                            :message => "Student number should be %d digits."
                          
                            
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
    # TODO call external script to validate cdf login/password
    # no password verification for now.
    true
  end
  
end