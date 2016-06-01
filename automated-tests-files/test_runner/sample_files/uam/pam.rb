#!/usr/bin/env ruby

require 'open3'

if __FILE__ == $0 then

  path_to_virtualenv = '/home/adisandro/Code/uam-virtualenv'
  path_to_uam = '/home/adisandro/Desktop/uam'
  assignment = 'asst'
  output, status = Open3.capture2e("ln -s #{path_to_uam} uam; cd uam/")
  unless status.success?
    abort "Can't find the automarking framework: #{output}"
  end
  # TODO It should be enough to use a standard config.py
  output, status = Open3.capture2e("
    cd uam/;
    source #{path_to_virtualenv}/bin/activate;
    python3 test_runner.py
  ")
  print output
  unless status.success?
    # TODO The test runner returns success even in case of errors
    abort "Test suite failed: #{output}"
  end
  # TODO Only one submission at a time runs: modify test framework or run aggregator/templator separately?
  # TODO Need to generate all the necessary files too
  output, status = Open3.capture2e("
    cd uam/;
    source #{path_to_virtualenv}/bin/activate;
    python3 aggregator.py #{assignment} examples/pam/dirs_and_names.txt examples/pam/students.csv examples/pam/groups.txt result.json aggregated.json
  ")
  print output
  unless status.success?
    abort "Aggregator failed: #{output}"
  end
  output, status = Open3.capture2e("
    cd uam/;
    source #{path_to_virtualenv}/bin/activate;
    python3 templator.py aggregated.json txt
  ")
  print output
  unless status.success?
    abort "Templator failed: #{output}"
  end

  print "<test>\n" \
          "<name>uam</name>\n" \
          "<input>test</input>\n" \
          "<expected>ok</expected>\n" \
          "<actual>ok</actual>\n" \
          "<marks_earned>1</marks_earned>\n" \
          "<status>pass</status>\n" \
        "</test>"

end