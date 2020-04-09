# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include ApplicationHelper, SessionHandler
  include UploadHelper
  include DownloadHelper

  rescue_from ActionPolicy::Unauthorized, with: :user_not_authorized

  # responder set up
  self.responder = ApplicationResponder
  respond_to :html

  protect_from_forgery with: :exception

  layout 'content'

  helper :all # include all helpers in the views, all the time

  # activate i18n for renaming constants in views
  before_action :set_locale, :set_markus_version, :set_remote_user, :get_file_encodings
  # check for active session on every page
  before_action :authenticate, except: [:login, :page_not_found, :check_timeout]
  # check for AJAX requests
  after_action :flash_to_headers
  # Define default URL options to include the locale
  def default_url_options(options={})
    { locale: I18n.locale }
  end

  protected

  # Set version for MarkUs to be available in
  # any view
  def set_markus_version
    version_file=File.expand_path(File.join(::Rails.root.to_s, 'app', 'MARKUS_VERSION'))
    unless File.exist?(version_file)
      @markus_version = 'unknown'
      return
    end
    content = File.new(version_file).read
    version_info = Hash.new
    content.split(',').each do |token|
      k,v = token.split('=')
      version_info[k.downcase] = v
    end
    @markus_version = "#{version_info['version']}.#{version_info['patch_level']}"
  end

  def set_remote_user
    if request.env['HTTP_X_FORWARDED_USER'].present?
      @markus_auth_remote_user = request.env['HTTP_X_FORWARDED_USER']
    elsif Rails.configuration.remote_user_auth && !Rails.env.production?
      # This is only used in non-production modes to test Markus behaviours specific to
      # external authentication. This should not be used in the place of any real
      # authentication (basic or otherwise)!
      authenticate_or_request_with_http_basic do |username, _|
        @markus_auth_remote_user = username
      end
    end
  end

  # Set locale according to URL parameter. If unknown parameter is
  # requested, fall back to default locale.
  def set_locale
    if params[:locale].nil?
      I18n.locale = I18n.default_locale
    elsif I18n.available_locales.include? params[:locale].to_sym
      I18n.locale = params[:locale]
    else
      flash_now(:notice, I18n.t('locale_not_available', locale: params[:locale]))
    end
  end

  def get_file_encodings
    @encodings = [%w(Unicode UTF-8), %w(ISO-8859-1 ISO-8859-1)]
  end

  # add flash message to AJAX response headers
  def flash_to_headers
    return unless request.xhr?
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
    flash.discard
  end

  # dynamically hide a flash message (for AJAX requests only)
  def hide_flash(key)
    return unless request.xhr?

    discard_header = response.headers['X-Message-Discard']
    if discard_header.nil?
      response.headers['X-Message-Discard'] = key.to_s
    else
      response.headers['X-Message-Discard'] = "#{key};#{discard_header}"
    end
  end

  def user_not_authorized
    render 'shared/http_status',
           formats: [:html], locals: { code: '403', message: HttpStatusHelper::ERROR_CODE['message']['403'] },
           status: 403, layout: false
  end
end
