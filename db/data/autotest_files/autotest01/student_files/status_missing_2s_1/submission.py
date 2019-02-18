#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The json is missing a 'status' field in the first test in the first script
  should not affect the test in the second script
"""
import sys
import os
import json

if os.path.basename(sys.argv[1]) == 'autotest_01.sh':
  print(json.dumps({'name': 'status_missing_bad_test', 'output': 'NA', 'marks_earned': 2, 'marks_total': 2}))
else:
  print(json.dumps({'name': 'status_missing_good_test', 'output': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
