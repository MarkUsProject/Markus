#!/usr/bin/env ruby

require_relative "Hello.rb"

def printResults(name, marks, status)
    #return "<test>\n" \
    #        "<name>#{name}</name>\n" \
    #        "<marks_earned>#{marks}</marks_earned>\n" \
    #        "<status>#{status}</status>\n" \
    #        "</test>"  
            
  return "<test>\n" \
            "<name>#{name}</name>\n" \
            "<status>#{status}</status>\n" \
            "</test>"    
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
  print "#{test()}" 
end

