# Invoke this task with "rake i18n:missing_keys"

namespace :i18n do
  desc 'Find and list translation keys that do not exist in all locales'
  task missing_keys: :environment do
    finder = MissingKeysFinder.new(I18n.backend)
    finder.find_missing_keys
  end
end

class MissingKeysFinder
  def initialize(backend)
    @backend = backend
    self.load_translations
  end

  # Returns an array with all keys from all locales
  def all_keys
    I18n.backend.public_send(:translations).collect do |_check_locale, translations|
      collect_keys([], translations).sort
    end.flatten.uniq
  end

  def find_missing_keys
    output_available_locales
    output_unique_key_stats(all_keys)

    missing_keys = {}
    all_keys.each do |key|
      I18n.available_locales.each do |locale|
        unless key_exists?(key, locale)
          if missing_keys[key]
            missing_keys[key] << locale
          else
            missing_keys[key] = [locale]
          end
        end
      end
    end

    output_missing_keys(missing_keys)
    missing_keys
  end

  def output_available_locales
    locale_word = I18n.available_locales.size == 1 ? 'locale' : 'locales'
    puts "#{I18n.available_locales.size} #{locale_word} available: #{I18n.available_locales.join(', ')}"
  end

  def output_missing_keys(missing_keys)
    missing_keys_word = missing_keys.size == 1 ? 'key is missing' : 'keys are missing'
    puts "#{missing_keys.size}} #{missing_keys_word} from one or more locales:"
    missing_keys.keys.sort.each do |key|
      puts "'#{key}': Missing from #{missing_keys[key].join(', ')}"
    end
  end

  def output_unique_key_stats(keys)
    number_of_keys = keys.size
    puts "#{number_of_keys} #{number_of_keys == 1 ? 'unique key' : 'unique keys'} found."
  end

  def collect_keys(scope, translations)
    full_keys = []
    translations.to_a.each do |key, translations_|
      new_scope = scope.dup << key
      if translations_.is_a?(Hash)
        full_keys += collect_keys(new_scope, translations_)
      else
        full_keys << new_scope.join('.')
      end
    end
    full_keys
  end

  # Returns true if key exists in the given locale
  def key_exists?(key, locale)
    I18n.locale = locale
    I18n.t(key, raise: true)
    true
  rescue I18n::MissingInterpolationArgument
    true
  rescue I18n::MissingTranslationData
    false
  end

  def load_translations
    # Make sure we’ve loaded the translations
    I18n.backend.public_send(:init_translations)
  end
end
