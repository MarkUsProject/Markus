#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The submission spawns a child process which should be killed
  by the autotester after the timeout limit (10 seconds) is reached

  This script is the second part of this test, it checks if the process
  spawned by the script in spawn_proc_with_timeout_A is still running.
  This script must be run by the autotester directly after and in the
  same dir as spawn_proc_with_timeout_A/submission.py
"""

import time
import os

open('angler.txt', 'w').close()
os.chmod('angler.txt', 0o777)

time.sleep(3) # just in case it takes some time to write to the file

with open('angler.txt') as f:
	contents = f.read()

if 'a fish!' in contents:
  output = ('child process was not killed', 0, 0, 'error')
else:
  output = ('child process successfully killed', 2, 2, 'pass')

response = '''
<test>
    <name>spawned_proc_with_timeout_test_B</name>
    <input>NA</input>
    <expected>NA</expected>
    <actual>{}</actual>
    <marks_earned>{}</marks_earned>
    <marks_total>{}</marks_total>
    <status>{}</status>
</test>
'''.format(*output)

print(response)

os.remove('angler.txt')
