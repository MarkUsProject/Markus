#!/usr/bin/env ruby

require 'open3'

if __FILE__ == $0 then

  path_to_virtualenv = '/home/adisandro/Code/uam-virtualenv'
  path_to_uam = '/home/adisandro/Desktop/uam'
  path_to_pam = path_to_uam + '/pam/pam.py'
  output, status = Open3.capture2e("
    . #{path_to_virtualenv}/bin/activate;
    PYTHONPATH=#{path_to_uam} #{path_to_pam} result.json test.py
  ")
  unless status.success?
    abort "PAM failed: #{output}"
  end


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

  # TODO Read result.json and produce this
  print "<test>\n" \
          "<name>uam</name>\n" \
          "<input>test</input>\n" \
          "<expected>ok</expected>\n" \
          "<actual>ok</actual>\n" \
          "<marks_earned>1</marks_earned>\n" \
          "<status>pass</status>\n" \
        "</test>\n" \
        "<test>\n" \
          "<name>uam</name>\n" \
          "<input>test</input>\n" \
          "<expected>ok</expected>\n" \
          "<actual>no</actual>\n" \
          "<marks_earned>0</marks_earned>\n" \
          "<status>fail</status>\n" \
        "</test>"

end