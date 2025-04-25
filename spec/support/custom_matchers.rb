# :nocov:
RSpec::Matchers.define :have_message do |expected|
  match do |actual|
    actual_messages = Array(actual).map { |m| extract_text(m.to_s) }
    actual_messages.any? { |m| m.strip == extract_text(expected).strip }
  end

  failure_message do |actual|
    actual_stripped = Array(actual).map { |m| extract_text(m.to_s) }
    "expected that #{actual_stripped.inspect} would exactly match message #{expected.inspect}"
  end
end
# :nocov:

# :nocov:
RSpec::Matchers.define :contain_message do |expected|
  match do |actual|
    actual_messages = Array(actual).map { |m| extract_text(m.to_s) }
    actual_messages.any? { |m| m.include?(extract_text(expected)) }
  end

  failure_message do |actual|
    actual_stripped = Array(actual).map { |m| extract_text(m.to_s) }
    "expected that #{actual_stripped.inspect} would contain message #{expected.inspect}"
  end
end
# :nocov:
