#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The student code tries to delete a file
"""
import os
import sys
import glob

autotest_file = sys.argv[1]

os.remove(autotest_file) # removes autotest script file (calls this file)
files = glob.glob('*')

if autotest_file in files:
  result = ('file not deleted', 2, 2, 'pass')
else:
  result = ('file deleted', 0, 2, 'fail')

response = '''
<test>
    <name>delete_file_test</name>
    <input>NA</input>
    <expected>NA</expected>
    <actual>{}</actual>
    <marks_earned>{}</marks_earned>
    <marks_total>{}</marks_total>
    <status>{}</status>
</test>
'''.format(*result)

print(response)
