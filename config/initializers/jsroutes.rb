# Configuration for the 'js-routes' gem

# Automatically update routes.js file
# when routes.rb is changed
Rails.application.config.middleware.use(JsRoutes::Middleware)

JsRoutes.setup do |config|
  config.url_links = true
end
