#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The xml is missing a <status> tag in the second script
  which causes the second test to be ignored
"""
import sys
import os

if os.path.basename(sys.argv[1]) == 'autotest_02.sh':
  response = '''
  <test>
      <name>status_missing_bad_test</name>
      <input>NA</input>
      <expected>NA</expected>
      <actual>NA</actual>
      <marks_earned>2</marks_earned>
      <marks_total>2</marks_total>
  </test>
  '''
else:
  response = '''
  <test>
      <name>status_missing_good_test</name>
      <input>NA</input>
      <expected>NA</expected>
      <actual>NA</actual>
      <marks_earned>2</marks_earned>
      <marks_total>2</marks_total>
      <status>pass</status>
  </test>
  '''

print(response)
