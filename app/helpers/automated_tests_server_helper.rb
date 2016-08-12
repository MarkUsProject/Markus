require 'timeout'
require 'httpparty'

module AutomatedTestsServerHelper
  # This is the waiting list for automated testing on the test server. Once a test is requested, it is enqueued
  # and it is waiting for execution. Resque manages this queue.
  @queue = MarkusConfigurator.markus_ate_test_queue_name
  TIME_LIMIT = 600

  def perform(markus_address, api_key, test_scripts, test_path, test_results_path, assignment_id, group_id)

    # run tests
    output = '<testrun>\n'
    errors = ''
    test_scripts.each do |script|
      begin
        # TODO make executable?
        # file = File.new(script)
        # file.chmod(0766)
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

    # store results and send them back to markus through its api
    test_results_path = File.join(test_results_path, "test_run_#{Time.now.to_i}")
    FileUtils.mkdir_p(test_results_path)
    File.write("#{test_results_path}/output.txt", output)
    File.write("#{test_results_path}/error.txt", errors)
    # TODO What about UTORid auth, how do I get the cookie?
    api_url = "#{markus_address}/api/assignments/#{assignment_id}/groups/#{group_id}/test_script_results"
    options = {:headers => {
                   :Authorization => "MarkUsAuth #{api_key}"},
               :body => {
                   :assignment_id => assignment_id,
                   :group_id => group_id,
                   :file_content => output}}
    HTTParty.post(api_url, options)
  end

end