require "date"

# set English as default
I18n.default_locale = 'en'
I18n.locale = 'en' 

# location where the language files go
LOCALES_DIRECTORY = File.join(RAILS_ROOT, "config", "locales")

language_files = Dir.glob(File.join(LOCALES_DIRECTORY, "*.yml" ))
AVAILABLE_LANGS = language_files.collect{ |file| File.basename(file).chomp(".yml") }

# Languages available in MarkUs
# Change the value of I18n.default_locale
# English : 'en'
# French : 'fr'
