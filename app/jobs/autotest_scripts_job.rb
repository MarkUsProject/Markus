class AutotestScriptsJob < ApplicationJob
  queue_as MarkusConfigurator.autotest_scripts_queue

  def perform(host_with_port, assignment_id)
    assignment = Assignment.find(assignment_id)
    assignment_tests_path = File.join(AutomatedTestsClientHelper::ASSIGNMENTS_DIR, assignment.short_identifier)
    markus_address = Rails.application.config.action_controller.relative_url_root.nil? ?
                       host_with_port :
                       host_with_port + Rails.application.config.action_controller.relative_url_root
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
        out, err, status = Open3.capture3("#{server_command} scripts '#{JSON.generate(server_params)}'")
      else
        # tests executed locally or remotely with authentication
        Net::SSH.start(server_host, server_username, auth_methods: ['publickey']) do |ssh|
          server_path = ssh.exec!("mktemp -d --tmpdir='#{server_path}'").strip # create temp subfolder
          # copy all files using passwordless scp (natively, the net-scp gem has poor performance)
          scp_command = "scp -o PasswordAuthentication=no -o ChallengeResponseAuthentication=no -rq "\
                        "'#{assignment_tests_path}'/. #{server_username}@#{server_host}:'#{server_path}'"
          Open3.capture3(scp_command)
          server_params[:files_path] = server_path
          out = ssh.exec!("#{server_command} scripts '#{JSON.generate(server_params)}'")
        end
      end
      # TODO use out for feedback, and possibly look at err+status
    rescue Exception => e
      # TODO
    end
  end
end
