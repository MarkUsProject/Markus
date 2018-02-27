#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The xml is malformed in the second script
  however the first script should still be ok
"""
import sys
import os

if os.path.basename(sys.argv[1]) == 'autotest_02.sh':
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
