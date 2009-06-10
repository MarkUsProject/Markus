# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  layout "content"
  
  include SessionHandler
  
  helper :all # include all helpers, all the time
    # exclude login/logout page so that anyone can access it (duh!)
  
  # activate i18n for renaming constants in views
  before_filter :set_locale
  # check for active session on every page
  before_filter :authenticate, :except => [:login, :logout] 
  
  # See ActionController::Base for details 
  # Filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "user"). 
  # TODO enable on production deployment
  # filter_parameter_logging :user
  
  protected
  
  def set_locale
    # does not do anything for now, but might be used later
    session[:locale] = params[:locale] if params[:locale]
    I18n.locale = session[:locale] || I18n.default_locale # for now, always resorts to I18n.default_locale
    
    locale_path = "#{LOCALES_DIRECTORY}#{I18n.locale}.yml"
    
    unless I18n.load_path.include? locale_path
      I18n.load_path << locale_path
      I18n.backend.send(:init_translations)
    end
  
  # handle unknown locales 
  rescue Exception => err
    logger.error err
    flash.now[:notice] = "#{I18n.locale} translation not available!"
    
    I18n.load_path -= [locale_path]
    I18n.locale = session[:locale] = I18n.default_locale
  end
end
