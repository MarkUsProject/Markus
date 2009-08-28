# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include SessionHandler

  protect_from_forgery  
  
  layout "content"
  
  helper :all # include all helpers, all the time
  
  # activate i18n for renaming constants in views
  before_filter :set_locale, :set_markus_version
  # check for active session on every page
  before_filter :authenticate, :except => [:login] 
  
  # See ActionController::Base for details 
  # Filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "user"). 
  filter_parameter_logging :user
  
  protected
  
  # Set version for MarkUs to be available in
  # any view
  def set_markus_version
    @markus_version = "0.5"
  end
  
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
