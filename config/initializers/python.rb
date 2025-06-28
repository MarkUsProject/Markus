# Initialize python dependencies
require 'open3'

Rails.application.config.after_initialize do
  # Initialize this as explicitly false
  Rails.application.config.scanner_enabled = false
  Rails.application.config.nbconvert_enabled = false

  if Settings.python
    Rails.application.config.python = Settings.python
  else
    warn 'MARKUS WARNING: No python executable can be found in settings (under "python:"). ' \
         'The default python3 executable will be used instead.'
    Rails.application.config.python = 'python3'
  end

  def process_requirements(requirements_file)
    File.open(requirements_file).each_line.filter_map do |line|
      line.strip!
      line.tr!('-_', '')
      line.start_with?('#') || line.length.zero? ? nil : line
    end
  end

  begin
    installed, status = Open3.capture2(Rails.application.config.python, '-m', 'pip', 'freeze')
  rescue Errno::ENOENT
    warn 'MARKUS WARNING: No python3 executable can be found. Jupyter notebook rendering ' \
         'and Automatic student matching will be disabled. Install python3 to enable these features.'
  else
    pip = "#{Rails.application.config.python} -m pip"

    if status.success?
      installed = installed.lines.map(&:chomp)
      installed.each { |p| p.tr!('-_', '') }

      jupyter_requirements = process_requirements(Rails.root.join('requirements-jupyter.txt'))
      scanner_requirements = process_requirements(Rails.root.join('requirements-scanner.txt'))

      if (jupyter_requirements - installed).empty?
        Rails.application.config.nbconvert_enabled = true
      else
        warn 'MARKUS WARNING: not all packages required to process jupyter notebooks are installed. ' \
             'Jupyter notebook rendering will be disabled. ' \
             "To enable notebook rendering run: #{pip} install -r #{Rails.root.join('requirements-jupyter.txt')}"
      end
      if (scanner_requirements - installed).empty?
        Rails.application.config.scanner_enabled = true
      else
        warn 'MARKUS WARNING: not all packages required to process scanned exams and automatically match students ' \
             'for scanned exams are installed. Exam scanning will not be enabled and automatic student matching will ' \
             'be disabled. To enable exam scanning and automatic student matching run: ' \
             "#{pip} install -r #{Rails.root.join('requirements-scanner.txt')}"
      end
    else
      warn "MARKUS WARNING: '#{pip} freeze' failed with: #{installed}. Python code cannot be run."
    end
  end
end
