# Initialize python dependencies
require 'open3'

Rails.configuration.to_prepare do
  pip_exe = File.join(Settings.python.bin, 'pip')
  if File.exist? pip_exe
    requirements = File.open(File.join(::Rails.root, 'requirements.txt')).each_line.map do |line|
      line.strip!
      line.start_with?('#') || line.length.zero? ? nil : line
    end.compact
    installed, _status = Open3.capture2("#{pip_exe} freeze")
    missing = requirements - installed.lines.map(&:chomp)
    unless missing.empty?
      warn "MARKUS WARNING: Python environment at #{Settings.python.bin} " \
           "missing the following required packages:\n\t#{requirements.join("\n\t")}"
    end
  else
    warn "MARKUS WARNING: No python/pip executable found at #{Settings.python.bin}. Python code cannot be run."
  end
end
