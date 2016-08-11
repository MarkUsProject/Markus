require 'timeout'
require 'httpparty'

module AutomatedTestsServerHelper
  # This is the waiting list for automated testing on the test server. Once a test is requested, it is enqueued
  # and it is waiting for execution. Resque manages this queue.
  @queue = MarkusConfigurator.markus_ate_test_queue_name
  TIME_LIMIT = 600

  def perform(test_scripts, test_path, test_results_path, auth_key, grouping_id, submission_id = nil)

    # run tests
    output = '<testrun>\n'
    errors = ''
    test_scripts.each do |script|
      begin
        # TODO make executable?
        # file = File.new(script)
        # file.chmod(0766)
        # TODO The time limit is handled by pam too
        Timeout.timeout(TIME_LIMIT) do
          stdout, stderr, status = Open3.capture3("
            cd '#{test_path}' &&
            ./#{script}
          ")
          errors += stderr
        end
      rescue Timeout::Error
        Process.kill(9, status.pid)
        stdout = '
          <test>\n
            <actual>Script timeout</actual>\n
            <status>error</status>\n
          </test>\n'
      end
      output += "
        <test_script>\n
          <script_name>#{script}</script_name>\n
          #{stdout}\n
        </test_script>\n"
    end
    output += '</testrun>'

    # store results and send them back to markus
    test_results_path = File.join(test_results_path, "test_run_#{Time.now.to_i}")
    FileUtils.mkdir_p(test_results_path)
    File.write("#{test_results_path}/output.txt", output)
    File.write("#{test_results_path}/error.txt", errors)
    # Test scripts must now use calls to the MarkUs API to process results.
    # process_result(stdout, call_on, assignment, grouping, submission)
    # api_url = "#{grouping_id}/#{submission_id}"
    # options = { headers: { 'Authorization' => "MarkUsAuth #{auth_key}",
    #                        'Accept' => 'application/json' } }
    # response = HTTParty.post(api_url, options)
  end

end