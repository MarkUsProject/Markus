#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The xml is missing the name tag in the second test which should
  not affect the first test
"""

response = '''
<test>
    <name>missing_name_good_test</name>
    <input>NA</input>
    <expected>NA</expected>
    <actual>NA</actual>
    <marks_earned>2</marks_earned>
    <marks_total>2</marks_total>
    <status>pass</status>
</test>
<test>
    <input>NA</input>
    <expected>NA</expected>
    <actual>NA</actual>
    <marks_earned>2</marks_earned>
    <marks_total>2</marks_total>
    <status>pass</status>
</test>
'''

print(response)
