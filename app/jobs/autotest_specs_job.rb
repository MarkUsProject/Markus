class AutotestSpecsJob < ApplicationJob
  include AutomatedTestsHelper
  queue_as Rails.configuration.x.queues.autotest_specs

  def self.show_status(_status)
    I18n.t('poll_job.autotest_specs_job')
  end

  def perform(host_with_port, assignment)
    assignment_tests_path = assignment.autotest_files_dir
    if Rails.application.config.action_controller.relative_url_root.nil?
      markus_address = host_with_port
    else
      markus_address = host_with_port + Rails.application.config.action_controller.relative_url_root
    end
    server_path = Rails.configuration.x.autotest.server_dir
    server_username = Rails.configuration.x.autotest.server_username
    server_command = Rails.configuration.x.autotest.server_command
    test_specs_path = assignment.autotest_settings_file
    test_specs = JSON.parse(File.read(test_specs_path))
    server_params = { markus_address: markus_address, assignment_id: assignment.id, test_specs: test_specs }

    schema_file = File.join(Rails.configuration.x.autotest.client_dir, 'testers.json')
    if File.exist? schema_file
      schema_data = JSON.parse(File.open(schema_file, &:read))
      fill_in_schema_data!(schema_data, assignment.autotest_files, assignment)
      server_params[:schema] = schema_data
    end

    begin
      if server_username.nil?
        # files copied locally with no authentication
        server_path = Dir.mktmpdir(nil, server_path) # create temp subfolder
        FileUtils.cp_r("#{assignment_tests_path}/.", server_path) # includes hidden files
        server_params[:files_path] = server_path
        scripts_command = [server_command, 'specs', '-j', JSON.generate(server_params)]
        output, status = Open3.capture2e(*scripts_command)
        if status.exitstatus != 0
          raise output
        end
      else
        # tests executed locally or remotely with authentication
        server_host = Rails.configuration.x.autotest.server_host
        Net::SSH.start(server_host, server_username, auth_methods: ['publickey']) do |ssh|
          mkdir_command = "mktemp -d --tmpdir='#{server_path}'"
          server_path = ssh.exec!(mkdir_command).strip # create temp subfolder
          # copy all files using rsync
          rsync_command = ['rsync', '-a',
                           "#{assignment_tests_path}/.", "#{server_username}@#{server_host}:#{server_path}"]
          Open3.capture3(*rsync_command)
          server_params[:files_path] = server_path
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
