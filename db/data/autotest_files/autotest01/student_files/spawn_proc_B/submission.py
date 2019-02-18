#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The submission spawns a child process which should be killed
  by the autotester once the script has finished running

  This script is the second part of this test, it checks if the process
  spawned by the script in spawn_proc_A is still running.
  This script must be run by the autotester directly after and in the
  same dir as spawn_proc_A/submission.py
"""

import time
import os
import json

open('angler.txt', 'w').close()
os.chmod('angler.txt', 0o777)

time.sleep(3) # just in case it takes some time to write to the file

with open('angler.txt') as f:
	contents = f.read()

if 'a fish!' in contents:
  print(json.dumps({'name': 'spawned_proc_test_B', 'output': 'child process was not killed', 'marks_earned': 0, 'marks_total': 0, 'status': 'error'}))
else:
  print(json.dumps({'name': 'spawned_proc_test_B', 'output': 'child process successfully killed', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))

os.remove('angler.txt')
