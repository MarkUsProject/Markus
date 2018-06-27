# Configuration for the 'i18n-js' gem

# Explicit activation (no asset pipeline)
Rails.application.config.middleware.use I18n::JS::Middleware
