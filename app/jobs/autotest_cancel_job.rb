class AutotestCancelJob < ApplicationJob
  queue_as Rails.configuration.x.queues.autotest_cancel

  def self.on_complete_js(_status)
    'window.BatchTestRunTable.fetchData'
  end

  def self.show_status(_status); end

  def perform(host_with_port, test_run_ids)
    if Rails.application.config.action_controller.relative_url_root.nil?
      markus_address = host_with_port
    else
      markus_address = host_with_port + Rails.application.config.action_controller.relative_url_root
    end
    server_username = Rails.configuration.x.autotest.server_username
    server_command = Rails.configuration.x.autotest.server_command
    server_params = { markus_address: markus_address, run_ids: test_run_ids }

    if server_username.nil?
      # local cancellation with no authentication
      cancel_command = [server_command, 'cancel', '-j', JSON.generate(server_params)]
      output, status = Open3.capture2e(*cancel_command)
      if status.exitstatus != 0
        raise output
      end
    else
      # local or remote cancellation with authentication
      server_host = Rails.configuration.x.autotest.server_host
      Net::SSH.start(server_host, server_username, auth_methods: ['publickey']) do |ssh|
        cancel_command = "#{server_command} cancel -j '#{JSON.generate(server_params)}'"
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
