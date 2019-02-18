#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The student code tries to modify a file
"""
import sys
import json

autotest_file = sys.argv[1]
extra_text = '# append test'

with open(autotest_file, 'a') as f:
  f.write(extra_text)

with open(autotest_file) as f:
  contents = f.read()

if extra_text in contents:
  print(json.dumps({'name': 'modify_file_test', 'output': 'file was modified', 'marks_earned': 0, 'marks_total': 2, 'status': 'fail'}))
else:
  print(json.dumps({'name': 'modify_file_test', 'output': 'file was not modified', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
