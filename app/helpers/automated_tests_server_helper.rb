require 'timeout'
require 'httparty'

module AutomatedTestsServerHelper
  # This is the waiting list for automated testing on the test server. Once a test is requested, it is enqueued
  # and it is waiting for execution. Resque manages this queue.
  @queue = MarkusConfigurator.markus_ate_test_queue_name
  TIME_LIMIT = 600

  def self.perform(markus_address, api_key, test_scripts, test_path, test_results_path, call_on, assignment_id, group_id)

    # run tests
    output = '<testrun>'
    errors = ''
    test_scripts.each do |script|
      begin
        stdout = ''
        Timeout.timeout(TIME_LIMIT) do
          stdout, stderr, status = Open3.capture3("
            cd '#{test_path}' &&
            ./'#{script}'
          ")
          errors += stderr
        end
      rescue Timeout::Error
        Process.kill(9, status.pid)
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
    test_results_path = File.join(test_results_path, "test_run_#{Time.now.to_i}")
    FileUtils.mkdir_p(test_results_path)
    File.write("#{test_results_path}/output.txt", output)
    File.write("#{test_results_path}/error.txt", errors)
    FileUtils.rm_rf(test_path)
    # TODO What about UTORid auth, how do I get the cookie?
    api_url = "#{markus_address}/api/assignments/#{assignment_id}/groups/#{group_id}/test_script_results"
    # HTTParty needs strings as hash keys, or it chokes
    options = {:headers => {
                   'Authorization' => "MarkUsAuth #{api_key}",
                   'Accept' => 'application/json'},
               :body => {
                   'assignment_id' => assignment_id,
                   'group_id' => group_id,
                   'call_on' => call_on,
                   'file_content' => output}}
    HTTParty.post(api_url, options)
  end

end