# Checks that a MarkUs installation is configured correctly.
#
# Run with: bundle exec rake markus:check
class InstallationCheck
  def initialize(output: $stdout)
    @output = output
    @failures = 0
  end

  # Runs all checks, printing the result of each one. Returns true if every check passed.
  def run
    check_paths
    check_logout_redirect
    @failures.zero?
  end

  private

  def pass(message)
    @output.puts "[PASS] #{message}"
  end

  def failure(message)
    @failures += 1
    @output.puts "[FAIL] #{message}"
  end

  def check_paths
    check_directory(File.dirname(Settings.logging.log_file), 'logging.log_file')
    Settings.file_storage.each do |key, path|
      check_directory(path, "file_storage.#{key}") unless path.nil?
    end
  end

  # Checks that MarkUs can create and access files in the directory +path+ (relative paths are relative to
  # the MarkUs root). If the directory does not exist yet, checks its parent directory (where the directory
  # would be created) instead, and fails if the parent directory does not exist either.
  def check_directory(path, setting)
    dir = Rails.root.join(path)
    dir = dir.parent unless dir.exist?
    unless dir.directory?
      failure "#{setting}: neither #{Rails.root.join(path)} nor its parent directory exists"
      return
    end
    missing = %w[readable writable executable].reject { |permission| File.public_send(:"#{permission}?", dir) }
    if missing.empty?
      pass "#{setting}: #{dir}"
    else
      failure "#{setting}: #{dir} is not #{missing.to_sentence}"
    end
  end

  def check_logout_redirect
    logout_redirect = Settings.logout_redirect
    if %w[DEFAULT NONE].include?(logout_redirect) || http_url?(logout_redirect)
      pass "logout_redirect: #{logout_redirect}"
    else
      failure "logout_redirect: #{logout_redirect} is invalid. Only 'DEFAULT', 'NONE' or a valid http:// " \
              'or https:// URL are valid values.'
    end
  end

  # Returns whether +url+ is a valid absolute http or https URL
  def http_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end
end
