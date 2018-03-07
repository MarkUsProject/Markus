#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The submission creates a file which should be removed
  by the autotester. leave_file_behind_B/submission.py
  then checks if the file is still around
"""
import os

filename = 'abandoned_file.txt'

open(filename, 'w').close()

if os.path.isfile(filename):
  output = ('file successfully created', 2, 2, 'pass')
else:
  output = ('failed to create file', 0, 0, 'error')

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


