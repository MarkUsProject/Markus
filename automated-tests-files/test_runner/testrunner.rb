$LAST_ARG = 0
$HALT_ON_FAIL = false
$HAS_FAILED = false

#
# given the filename, output, and exit status, this will format them as xml
# and return the resulting xml
#
def parseOutput(fileName, marks, input, expected, output, status)
  expected = expected.strip()
  input = input.strip()
  marks = marks.strip()
  
  if expected == output then earned = marks 
    else earned = 0 
  end
  if status != 0 then exitType = "Error" 
    elsif expected == output then exitType = "Pass" 
    else exitType = "Fail" 
  end
  
  if exitType == "Fail" || exitType == "Error" then
    $HAS_FAILED = true
  else
    $HAS_FAILED = false
  end
     
  xml = "<test>\n" \
        "<id>#{fileName}</id>\n" \
        "<input>#{input}</input>\n" \
        "<expected>#{expected}</expected>\n" \
        "<output>#{output}</output>\n" \
        "<marks>#{earned}</marks>\n" \
        "<status>#{exitType}</status>\n" \
        "</test>\n"
  return xml  
end

#
# fork a child process (and open a pipe to it) and run the test
# the parent waits for the child to terminate before continuing
# 
# depending on the format of the script, the child will try to run it in a
# different way.
# 
# if the child returns the output, then the parent reads it
# 
# the parent then calls parseOutput on the file name, output, and exit status
# and returns the resulting xml
#
# to add support for a language, just add this to internal if block:
# elsif File.extname(fileName) == ".<lang_extension>"
#        exec "<program_name> #{fileName} <optional_args>"
# 
def runTest(fileName)
open("|-", "r+") do |child|
    if child
      # wait for the child process to finish, then get the exit status
      
      Process.wait
      status = $?
      
      # if there's an error, then the test failed
      if(status != 0) then
        $HAS_FAIL = true
      end
      
      # get the data from the test script
      # .gets("") reads up to the first \n\n
      # .gets(nil) reads everything
      marks = child.gets("")
      input = child.gets("")
      expected = child.gets("")
      output = child.gets(nil)
      # if the output isnt null, strip leading/trailing whitespace
      if !output.nil?
        output = output.strip
      end
      
      # return the xml
      return parseOutput(fileName, marks, input, expected, output, status)
    else
      # commented formats are not fully supported
      
      # run the script
      if File.extname(fileName) == ".rb"
        exec "ruby #{fileName}"
      #elsif File.extname(fileName) == ".rkt"
      #  exec "racket #{fileName}"
      #elsif File.extname(fileName) == ".class"
      #  exec "java #{fileName}"
      #elsif File.extname(fileName) == ""
      #  exec "./#{fileName}"
      end
    end
  end
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

def main()
  #the output is nested in a <test_stuite> tag
  output = "<test_suite>\n"  
  
  # if there are no other cmd line args, then stdin is being used
  # if there are no args and stdin isnt being used, then it will crash
  if ARGV[0] == nil then 
    useSTD = true
  else 
    useSTD = false
  end
  
  # set the first test
  nextFile = getNext(useSTD)
  
  #using stdin can return nil, and using cmd line can return " ", but not nil
  while(nextFile != nil && nextFile != " " \
    && (!$HAS_FAILED || !$HALT_ON_FAIL)) do
    filedata = nextFile.split(' ')
    
    #extract the test script data
    filename = filedata[0]
    $HALT_ON_FAIL = getBool(filedata[1]) 
        
    # add its output to the current output
    output = output + runTest(filename)
    
    #get the next script
    nextFile = getNext(useSTD)
  end
  #close the top level tag
  output = output + "</test_suite>"
  # print the entire xml block
  print output
end

# just calls the main method
if __FILE__ == $0 then
  main()
end