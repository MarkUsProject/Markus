class AutotestTestersJob < ApplicationJob
  include AutomatedTestsHelper

  def self.show_status(_status); end

  def perform
    testers_path = File.join(Settings.autotest.client_dir, 'testers.json')
    output = run_autotester_command('schema', {})
    File.open(testers_path, 'w') { |f| f.write(output) }
  end
end
