#!/usr/bin/env ruby

require 'open3'
require 'json'

def print_result(name, input, expected, actual, marks, status)
  print <<-EOF
    <test>
      <name>#{name}</name>
      <input>#{input}</input>
      <expected>#{expected}</expected>
      <actual>#{actual}</actual>
      <marks_earned>#{marks}</marks_earned>
      <status>#{status}</status>
    </test>
  EOF
end

def print_results(result_filename, timeout_filename)

  begin
    File.open(result_filename, 'r') do |result_file|
      result = JSON.parse(result_file.read)
      result['results'].each do |test_class|
        test_class['passes'].each do |test_name, test_desc|
          print_result(test_name, test_desc, '', '', 1, 'pass')
        end
        test_class['failures'].each do |test_name, test_stack|
          print_result(test_name, test_stack['description'], '', test_stack['message'], 0, 'fail')
        end
        test_class['errors'].each do |test_name, test_stack|
          print_result(test_name, test_stack['description'], '', test_stack['message'], 0, 'fail')
        end
      end
    end
  rescue Errno::ENOENT
    if File.exist?(timeout_filename)
      print_result('All tests', '', '', 'Timeout', 0, 'fail')
    else
      print_result('All tests', '', '', 'The test framework failed, please contact your instructor', 0, 'fail')
    end
  end
end

if __FILE__ == $0 then

  path_to_virtualenv = '/home/adisandro/Code/uam-virtualenv'
  path_to_uam = '/home/adisandro/Desktop/uam'
  path_to_pam = path_to_uam + '/pam/pam.py'
  result_filename = 'result.json'
  timeout_filename = 'timedout'
  output, status = Open3.capture2e("
    . #{path_to_virtualenv}/bin/activate;
    PYTHONPATH=#{path_to_uam} #{path_to_pam} #{result_filename} test.py
  ")
  unless status.success?
    abort "PAM failed: #{output}"
  end
  print_results(result_filename, timeout_filename)
  # TODO Get test.py filename from markus

  # # TODO Get the assignment name from MarkUs
  # assignment = 'A1'
  # output, status = Open3.capture2e("ln -s #{path_to_uam} uam; cd uam/")
  # unless status.success?
  #   abort "Can't find the automarking framework: #{output}"
  # end
  # # TODO Generate a config.py to target the real assignment..
  # # TODO ..or launch pam.py directly?
  # # TODO Think about the actual
  # output, status = Open3.capture2e("
  #   cd uam/;
  #   . #{path_to_virtualenv}/bin/activate;
  #   python3 test_runner.py
  # ")
  # unless status.success?
  #   # TODO The test runner returns success even in case of errors
  #   abort "Test suite failed: #{output}"
  # end
  # # TODO Cut the aggregator and the templator, they're not needed
  # output, status = Open3.capture2e("
  #   cd uam/;
  #   . #{path_to_virtualenv}/bin/activate;
  #   python3 aggregator.py #{assignment} pam/examples/dirs_and_names.txt pam/examples/students.csv pam/examples/groups.txt result.json aggregated.json
  # ")
  # unless status.success?
  #   abort "Aggregator failed: #{output}"
  # end
  # output, status = Open3.capture2e("
  #   cd uam/;
  #   . #{path_to_virtualenv}/bin/activate;
  #   python3 templator.py aggregated.json txt
  # ")
  # unless status.success?
  #   abort "Templator failed: #{output}"
  # end

end