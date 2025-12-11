# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include SessionHandler
  include ApplicationHelper
  include UploadHelper
  include DownloadHelper

  authorize :role, through: :current_role
  authorize :real_user, through: :real_user
  authorize :real_role, through: :real_role
  verify_authorized
  rescue_from ActionPolicy::Unauthorized, with: :user_not_authorized

  # responder set up
  self.responder = ApplicationResponder
  respond_to :html

  protect_from_forgery with: :exception

  layout 'content'

  helper :all # include all helpers in the views, all the time

  # set user time zone based on their settings
  around_action :use_time_zone, if: :current_user
  # activate i18n for renaming constants in views
  before_action :set_locale, :get_file_encodings
  # check for active session on every page
  before_action :authenticate, :check_record,
                except: [:login, :page_not_found, :check_timeout, :login_remote_auth]
  before_action :check_course_switch
  # check for AJAX requests
  after_action :flash_to_headers

  # Define default URL options to include the locale if the user is not logged in
  def default_url_options(_options = {})
    if current_user
      {}
    else
      { locale: I18n.locale }
    end
  end

  def page_not_found
    if current_user
      current_role unless current_course.nil?
      render 'shared/error_page',
             locals: { code: '404', message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: :not_found,
             layout: 'content'
    else
      redirect_to root_path
    end
  end

  protected

  def use_time_zone(&)
    Time.use_zone(current_user.time_zone, &)
  end

  # Set locale according to URL parameter. If unknown parameter is
  # requested, fall back to default locale.
  def set_locale
    if params[:locale].nil?
      if current_user && I18n.available_locales.include?(current_user.locale.to_sym)
        I18n.locale = current_user.locale
      else
        I18n.locale = I18n.default_locale
      end
    elsif I18n.available_locales.include? params[:locale].to_sym
      I18n.locale = params[:locale]
    else
      flash_now(:notice, I18n.t('locale_not_available', locale: params[:locale]))
    end
  end

  def get_file_encodings
    @encodings = [%w[Unicode UTF-8], %w[ISO-8859-1 ISO-8859-1]]
  end

  # add flash message to HTTP response headers
  def flash_to_headers
    [:error, :success, :warning, :notice].each do |key|
      unless flash[key].nil?
        if flash[key].is_a?(Array)
          str = flash[key].join(';')
        else
          str = flash[key]
        end
        response.headers["X-Message-#{key}"] = str
      end
    end
    if request.xhr?
      flash.discard
    end
  end

  # dynamically hide a flash message (for HTTP requests)
  def hide_flash(key)
    discard_header = response.headers['X-Message-Discard']
    if discard_header.nil?
      response.headers['X-Message-Discard'] = key.to_s
    else
      response.headers['X-Message-Discard'] = "#{key};#{discard_header}"
    end
  end

  def user_not_authorized
    if current_user
      render 'shared/error_page',
             locals: { code: '403', message: HttpStatusHelper::ERROR_CODE['message']['403'] },
             status: :forbidden,
             layout: 'content'
    else
      redirect_to root_path
    end
  end

  # Render 403 if the current user is switching roles and they try to view a route for a different course
  def check_course_switch
    if session[:role_switch_course_id] && current_course&.id != session[:role_switch_course_id]
      flash_message(:error, I18n.t('main.role_switch.forbidden_warning'))
      redirect_back(fallback_location: course_assignments_path(session[:role_switch_course_id]))
    end
  end

  def implicit_authorization_target
    controller_name.classify.constantize.find_or_initialize_by(identification_params)
  end

  def identification_params
    params.permit(:id)
  end
end
