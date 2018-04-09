#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The submission raises an error (writes to stderr) and that
  error is not caught and handled by the autotest script
"""
import sys

sys.stderr.write('uncaught_error_test')

response = '''
<test>
    <name>pass_test</name>
    <input>NA</input>
    <expected>NA</expected>
    <actual>NA</actual>
    <marks_earned>2</marks_earned>
    <marks_total>2</marks_total>
    <status>pass</status>
</test>
'''

print(response)
