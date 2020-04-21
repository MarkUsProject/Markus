class AutotestCancelJob < ApplicationJob
  include AutomatedTestsHelper

  queue_as Rails.configuration.x.queues.autotest_cancel

  def self.on_complete_js(_status)
    'window.BatchTestRunTable.fetchData'
  end

  def self.show_status(_status); end

  def perform(host_with_port, assignment_id, test_run_ids)
    if Rails.application.config.action_controller.relative_url_root.nil?
      markus_address = host_with_port
    else
      markus_address = host_with_port + Rails.application.config.action_controller.relative_url_root
    end
    server_username = Rails.configuration.x.autotest.server_username
    server_command = Rails.configuration.x.autotest.server_command

    server_kwargs = server_params(markus_address, assignment_id)
    server_kwargs[:test_data] = test_data(test_run_ids)

    if server_username.nil?
      # local cancellation with no authentication
      cancel_command = [server_command, 'cancel', '-j', JSON.generate(server_kwargs)]
      output, status = Open3.capture2e(*cancel_command)
      if status.exitstatus != 0
        raise output
      end
    else
      # local or remote cancellation with authentication
      server_host = Rails.configuration.x.autotest.server_host
      Net::SSH.start(server_host, server_username, auth_methods: ['publickey']) do |ssh|
        cancel_command = "#{server_command} cancel -j '#{JSON.generate(server_kwargs)}'"
        output = ssh.exec!(cancel_command)
        if output.exitstatus != 0
          raise output
        end
      end
    end
    TestRun.find(test_run_ids).each { |test_run| test_run.update(time_to_service: -1) }
    # TODO: Use output for something?
  end
end
