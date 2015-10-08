#!/usr/bin/env python

import hello

def printResults(name, input, exp, act, marks, status):
  return "<test>\n \
    <name>" + name + "</name>\n \
    <input>" + input + "</input>\n \
    <expected>" + exp + "</expected>\n \
    <actual>" + act + "</actual>\n \
    <marks_earned>" + str(marks) + "</marks_earned>\n \
    <status>" + status + "</status>\n \
    </test>"    


def test_1():
  name = "Normal Hello"
  input = "Bob"
  expected = "Hello Bob"
  actual = hello.greet(input)
  
  if actual == expected:
      marks = 1
      status = "pass"
  else:
      marks = 0
      status = "fail"

  return printResults(name, input, expected, actual, marks, status)


def test_2():
  name = "Empty Hello"
  input = ""
  expected = "Hello "
  actual = hello.greet(input)
  
  if actual == expected:
      marks = 2
      status = "pass"
  else:
      marks = 0
      status = "fail"

  return printResults(name, input, expected, actual, marks, status)


def test_3():
  name = "Wrong Answer"
  input = "Bob"
  expected = "Hello Bob"
  actual = "This-is-rigged"
  
  if actual == expected:
      marks = 2
      status = "pass"
  else:
      marks = 0
      status = "fail"
          

  return printResults(name, input, expected, actual, marks, status)
  
if __name__ == "__main__":
    print test_1()
    print test_2()
    print test_3()