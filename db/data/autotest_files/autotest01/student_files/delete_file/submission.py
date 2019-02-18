#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The student code tries to delete a file
"""
import os
import sys
import glob
import json

autotest_file = sys.argv[1]

os.remove(autotest_file) # removes autotest script file (calls this file)
files = glob.glob('*')

if autotest_file in files:
  print(json.dumps({'name': 'delete_file_test', 'output': 'file not deleted', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
else:
  print(json.dumps({'name': 'delete_file_test', 'output': 'file deleted', 'marks_earned': 0, 'marks_total': 2, 'status': 'fail'}))

