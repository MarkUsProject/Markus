# Add all config/locales subdirs
# Explicitly whitelist available locales for i18n-js.
I18n.available_locales = Settings.i18n.available_locales

# Set default locale.
I18n.default_locale = Settings.i18n.default_locale

# Set load path
I18n.load_path += Dir[Rails.root.join('config/locales/**/*.{rb,yml}')]
