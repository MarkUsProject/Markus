#!/usr/bin/env ruby

require 'timeout'

$LAST_ARG = 0
$HALT_ON_FAIL = false
$HAS_FAILED = false
$TIME_LIMIT = 600     #the maximum amount of time a given test suite can run for, in seconds

#
# given the filename, and suite output, it formats and returns the results
# also checks to see if a fail/error was encountered
#
def parseOutput(fileName, output, status)
  # used to set the HAS_FAILED tag
  hasFail = ! output.downcase["<status>fail</status>"].nil?
  hasError = ! output.downcase["<status>error</status>"].nil?
  
  # used to determine if a default mark should be added
  hasMarks = ! output.downcase[/<marks_earned>(\d+)<\/marks_earned>/].nil?
  marksClause = "";
  
  # if there are no marks listed, then add a mark of 0 or 1
  if !hasMarks then
      marks = if (hasFail || hasError) then 0 else 1 end;
      marksClause = "<marks_earned>#{marks}</marks_earned>\n"
  end
  
  if hasFail || hasError then
    $HAS_FAILED = true
  else
    $HAS_FAILED = false
  end
  
  xml = "<test_script>\n" \
            "<script_name>#{File.basename(fileName)}</script_name>\n" \
            "#{output}\n" \
            "#{marksClause}" \
        "</test_script>\n"
  return xml  
end

#
# fork a child process (and open a pipe to it) and run the test
# the parent waits for the child to terminate or timeout before continuing
# 
def runTest(fileName)
  begin
    # basic timeout check
    # if the test_suite runs for over N seconds, it times out
    Timeout.timeout($TIME_LIMIT) do
      @pipe = IO.popen("./#{fileName}")
      Process.wait @pipe.pid
    end
  rescue Timeout::Error
    # on a timeout, kill the process and make some basic error message in the XML
    Process.kill 9, @pipe.pid
    Process.wait @pipe.pid
    
    $HAS_FAILED = true

    output = "<test>\n" \
             "<actual>MarkUs - Timeout</actual>\n" \
             "<status>Error</status>\n" \
             "</test>"
    # then just parse and return that error message
    return parseOutput(fileName, output, $?)
  end
    
  
  # otherwise, iterate over the pipe's data, one line at a time
  # and append that to the output
  output = ""
  str = @pipe.gets
  while(! str.nil?) do
    output = output + str
    str = @pipe.gets
  end
  
  # check to see if there was a failure
  if $? != 0 then
    $HAS_FAILED = true
  end
 
  # then parse and return the output
  return parseOutput(fileName, output, $?)
      
end

#
# gets the next (testName, flag) pair, based on whether or not
# it uses stdin or if the input is from the command line.
# the pair is returnes as a string "name flag"
#
def getNext(useSTD)
  if(useSTD)
    # if s is an empty line (but not EOF), skip it
    s = STDIN.gets
    while s == "\n"
      s = STDIN.gets
    end
    return s
  else
    # return the next 2 arguments, which will be (fileName, tag)
    args = "#{ARGV[$LAST_ARG]} #{ARGV[$LAST_ARG+1]}"
    $LAST_ARG = $LAST_ARG + 2
    return args
  end
end

#
# returns a boolean value for a string
# returns true if s is "true"
# returns false otherwise
# 
def getBool(s)
  if s == "true" then return true
  else return false
  end
end

#
# checks to see if all the submitted files exist
#
def checkFiles(files)
  files.each {
    |file|
    if  !File.exist?(file) then
      return false
    end
  }
  return true;
end

#
# sets all the test scripts to +x
# this is done because they are all run using ./filename
#
def modFiles(files)
  files.each{
    |file|
    f = File.new(file)
    f.chmod(0766)
  }
end

def main()
  #the output is nested in a <test_stuite> tag
  output = "<testrun>\n"  
  
  # if there are no other cmd line args, then stdin is being used
  # if there are no args and stdin isnt being used, then it will crash
  # if the argv tag is used, then change the default time limit
  if ARGV[0] == nil then 
    useSTD = true
  elsif ARGV[0] == '-t' and ARGV[1] == nil then
    # error
  elsif ARGV[0] == '-t' and ARGV[2] == nil then
    useSTD = true
    $TIME_LIMIT = Integer(ARGV[1])
  elsif ARGV[0] == '-t' and ARGV[2] != nil then
    useSTD = false
    $TIME_LIMIT = Integer(ARGV[1])
    $LAST_ARG = 2
  else 
    useSTD = false
  end
  
  # set the first test
  nextFile = getNext(useSTD)
  
  files = []
  flags = []
  #using stdin can return nil, and using cmd line can return " ", but not nil
  while(nextFile != nil && nextFile != " ") do
    filedata = nextFile.split(' ')

    #extract the test script data
    files.push(filedata[0])
    flags.push(getBool(filedata[1]))
    
    #get the next script
    nextFile = getNext(useSTD)
  end

  # if any of the files don't exist, output
  if !checkFiles(files) then
    print "<testrun></testrun>"
    exit(-1)
  end
  
  # set the scripts to +x, so they can be run
  modFiles(files)

  curInd = 0; # current file's index 
  # runs test on all the files
  while curInd < files.length && (!$HAS_FAILED || !$HALT_ON_FAIL)
    # add its output to the current output    
    filename = files[curInd]
    $HALT_ON_FAIL = flags[curInd]
    
    # append the current file's test results
    output = output + runTest(filename)
    
    curInd = curInd + 1;
  end
  
  #close the top level tag
  output = output + "</testrun>"
  # print the entire xml block
  print output
end

# just calls the main method
if __FILE__ == $0 then
  main()
end