#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The submission spawns a child process which should be killed
  by the autotester once the script has finished running

  This script is the first part of this test, it only spawns a child
  process in the background and quits. The seconds script
  (in spawn_proc_B) checks if the process spawned by this
  script is still running
"""

import subprocess
import time

# Note: sleeps once after the while loop to make sure the *_B.py file has time to
#       make sure the permissions for angler.txt are set corectly

cmd = "while [ ! -f ./angler.txt ]; do sleep 1; done; sleep 1; echo 'a fish!' > angler.txt"
proc = subprocess.Popen(cmd, shell=True)

time.sleep(1) # gives the process a second so .poll() can catch an early failure

if proc.poll() is None:
  output = ('child process successfully spawned', 2, 2, 'pass')
else:
  output = ('failed to spawn child process', 0, 0, 'error')

response = '''
<test>
    <name>spawned_proc_test_A</name>
    <input>NA</input>
    <expected>NA</expected>
    <actual>{}</actual>
    <marks_earned>{}</marks_earned>
    <marks_total>{}</marks_total>
    <status>{}</status>
</test>
'''.format(*output)

print(response)


