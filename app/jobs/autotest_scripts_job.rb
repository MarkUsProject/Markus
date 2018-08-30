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
    server_host = MarkusConfigurator.autotest_server_host
    server_path = MarkusConfigurator.autotest_server_dir
    server_username = MarkusConfigurator.autotest_server_username
    server_command = MarkusConfigurator.autotest_server_command
    server_params = { markus_address: markus_address, files_path: 'files_path_placeholder',
                      assignment_id: assignment_id }

    begin
      if server_username.nil?
        # files copied locally with no authentication
        server_path = Dir.mktmpdir(nil, server_path) # create temp subfolder
        FileUtils.cp_r("#{assignment_tests_path}/.", server_path) # includes hidden files
        server_params[:files_path] = server_path
        out, status = Open3.capture2e("#{server_command} scripts '#{JSON.generate(server_params)}'")
        if status.exitstatus != 0
          raise out
        else
          # TODO: use out for something?
        end
      else
        # tests executed locally or remotely with authentication
        Net::SSH.start(server_host, server_username, auth_methods: ['publickey']) do |ssh|
          server_path = ssh.exec!("mktemp -d --tmpdir='#{server_path}'").strip # create temp subfolder
          # copy all files using passwordless scp (natively, the net-scp gem has poor performance)
          Open3.capture3('scp', '-o', 'PasswordAuthentication=no', '-o', 'ChallengeResponseAuthentication=no', '-rq',
                         "#{assignment_tests_path}/.", "#{server_username}@#{server_host}:'#{server_path}'")
          server_params[:files_path] = server_path
          out = ssh.exec!("#{server_command} scripts '#{JSON.generate(server_params)}'")
          # TODO: use out for something?
        end
      end
    rescue StandardError => e
      # TODO: where to show failure?
    end
  end
end
