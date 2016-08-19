#!/usr/bin/env python3

import hello
import markusapi

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
    # Note: currently this data is hard-coded, but should be passed in
    API_KEY = 'ZTEwY2VlNmM4Nzk3NjM2N2QxYjk0YWM0MjU0M2NlMDQ='
    ROOT_URL = 'http://localhost:3000/'
    api = markusapi.Markus(API_KEY, ROOT_URL)
    api.upload_test_script_result(6, '77',
        '<testrun><test_script><script_name>py_suite_1.py</script_name>' +
        test_1() + test_2() + test_3() +
        '</test_script></testrun>')
