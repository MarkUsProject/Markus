#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The student tries to write a file in the parent directory
"""
import os
import json

new_file = os.path.join('..', 'tmp.txt')

# make sure we don't overwrite an existing file by accident
i = 0
while os.path.isfile(new_file):
  new_file = os.path.join('..', 'tmp{}.txt'.format(i))
  i += 1

open(new_file, 'w').close()

if os.path.isfile(new_file):
  print(json.dumps({'name': 'write_to_parent_dir_test', 'output': 'new file written to parent dir', 'marks_earned': 0, 'marks_total': 2, 'status': 'fail'}))
else:
  print(json.dumps({'name': 'write_to_parent_dir_test', 'output': 'new file not written to parent dir', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))

os.remove(new_file)
