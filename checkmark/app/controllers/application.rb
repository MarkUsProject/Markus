# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  layout "content"
  
  include SessionHandler
  
  helper :all # include all helpers, all the time
  
  
  # check for active session on every page
  before_filter :authenticate
  
  

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery :secret => '242d0f902b4b476d4807d862b5ebd6c1'
  
  # See ActionController::Base for details 
  # Filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "user"). 
  # TODO enable on production deployment
  # filter_parameter_logging :user
  
end
