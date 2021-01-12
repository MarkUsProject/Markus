# Configuration for the 'i18n-js' gem

# Generate public/javascripts/{i18n.js,translations.js}
Rails.application.config.middleware.use I18n::JS::Middleware

# Explicitly whitelist available locales for i18n-js.
I18n.available_locales = Settings.i18n.available_locales

# Set default locale.
I18n.default_locale = Settings.i18n.default_locale
