# Configuration for the 'js-routes' gem

# Automatically update routes.js file
# when routes.rb is changed
Rails.application.config.middleware.use(JsRoutes::Middleware)

JsRoutes.setup do |config|
  config.url_links = true
  # The relative URL root is set dynamically, once the application JS loads
  # (see the RELATIVE_URL_ROOT constant and its use in application_webpack.js).
  config.prefix = ''
end
