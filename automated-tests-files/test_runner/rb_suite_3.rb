require "Hello.rb"

def printResults(name, marks, status)
  return "<markus_test>\n" \
            "<markus_name>#{name}</markus_name>\n" \
            "<markus_marks_earned>#{marks}</markus_marks_earned>\n" \
            "<markus_status>#{status}</markus_status>\n" \
            "</markus_test>"    
end

def test()
  marks = 0;
  name = "Question 3"
  
  input = "Bob"
  expected = "Hello Bob"
  actual = greet(input)
  if(expected == actual) then marks = marks+1 end

  input = ""
  expected = "Hello "
  actual = greet(input)
  if(expected == actual) then marks = marks+1 end
  
  input = "Bob"
  expected = "Hello Bob"
  actual = "This-is-rigged"
  if(expected == actual) then marks = marks+1 end
    
  if marks == 3 then status = "pass" else status = "fail" end
    
  return printResults(name, marks, status)
end

if __FILE__ == $0 then
  print "#{test()}\n" 
end

