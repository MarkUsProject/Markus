class AutotestCancelJob < ApplicationJob
  queue_as MarkusConfigurator.autotest_cancel_queue

  def perform(host_with_port, test_run_ids)
    if Rails.application.config.action_controller.relative_url_root.nil?
      markus_address = host_with_port
    else
      markus_address = host_with_port + Rails.application.config.action_controller.relative_url_root
    end
    server_host = MarkusConfigurator.autotest_server_host
    server_username = MarkusConfigurator.autotest_server_username
    server_command = MarkusConfigurator.autotest_server_command
    server_params = { markus_address: markus_address, run_ids: test_run_ids }
    cancel_command = "#{server_command} cancel '#{JSON.generate(server_params)}'"

    begin
      if server_username.nil?
        # local cancellation with no authentication
        out, status = Open3.capture2e(cancel_command)
        if status.exitstatus != 0
          raise out
        else
          # TODO: use out for something?
        end
      else
        # local or remote cancellation with authentication
        Net::SSH.start(server_host, server_username, auth_methods: ['publickey']) do |ssh|
          out = ssh.exec!(cancel_command)
          # TODO: use out for something?
        end
      end
    rescue StandardError => e
      # TODO: where to show failure?
    ensure
      TestRun.find(test_run_ids).each { |test_run| test_run.update_attributes!(time_to_service: -1) }
    end
  end
end
