RSpec::Matchers.define :have_message do |msg, **interpolations|
  match do |actual|
    expected = get_expected_text(msg, **interpolations)
    actual_messages = Array(actual).map { |m| strip_html(m.to_s) }
    actual_messages.any? { |m| m.strip == strip_html(expected).strip }
  end

  failure_message do |actual|
    actual_stripped = Array(actual).map { |m| strip_html(m.to_s) }
    "expected that #{actual_stripped.inspect} would exactly match message #{expected.inspect}"
  end
end

RSpec::Matchers.define :contain_message do |msg, **interpolations|
  match do |actual|
    expected = get_expected_text(msg, **interpolations)
    actual_messages = Array(actual).map { |m| strip_html(m.to_s) }
    actual_messages.any? { |m| m.include?(strip_html(expected)) }
  end

  failure_message do |actual|
    actual_stripped = Array(actual).map { |m| strip_html(m.to_s) }
    "expected that #{actual_stripped.inspect} would contain message #{expected.inspect}"
  end
end

def get_expected_text(msg, **interpolations)
  if translation_exists?(msg)
    I18n.t(msg, **interpolations)
  else
    interpolate_string(msg.to_s, **interpolations)
  end
end

def translation_exists?(key)
  I18n.exists?(key)
rescue StandardError
  false
end

def interpolate_string(text, **interpolations)
  interpolations.each do |key, value|
    text = text.gsub("%{#{key}}", value.to_s)
  end
  text
end

def strip_html(text)
  # remove HTML tags
  text = text.gsub(/<[^>]*>/, '')
  # replace common HTML entities
  text = text.gsub('&nbsp;', ' ')
             .gsub('&amp;', '&')
             .gsub('&lt;', '<')
             .gsub('&gt;', '>')
             .gsub('&quot;', '"')
             .gsub('&apos;', "'")
  text.strip
end
