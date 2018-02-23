#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The student tries to write a file in the current directory
"""
import os

new_file = 'tmp.txt'

# make sure we don't overwrite an existing file by accident
i = 0
while os.path.isfile(new_file):
  new_file = 'tmp{}.txt'.format(i)
  i += 1

open(new_file, 'w').close()

if os.path.isfile(new_file):
  result = ('new file written to current dir', 2, 2, 'pass')
else:
  result = ('new file not written to current dir', 0, 2, 'fail')

response = '''
<test>
    <name>write_to_current_dir_test</name>
    <input>NA</input>
    <expected>NA</expected>
    <actual>{}</actual>
    <marks_earned>{}</marks_earned>
    <marks_total>{}</marks_total>
    <status>{}</status>
</test>
'''.format(*result)

print(response)

os.remove(new_file)
