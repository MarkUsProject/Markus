class AutotestSpecsJob < ApplicationJob
  include AutomatedTestsHelper
  queue_as Rails.configuration.x.queues.autotest_specs

  def self.show_status(_status)
    I18n.t('poll_job.autotest_specs_job')
  end

  def perform(host_with_port, assignment)
    run_autotester_command('specs', server_params(get_markus_address(host_with_port), assignment.id))
  end
end
