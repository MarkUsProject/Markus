# This lets rails autoreload the lib/repo files on every request
# Should be taken out before production.
require_dependency Rails.root.join('lib', 'repo', 'repository').to_s

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include ApplicationHelper, SessionHandler

  protect_from_forgery

  layout 'content'

  helper :all # include all helpers in the views, all the time

  # activate i18n for renaming constants in views
  before_filter :set_locale, :set_markus_version, :set_remote_user, :get_file_encodings
  # check for active session on every page
  before_filter :authenticate, except: [:login, :page_not_found]

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
    unless request.env['HTTP_X_FORWARDED_USER'].blank?
      @markus_auth_remote_user = request.env['HTTP_X_FORWARDED_USER']
    end
  end

  # Set locale according to URL parameter. If unknown parameter is
  # requested, fall back to default locale.
  def set_locale
    @available_locales = AVAILABLE_LANGS if @available_locales.nil?
    I18n.locale = params[:locale] || I18n.default_locale

    locale_path = File.join(LOCALES_DIRECTORY, "#{I18n.locale}.yml")

    unless I18n.load_path.include? locale_path
      I18n.load_path << locale_path
      I18n.backend.send(:init_translations)
    end

  # handle unknown locales
  rescue Exception => err
    logger.error err
    flash.now[:notice] = I18n.t('locale_not_available', locale: I18n.locale)

    I18n.load_path -= [locale_path]
    I18n.locale = I18n.default_locale
  end

  def get_file_encodings
    @encodings = [%w(Unicode UTF-8), %w(ISO-8859-1 ISO-8859-1)]
  end

end
