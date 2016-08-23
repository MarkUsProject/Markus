require "date"

# set English as default
I18n.default_locale = MarkusConfigurator.markus_config_default_language
I18n.locale = MarkusConfigurator.markus_config_default_language

# location where the language files go
LOCALES_DIRECTORY = File.join(::Rails.root.to_s, "config", "locales")

language_files = Dir.glob(File.join(LOCALES_DIRECTORY, "*.yml" ))
AVAILABLE_LANGS = language_files.collect{ |file| File.basename(file).chomp(".yml") }.sort
