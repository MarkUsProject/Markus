#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The xml is missing a <name> tag in the test in the first script
  which should not affect the test in the second script
"""
import sys
import os

if os.path.basename(sys.argv[1]) == 'autotest_01.sh':
  response = '''
  <test>
      <input>NA</input>
      <expected>NA</expected>
      <actual>NA</actual>
      <marks_earned>2</marks_earned>
      <marks_total>2</marks_total>
      <status>pass</status>
  </test>
  '''
else:
  response = '''
  <test>
      <name>name_missing_good_test</name>
      <input>NA</input>
      <expected>NA</expected>
      <actual>NA</actual>
      <marks_earned>2</marks_earned>
      <marks_total>2</marks_total>
      <status>pass</status>
  </test>
  '''

print(response)
