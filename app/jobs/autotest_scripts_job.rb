class AutotestScriptsJob < ApplicationJob
  queue_as MarkusConfigurator.autotest_scripts_queue

  def perform(host_with_port, assignment_id)
    assignment = Assignment.find(assignment_id)
    assignment_tests_path = File.join(AutomatedTestsClientHelper::ASSIGNMENTS_DIR, assignment.short_identifier)
    if Rails.application.config.action_controller.relative_url_root.nil?
      markus_address = host_with_port
    else
      markus_address = host_with_port + Rails.application.config.action_controller.relative_url_root
    end
    server_path = MarkusConfigurator.autotest_server_dir
    server_username = MarkusConfigurator.autotest_server_username
    server_command = MarkusConfigurator.autotest_server_command
    server_params = { markus_address: markus_address, assignment_id: assignment_id }

    begin
      if server_username.nil?
        # files copied locally with no authentication
        server_path = Dir.mktmpdir(nil, server_path) # create temp subfolder
        FileUtils.cp_r("#{assignment_tests_path}/.", server_path) # includes hidden files
        server_params[:files_path] = server_path
        scripts_command = [server_command, 'scripts', '-j', JSON.generate(server_params)]
        output, status = Open3.capture2e(*scripts_command)
        if status.exitstatus != 0
          raise output
        end
      else
        # tests executed locally or remotely with authentication
        server_host = MarkusConfigurator.autotest_server_host
        Net::SSH.start(server_host, server_username, auth_methods: ['publickey']) do |ssh|
          mkdir_command = "mktemp -d --tmpdir='#{server_path}'"
          server_path = ssh.exec!(mkdir_command).strip # create temp subfolder
          # copy all files using rsync
          rsync_command = ['rsync', '-a',
                           "#{assignment_tests_path}/.", "#{server_username}@#{server_host}:#{server_path}"]
          Open3.capture3(*rsync_command)
          server_params[:files_path] = server_path
          scripts_command = "#{server_command} scripts -j '#{JSON.generate(server_params)}'"
          output = ssh.exec!(scripts_command)
          if output.exitstatus != 0
            raise output
          end
        end
      end
      # TODO: Use output for something?
    rescue StandardError => e
      # TODO: Where to show failure?
    end
  end
end
