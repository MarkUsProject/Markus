class AutotestTestersJob < ApplicationJob
  queue_as MarkusConfigurator.autotest_testers_queue

  def self.show_status(_status); end

  def perform
    server_username = MarkusConfigurator.autotest_server_username
    server_command = MarkusConfigurator.autotest_server_command

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
        server_host = MarkusConfigurator.autotest_server_host
        Net::SSH.start(server_host, server_username, auth_methods: ['publickey']) do |ssh|
          testers_command = "#{server_command} schema"
          output = ssh.exec!(testers_command)
          if output.exitstatus != 0
            raise output
          end
        end
      end
      testers_path = File.join(MarkusConfigurator.autotest_client_dir, 'testers.json')
      File.open(testers_path, 'w') { |f| f.write(output) }
    end
  end
end
