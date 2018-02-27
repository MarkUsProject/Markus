#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The xml is malformed in the first test in the first script
  which causes the second test to be ignored
"""
import sys
import os

if os.path.basename(sys.argv[1]) == 'autotest_01.sh':
  response = '''
  <test>
      <name>bad_xml_bad_test</name
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
      <name>bad_xml_good_test</name>
      <input>NA</input>
      <expected>NA</expected>
      <actual>NA</actual>
      <marks_earned>2</marks_earned>
      <marks_total>2</marks_total>
      <status>pass</status>
  </test>
  '''

print(response)
