require 'timeout'
require 'httparty'

module AutomatedTestsServerHelper
  # This is the waiting list for automated testing on the test server. Once a test is requested, it is enqueued
  # and it is waiting for execution. Resque manages this queue.
  @queue = MarkusConfigurator.markus_ate_tests_queue_name
  TIME_LIMIT = 600

  def self.get_test_scripts_chmod(test_scripts, tests_path)
    return test_scripts.map {|script| "chmod ugo+x '#{tests_path}/#{script}'"}.join('; ')
  end

  # the user running this Resque worker should be:
  # a) the user running MarkUs if ATE_SERVER_HOST == 'localhost'
  # b) ATE_SERVER_FILES_USERNAME otherwise
  def self.perform(markus_address, user_api_key, server_api_key, test_username, test_scripts, files_path, tests_path,
                   results_path, assignment_id, group_id, submission_id)

    # move files to the test location (if needed)
    test_scripts_executables = get_test_scripts_chmod(test_scripts, tests_path)
    if files_path != tests_path
      FileUtils.mkdir_p(tests_path, {mode: 0777}) # create tests dir if not already existing..
      FileUtils.cp_r("#{files_path}/.", tests_path) # == cp -r '#{files_path}'/* '#{tests_path}'
      FileUtils.rm_rf(files_path)
    end
    Open3.capture3(test_scripts_executables)

    # run tests
    all_output = '<testrun>'
    all_errors = ''
    test_scripts.each do |script|
      run_command = "cd '#{tests_path}'; ./'#{script}' #{markus_address} #{user_api_key} #{assignment_id} #{group_id}"
      unless test_username.nil?
        run_command = "sudo -u #{test_username} -- bash -c \"#{run_command}\""
      end
      output = ''
      errors = ''
      Open3.popen3(run_command, pgroup: true) do |stdin, stdout, stderr, thread|
        # mimic capture3 to read safely
        stdout_thread = Thread.new { stdout.read }
        stderr_thread = Thread.new { stderr.read }
        if !thread.join(TIME_LIMIT) # still running, let's kill the process group
          if test_username.nil?
            Process.kill('KILL', -thread.pid)
          else
            Open3.capture3("sudo -u #{test_username} -- bash -c \"kill -KILL -#{thread.pid}\"")
          end
          # timeout output
          output = '
            <test>
              <name>All tests</name>
              <input></input>
              <expected></expected>
              <actual>Timeout</actual>
              <marks_earned>0</marks_earned>
              <status>error</status>
            </test>'
        else
          # normal output
          output = stdout_thread.value
        end
        # always collect errors
        errors = stderr_thread.value
      end
      all_output += "
        <test_script>
          <script_name>#{script}</script_name>
          #{output}
        </test_script>"
      all_errors += errors
    end
    all_output += "\n</testrun>"

    # store results
    results_path = File.join(results_path, markus_address.gsub('/', '_'), "a#{assignment_id}", "g#{group_id}",
                             "s#{submission_id}", "run_#{Time.now.to_i}")
    FileUtils.mkdir_p(results_path)
    File.write("#{results_path}/output.txt", all_output)
    File.write("#{results_path}/errors.txt", all_errors)

    # cleanup
    if test_username.nil?
      FileUtils.rm_rf(tests_path)
    else
      Open3.capture3("sudo -u #{test_username} -- bash -c \"rm -rf '#{tests_path}'; killall -KILL -u #{test_username}\"")
    end

    # send results back to markus by api
    api_url = "#{markus_address}/api/assignments/#{assignment_id}/groups/#{group_id}/test_script_results"
    # HTTParty needs strings as hash keys, or it chokes
    options = {:headers => {
                   'Authorization' => "MarkUsAuth #{server_api_key}",
                   'Accept' => 'application/json'},
               :body => {
                   'test_scripts' => test_scripts,
                   'file_content' => all_output}}
    unless submission_id.nil?
      options[:body]['submission_id'] = submission_id
    end
    HTTParty.post(api_url, options)
  end

end