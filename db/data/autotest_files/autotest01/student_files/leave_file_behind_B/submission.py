#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  This submission checks if a file left over from running
  leave_file_behind_A/submission.py is still there
"""
import os
import json

filename = 'abandoned_file.txt'

if os.path.isfile(filename):
  print(json.dumps({'name': 'leave_file_behind_test_B', 'output': 'file still there', 'marks_earned': 0, 'marks_total': 2, 'status': 'fail'}))
else:
  print(json.dumps({'name': 'leave_file_behind_test_B', 'output': 'file removed successfully', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
