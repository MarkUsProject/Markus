#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The xml is malformed in the second script
  however the first script should still be ok
"""
import sys
import os
import json

if os.path.basename(sys.argv[1]) == 'autotest_02.sh':
  print(json.dumps({'name': 'bad_xml_good_test', 'input': 'NA', 'expected': 'NA', 'actual': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'})[2:])

else:
  print(json.dumps({'name': 'bad_xml_good_test', 'input': 'NA', 'expected': 'NA', 'actual': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
