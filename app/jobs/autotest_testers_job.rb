class AutotestTestersJob < ApplicationJob
  queue_as Rails.configuration.x.queues.autotest_testers

  def self.show_status(_status); end

  def perform
    server_username = Rails.configuration.x.autotest.server_username
    server_command = Rails.configuration.x.autotest.server_command

    begin
      if server_username.nil?
        # local fetch testers with no authentication
        testers_command = [server_command, 'schema']
        output, status = Open3.capture2e(*testers_command)
        if status.exitstatus != 0
          raise output
        end
      else
        # local or remote fetch testers with authentication
        server_host = Rails.configuration.x.autotest.server_host
        Net::SSH.start(server_host, server_username, auth_methods: ['publickey']) do |ssh|
          testers_command = "#{server_command} schema"
          output = ssh.exec!(testers_command)
          if output.exitstatus != 0
            raise output
          end
        end
      end
      testers_path = File.join(Rails.configuration.x.autotest.client_dir, 'testers.json')
      File.open(testers_path, 'w') { |f| f.write(output) }
    end
  end
end
