#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The student code tries to modify a file
"""
import sys

autotest_file = sys.argv[1]
extra_text = '# append test'

with open(autotest_file, 'a') as f:
  f.write(extra_text)

with open(autotest_file) as f:
  contents = f.read()

if extra_text in contents:
  result = ('file was modified', 0, 2, 'fail')
else:
  result = ('file was not modified', 2, 2, 'pass')

response = '''
<test>
    <name>modify_file_test</name>
    <input>NA</input>
    <expected>NA</expected>
    <actual>{}</actual>
    <marks_earned>{}</marks_earned>
    <marks_total>{}</marks_total>
    <status>{}</status>
</test>
'''.format(*result)

print(response)
