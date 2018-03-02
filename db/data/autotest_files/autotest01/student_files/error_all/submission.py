#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The submission passes one test but then the second test
  prompts an "error_all" status which should invalidate
  the first test result
"""

response = '''
<test>
    <name>error_all_test1</name>
    <input>NA</input>
    <expected>NA</expected>
    <actual>NA</actual>
    <marks_earned>2</marks_earned>
    <marks_total>2</marks_total>
    <status>pass</status>
</test>
<test>
    <name>error_all_test2</name>
    <input>NA</input>
    <expected>NA</expected>
    <actual>NA</actual>
    <marks_earned>0</marks_earned>
    <marks_total>0</marks_total>
    <status>error_all</status>
</test>
<test>
    <name>error_all_test3</name>
    <input>NA</input>
    <expected>NA</expected>
    <actual>NA</actual>
    <marks_earned>2</marks_earned>
    <marks_total>2</marks_total>
    <status>pass</status>
</test>
'''

print(response)
