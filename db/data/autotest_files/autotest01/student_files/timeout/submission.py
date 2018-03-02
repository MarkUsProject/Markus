#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The submission runs longer than the timeout limit (10 seconds)
"""
import time

time.sleep(15)

# should be killed before reaching the following:

response = '''
<test>
    <name>timeout_test</name>
    <input>NA</input>
    <expected>NA</expected>
    <actual>script should have timed out but did not</actual>
    <marks_earned>2</marks_earned>
    <marks_total>2</marks_total>
    <status>pass</status>
</test>
'''

print(response)
