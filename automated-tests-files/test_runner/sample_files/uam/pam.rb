#!/usr/bin/env ruby

if __FILE__ == $0 then

  path_to_uam = '../../../../uam'
  assignment = 'asst'
  output, status = Open3.capture2e("ln -s #{path_to_uam} uam")
  unless status.success?
    print "Can't find automarking framework: #{output}"
    return
  end
  # TODO It should be enough to use a standard config.py
  output, status = Open3.capture2e('cd uam/; python3 test_runner.py')
  unless status.success?
    print "Test suite failed: #{output}"
    return
  end
  # TODO Only one submission at a time runs: modify test framework or run aggregator/templator separately?
  # TODO Need to generate all the necessary files too
  output, status = Open3.capture2e("
    cd uam/;
    python3 aggregator.py #{assignment} examples/pam/dirs_and_names.txt examples/pam/students.csv examples/pam/groups.txt result.json #{assignment}_aggregated.json
  ")
  unless status.success?
    print "Aggregator failed: #{output}"
    return
  end
  output, status = Open3.capture2e("
    cd uam/;
    python3 templator.py #{assignment}_aggregated.json txt
  ")
  unless status.success?
    print "Templator failed: #{output}"
    return
  end

end