#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The student tries to write a file in the parent directory
"""
import os

new_file = os.path.join('..', 'tmp.txt')

# make sure we don't overwrite an existing file by accident
i = 0
while os.path.isfile(new_file):
  new_file = os.path.join('..', 'tmp{}.txt'.format(i))
  i += 1

open(new_file, 'w').close()

if os.path.isfile(new_file):
  result = ('new file written to parent dir', 0, 2, 'fail')
else:
  result = ('new file not written to parent dir', 2, 2, 'pass')

response = '''
<test>
    <name>write_to_parent_dir_test</name>
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
