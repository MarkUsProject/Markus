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
      result['results'].values.each do |test_class|
        if test_class.key?('passes')
          test_class['passes'].each do |test_name, test_desc|
            print_result(test_name, test_desc, '', '', 1, 'pass')
          end
        end
        if test_class.key?('failures')
          test_class['failures'].each do |test_name, test_stack|
            print_result(test_name, test_stack['description'], '', test_stack['message'], 0, 'fail')
          end
        end
        if test_class.key?('errors')
          test_class['errors'].each do |test_name, test_stack|
            print_result(test_name, test_stack['description'], '', test_stack['message'], 0, 'fail')
          end
        end
      end
    end
  rescue Errno::ENOENT
    if File.exist?(timeout_filename)
      print_result('All tests', '', '', 'Timeout', 0, 'fail')
    else
      print_result('All tests', '', '', 'The test framework failed', 0, 'fail')
    end
  end
end

if __FILE__ == $0

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
end