# Add all config/locales subdirs
I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
