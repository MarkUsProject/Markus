# Helpers for routing related tasks
module RoutingHelper
  # Return the request referer parsed as a hash that can be passed directly to
  # redirect_to. If the referer is not a url that can be redirected to, return
  # an empty hash.
  def referer_options
    referer_url = request.referer || ''
    referer = URI(referer_url)
    relative_url = Rails.application.config.relative_url_root
    referer.path = referer.path.gsub(%r{^#{relative_url}/?}, '/')
    begin
      options = Rails.application.routes.recognize_path(referer.to_s)
    rescue ActionController::RoutingError
      options = {}
    end
    options = {} if options[:action] == 'page_not_found'
    options
  end
end
