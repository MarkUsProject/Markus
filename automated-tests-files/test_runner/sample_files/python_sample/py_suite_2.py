#!/usr/bin/env python

import hello

def printResults(name, input, status):
  return "<test>\n \
            <name>" + name + "</name>\n \
            <input>" + input + "</input>\n \
            <status>" + status + "</status>\n \
            </test>"    

def test_1():
  name = "Normal Hello"
  input = "Bob"
  expected = "Hello Bob"
  actual = hello.greet(input)
  
  if actual == expected:
      status = "pass"
  else:
      status = "false"

  return printResults(name, input, status)

def test_2():
  name = "Empty Hello"
  input = ""
  expected = "Hello "
  actual = hello.greet(input)
  
  if actual == expected:
      status = "pass"
  else:
      status = "false"

  return printResults(name, input, status)

def test_3():
  name = "Wrong Answer"
  input = "Bob"
  expected = "Hello Bob"
  actual = "This-is-rigged"
  
  if actual == expected:
      status = "pass"
  else:
      status = "false"
  return printResults(name, input, status)

if __name__ == "__main__":
    print test_1()
    print test_2()
    print test_3()

