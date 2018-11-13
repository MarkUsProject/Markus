# Configuration for the 'i18n-js' gem

# Generate public/javascripts/{i18n.js,translations.js}
Rails.application.config.middleware.use I18n::JS::Middleware
