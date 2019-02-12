#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The submission spawns a child process which should be killed
  by the autotester after the timeout limit (10 seconds) is reached

  This script is the first part of this test, it only spawns a child
  process in the background and quits. The seconds script
  (in spawn_proc_with_timeout_B) checks if the process spawned by this
  script is still running
"""
import subprocess
import time
import json

# Note: sleeps once after the while loop to make sure the *_B.py file has time to
#       make sure the permissions for angler.txt are set corectly

cmd = "while [ ! -f ./angler.txt ]; do sleep 1; done; sleep 1; echo 'a fish!' > angler.txt"
proc = subprocess.Popen(cmd, shell=True)

time.sleep(1) # gives the process a second so .poll() can catch an early failure

if proc.poll() is None:
  print(json.dumps({'name': 'spawned_proc_with_timeout_test_A', 'output': 'child process successfully spawned', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
else:
  print(json.dumps({'name': 'spawned_proc_with_timeout_test_A', 'output': 'failed to spawn child process', 'marks_earned': 0, 'marks_total': 0, 'status': 'error'}))

time.sleep(15)
