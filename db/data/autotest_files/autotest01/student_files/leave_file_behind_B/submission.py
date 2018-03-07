#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  This submission checks if a file left over from running
  leave_file_behind_A/submission.py is still there
"""
import os

filename = 'abandoned_file.txt'

if os.path.isfile(filename):
  output = ('file still there', 0, 0, 'error')
else:
  output = ('file removed successfully', 2, 2, 'pass')

response = '''
<test>
    <name>leave_file_behind_test_A</name>
    <input>NA</input>
    <expected>NA</expected>
    <actual>{}</actual>
    <marks_earned>{}</marks_earned>
    <marks_total>{}</marks_total>
    <status>{}</status>
</test>
'''.format(*output)

print(response)


