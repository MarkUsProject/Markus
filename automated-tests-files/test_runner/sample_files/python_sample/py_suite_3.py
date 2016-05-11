#!/usr/bin/env python

import hello

def printResults(name, status):
  return "<test>\n \
    <name>" + name + "</name>\n \
    <status>" + status + "</status>\n \
    </test>"    

def test():
  marks = 0;
  name = "Question 3"
  
  input = "Bob"
  expected = "Hello Bob"
  actual = hello.greet(input)
  if expected == actual:
    marks = marks+1

  input = ""
  expected = "Hello "
  actual = hello.greet(input)
  if expected == actual:
    marks = marks+1
  
  input = "Bob"
  expected = "Hello Bob"
  actual = "This-is-rigged"
  if expected == actual:
    marks = marks+1
    
  if marks == 3:
       status = "pass"
  else: 
      status = "fail"
    
  return printResults(name, status)

if __name__ == "__main__":
    print test()

