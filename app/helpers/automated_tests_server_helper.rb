require 'timeout'
require 'httparty'

module AutomatedTestsServerHelper
  # This is the waiting list for automated testing on the test server. Once a test is requested, it is enqueued
  # and it is waiting for execution. Resque manages this queue.
  @queue = MarkusConfigurator.markus_ate_tests_queue_name
  TIME_LIMIT = 600

  def self.get_test_scripts_chmod(test_scripts, tests_path)
    return test_scripts.map {|script| "chmod ug+x '#{tests_path}/#{script}'"}.join('; ')
  end

  # the user running this Resque worker should be:
  # a) the user running MarkUs if ATE_SERVER_HOST == 'localhost'
  # b) ATE_SERVER_FILES_USERNAME otherwise
  def self.perform(markus_address, user_api_key, server_api_key, test_username, test_scripts, files_path, tests_path,
                   results_path, assignment_id, group_id, submission_id)

    # move files to the test location (if needed)
    test_scripts_executables = get_test_scripts_chmod(test_scripts, tests_path)
    if files_path != tests_path
      if test_username.nil? # no auth or same user
        FileUtils.mkdir_p(tests_path, {mode: 0700}) # create tests dir if not already existing..
        #TODO tests_path = Dir.mktmpdir(nil, tests_path) # ..then create temp subfolder
        FileUtils.cp_r("#{files_path}/.", tests_path) # == cp -r '#{files_path}'/* '#{tests_path}'
        Open3.capture2("#{test_scripts_executables}")
      else # need sudo
        Open3.capture2("sudo -u #{test_username} -- bash -c \"mkdir -m 700 -p '#{tests_path}'\"")
        #TODO tests_path, status = Open3.capture2("sudo -u #{test_username} -- bash -c \"mktemp -d --tmpdir='#{tests_path}'\"").strip
        Open3.capture2("sudo -u #{test_username} -- bash -c \"cp -r '#{files_path}'/* '#{tests_path}'\"")
        Open3.capture2("sudo -u #{test_username} -- bash -c \"#{test_scripts_executables}\"")
      end
      FileUtils.rm_rf(files_path)
    else
      Open3.capture2("#{test_scripts_executables}")
    end

    # run tests
    output = '<testrun>'
    errors = ''
    test_scripts.each do |script|
      run_command = "cd '#{tests_path}'; ./'#{script}'"
      unless test_username.nil?
        run_command = "sudo -u #{test_username} -- bash -c \"#{run_command}\""
      end
      stdout = ''
      status = nil
      begin
        Timeout.timeout(TIME_LIMIT) do
          stdout, stderr, status = Open3.capture3(
            {'MARKUS_ADDRESS' => "#{markus_address}", 'API_KEY' => "#{user_api_key}",
             'ASSIGNMENT_ID' => "#{assignment_id}", 'GROUP_ID' => "#{group_id}"}, # needs strings as hash keys and values for env variables
            run_command)
          errors += stderr
        end
      rescue Timeout::Error
        if test_username.nil?
          Process.kill(9, status.pid)
        else
          Open3.capture2("sudo -u #{test_username} -- bash -c \"kill -9 #{status.pid}\"")
        end
        stdout = '
          <test>
            <actual>Script timeout</actual>
            <status>error</status>
          </test>'
      end
      output += "
        <test_script>
          <script_name>#{script}</script_name>
          #{stdout}
        </test_script>"
    end
    output += "\n</testrun>"

    # store results and send them back to markus through its api
    results_path = File.join(results_path, markus_address.gsub('/', '_'), "a#{assignment_id}", "g#{group_id}",
                             "s#{submission_id}", "run_#{Time.now.to_i}")
    FileUtils.mkdir_p(results_path)
    File.write("#{results_path}/output.txt", output)
    File.write("#{results_path}/error.txt", errors)
    if test_username.nil?
      FileUtils.rm_rf(tests_path)
    else
      Open3.capture2("sudo -u #{test_username} -- bash -c \"rm -rf #{tests_path}\"")
    end
    # TODO What about UTORid auth, how do I get the cookie?
    api_url = "#{markus_address}/api/assignments/#{assignment_id}/groups/#{group_id}/test_script_results"
    # HTTParty needs strings as hash keys, or it chokes
    options = {:headers => {
                   'Authorization' => "MarkUsAuth #{server_api_key}",
                   'Accept' => 'application/json'},
               :body => {
                   'assignment_id' => assignment_id,
                   'group_id' => group_id,
                   'file_content' => output}}
    unless submission_id.nil?
      options[:body]['submission_id'] = submission_id
    end
    HTTParty.post(api_url, options)
  end

end