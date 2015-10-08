#!/usr/bin/env ruby

def greet(x) 
  print "Hello #{x}"
end

if __FILE__ == $0 then
  s = STDIN.gets
  while !s.nil?
    greet(s)
    s = STDIN.gets
  end
end