require 'open3'

# Checks that a MarkUs installation is configured correctly, and that the external dependencies required by
# each enabled optional feature are installed.
#
# Run with: bundle exec rake markus:check
class InstallationCheck
  # A minimal Jupyter notebook used to check that notebooks can be converted
  TEST_NOTEBOOK = {
    cells: [{ cell_type: 'markdown', metadata: {}, source: ['MarkUs installation check'] }],
    metadata: {},
    nbformat: 4,
    nbformat_minor: 4
  }.to_json.freeze

  def initialize(output: $stdout)
    @output = output
    @failures = 0
  end

  # Runs all checks, printing the result of each one. Returns true if every check passed.
  def run
    check_paths
    check_logout_redirect
    check_feature('scanned_exams.enabled', Settings.scanned_exams.enabled) { check_scanned_exams }
    check_feature('nbconvert_enabled', Rails.application.config.nbconvert_enabled) { check_nbconvert }
    check_feature('rmd_convert_enabled', Rails.application.config.rmd_convert_enabled) do
      check_command('rmd_convert_enabled', 'pandoc is installed', 'pandoc', '--version')
    end
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

  def skip(message)
    @output.puts "[SKIP] #{message}"
  end

  def check_paths
    check_directory(File.dirname(Settings.logging.log_file), 'logging.log_file')
    check_directory(File.dirname(Settings.logging.error_file), 'logging.error_file')
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

  # Runs the checks for the optional feature enabled by +setting+, or skips them if the feature is disabled
  def check_feature(setting, enabled)
    if enabled
      yield
    else
      skip "#{setting}: disabled"
    end
  end

  def check_scanned_exams
    setting = 'scanned_exams.enabled'
    return unless check_python(setting)

    check_python_requirements(setting, 'requirements-scanner.txt')
    check_command(setting, 'markus_exam_matcher can be imported', python, '-c', 'import markus_exam_matcher')
  end

  def check_nbconvert
    setting = 'nbconvert_enabled'
    return unless check_python(setting)

    check_python_requirements(setting, 'requirements-jupyter.txt')
    Dir.mktmpdir do |dir|
      check_command(setting, 'nbconvert can convert notebooks to HTML',
                    python, '-m', 'nbconvert', '--to', 'html', '--stdin', '--output', File.join(dir, 'notebook'),
                    "--TemplateExporter.extra_template_basedirs=#{Rails.root.join('lib/jupyter-notebook')}",
                    '--template', 'markus-html-template',
                    stdin_data: TEST_NOTEBOOK)
      check_command(setting, 'nbconvert can convert notebooks to PDF',
                    python, '-m', 'nbconvert', '--to', 'webpdf', '--stdin', '--output', File.join(dir, 'notebook'),
                    stdin_data: TEST_NOTEBOOK,
                    hint: 'Make sure Chromium and its system dependencies are installed for Playwright: ' \
                          "#{python} -m playwright install chromium (and, as root, " \
                          "#{python} -m playwright install-deps chromium)")
    end
  end

  def python
    Rails.application.config.python
  end

  # Checks that the configured Python executable can be run. Returns true if it can.
  def check_python(setting)
    check_command(setting, "Python executable can be run: #{python}", python, '--version',
                  hint: "Set the python setting to the path of the Python executable where MarkUs's " \
                        'Python dependencies are installed')
  end

  def check_python_requirements(setting, requirements_file)
    installed = installed_python_packages(setting)
    return if installed.nil?

    problems = parse_requirements(Rails.root.join(requirements_file)).filter_map do |name, version|
      installed_version = installed[normalize_package_name(name)]
      if installed_version.nil?
        "#{name} is not installed"
      elsif version && installed_version != version
        "#{name} #{installed_version} is installed but #{version} is required"
      end
    end
    if problems.empty?
      pass "#{setting}: Python packages in #{requirements_file} are installed"
    else
      failure "#{setting}: Python packages in #{requirements_file} are not installed correctly: " \
              "#{problems.join('; ')}. To fix this, run: #{python} -m pip install -r " \
              "#{Rails.root.join(requirements_file)}"
    end
  end

  # Returns a hash mapping the (normalized) name of each package installed in the Python environment
  # to its version, or nil if the installed packages could not be determined.
  def installed_python_packages(setting)
    script = 'import importlib.metadata, json; ' \
             'print(json.dumps({d.metadata["Name"]: d.version for d in importlib.metadata.distributions() ' \
             'if d.metadata["Name"]}))'
    stdout, stderr, status = Open3.capture3(python, '-c', script)
    unless status.success?
      failure "#{setting}: Could not list installed Python packages: #{stderr.lines.last&.strip}"
      return
    end
    JSON.parse(stdout).transform_keys { |name| normalize_package_name(name) }
  end

  # Returns a list of [package name, pinned version] pairs from a pip requirements file.
  # The version is nil if the requirement is not pinned to an exact version.
  def parse_requirements(requirements_file)
    File.readlines(requirements_file).filter_map do |line|
      line = line.sub(/#.*/, '').strip
      next if line.empty? || line.start_with?('-')

      match = line.match(/\A([A-Za-z0-9][A-Za-z0-9._-]*)(?:\[[^\]]*\])?\s*(?:==\s*([^\s;,]+))?/)
      [match[1], match[2]] unless match.nil?
    end
  end

  # Normalizes a Python package name as described in PEP 503
  def normalize_package_name(name)
    name.downcase.gsub(/[-_.]+/, '-')
  end

  # Runs +command+ and reports whether it succeeded. Returns true if it succeeded.
  def check_command(setting, description, *command, stdin_data: '', hint: nil)
    _stdout, stderr, status = Open3.capture3(*command, stdin_data: stdin_data)
    if status.success?
      pass "#{setting}: #{description}"
      return true
    end
    failure_with_details("#{setting}: #{description}", stderr.lines.last&.strip, hint)
    false
  rescue SystemCallError => e
    failure_with_details("#{setting}: #{description}", e.message, hint)
    false
  end

  def failure_with_details(*messages)
    failure messages.compact_blank.map { |message| message.chomp('.') }.join('. ')
  end
end
