class AutotestSpecsJob < ApplicationJob
  include AutomatedTestsHelper
  queue_as Rails.configuration.x.queues.autotest_specs

  def self.show_status(_status)
    I18n.t('poll_job.autotest_specs_job')
  end

  def perform(host_with_port, assignment)
    if Rails.application.config.action_controller.relative_url_root.nil?
      markus_address = host_with_port
    else
      markus_address = host_with_port + Rails.application.config.action_controller.relative_url_root
    end
    server_username = Rails.configuration.x.autotest.server_username
    server_command = Rails.configuration.x.autotest.server_command
    server_params =  { client_type: :markus,
                       url: markus_address,
                       assignment_id: assignment.id,
                       api_key: get_server_api_key }

    begin
      if server_username.nil?
        # files copied locally with no authentication
        scripts_command = [server_command, 'specs', '-j', JSON.generate(server_params)]
        output, status = Open3.capture2e(*scripts_command)
        if status.exitstatus != 0
          raise output
        end
      else
        # tests executed locally or remotely with authentication
        server_host = Rails.configuration.x.autotest.server_host
        Net::SSH.start(server_host, server_username, auth_methods: ['publickey']) do |ssh|
          scripts_command = "#{server_command} specs -j '#{JSON.generate(server_params)}'"
          output = ssh.exec!(scripts_command)
          if output.exitstatus != 0
            raise output
          end
        end
      end
      # TODO: Use output for something?
    end
  end
end
