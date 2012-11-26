require "Hello.rb"

def printResults(name, input, marks, status)
  return "<markus_test>\n" \
            "<markus_name>#{name}</markus_name>\n" \
            "<markus_input>#{input}</markus_input>\n" \
            "<markus_marks_earned>#{marks}</markus_marks_earned>\n" \
            "<markus_status>#{status}</markus_status>\n" \
            "</markus_test>"    
end

def test_1()
  name = "Normal Hello"
  input = "Bob"
  expected = "Hello Bob"
  actual = greet(input)
  
  marks = if actual == expected then 1 else 0 end
  status = if marks>0 then "Pass" else "Fail" end
  return printResults(name, input, marks, status)
end

def test_2()
  name = "Empty Hello"
  input = ""
  expected = "Hello "
  actual = greet(input)
  
  marks = if actual == expected then 1 else 0 end
  status = if marks>0 then "Pass" else "Fail" end
  return printResults(name, input, marks, status)
end

def test_3()
  name = "Wrong Answer"
  input = "Bob"
  expected = "Hello Bob"
  actual = "This-is-rigged"
  
  marks = if actual == expected then 1 else 0 end
  status = if marks>0 then "Pass" else "Fail" end
  return printResults(name, input, marks, status)
end

if __FILE__ == $0 then
  print "#{test_1()}\n" \
          "#{test_2()}\n" \
          "#{test_3()}\n" \
end

