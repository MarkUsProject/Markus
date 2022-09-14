# Initialize python dependencies
require 'open3'

Rails.configuration.after_initialize do
  pip_exe = File.join(Settings.python.bin, 'pip')

  def process_requirements(requirements_file)
    File.open(requirements_file).each_line.map do |line|
      line.strip!
      line.start_with?('#') || line.length.zero? ? nil : line
    end.compact
  end

  if File.exist? pip_exe
    installed, status = Open3.capture2("#{pip_exe} freeze")
    if status.success?
      installed = installed.lines.map(&:chomp)

      jupyter_requirements = process_requirements(Rails.root.join('requirements-jupyter.txt'))
      scanner_requirements = process_requirements(Rails.root.join('requirements-scanner.txt'))

      if (jupyter_requirements - installed).empty?
        Rails.application.config.nbconvert_enabled = true
      else
        warn 'MARKUS WARNING: not all packages required to process jupyter notebooks are installed. ' \
             'Jupyter notebook rendering will be disabled. ' \
             "To enable notebook rendering run: #{pip_exe} install -r #{Rails.root.join('requirements-jupyter.txt')}"
      end
      if (scanner_requirements - installed).empty?
        Rails.application.config.scanner_enabled = true
      else
        warn 'MARKUS WARNING: not all packages required to automatically match students for scanned exams ' \
             'are installed. Automatic student matching will be disabled. ' \
             'To enable automatic student matching  run: ' \
             "#{pip_exe} install -r #{Rails.root.join('requirements-scanner.txt')}"
      end
    else
      warn "MARKUS WARNING: '#{pip_exe} freeze' failed with: #{installed}. Python code cannot be run."
    end
  else
    warn "MARKUS WARNING: No python/pip executable found at #{Settings.python.bin}. Python code cannot be run."
  end
end
