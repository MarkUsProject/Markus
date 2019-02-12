#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The submission creates a file which should be removed
  by the autotester. leave_file_behind_B/submission.py
  then checks if the file is still around
"""
import os
import json

filename = 'abandoned_file.txt'

open(filename, 'w').close()

if os.path.isfile(filename):
  print(json.dumps({'name': 'leave_file_behind_test_A', 'output': 'file successfully created', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
else:
  print(json.dumps({'name': 'leave_file_behind_test_A', 'output': 'failed to create file', 'marks_earned': 0, 'marks_total': 2, 'status': 'fail'}))

