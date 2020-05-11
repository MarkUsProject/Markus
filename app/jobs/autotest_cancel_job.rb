class AutotestCancelJob < ApplicationJob
  include AutomatedTestsHelper

  queue_as Rails.configuration.x.queues.autotest_cancel

  def self.on_complete_js(_status)
    'window.BatchTestRunTable.fetchData'
  end

  def self.show_status(_status); end

  def perform(host_with_port, assignment_id, test_run_ids)
    server_kwargs = server_params(get_markus_address(host_with_port), assignment_id)
    server_kwargs[:test_data] = test_data(test_run_ids)
    run_autotester_command('cancel', server_kwargs)
    TestRun.find(test_run_ids).each { |test_run| test_run.update(time_to_service: -1) }
    # TODO: Use output for something?
  end
end
