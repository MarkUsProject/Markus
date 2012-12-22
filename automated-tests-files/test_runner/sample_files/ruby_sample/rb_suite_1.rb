#!/usr/bin/env ruby

require_relative "Hello.rb"

def printResults(name, input, exp, act, marks, status)
  return "<test>\n" \
            "<name>#{name}</name>\n" \
            "<input>#{input}</input>\n" \
            "<expected>#{exp}</expected>\n" \
            "<actual>#{act}</actual>\n" \
            "<marks_earned>#{marks}</marks_earned>\n" \
            "<status>#{status}</status>\n" \
            "</test>"    
end

def test_1()
  name = "Normal Hello"
  input = "Bob"
  expected = "Hello Bob"
  actual = greet(input)
  
  marks = if actual == expected then 1 else 0 end
  status = if marks>0 then "pass" else "fail" end
  return printResults(name, input, expected, actual, marks, status)
end

def test_2()
  name = "Empty Hello"
  input = ""
  expected = "Hello "
  actual = greet(input)
  
  marks = if actual == expected then 1 else 0 end
  status = if marks>0 then "pass" else "fail" end
  return printResults(name, input, expected, actual, marks, status)
end

def test_3()
  name = "Wrong Answer"
  input = "Bob"
  expected = "Hello Bob"
  actual = "This-is-rigged"
  
  marks = if actual == expected then 1 else 0 end
  status = if marks>0 then "pass" else "fail" end
          
  return printResults(name, input, expected, actual, marks, status)
  
end

if __FILE__ == $0 then
  
  print "#{test_1()}\n" \
          "#{test_2()}\n" \
          "#{test_3()}"
  
end

