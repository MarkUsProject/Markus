#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The json is missing the 'name' field in the test in the first script
  which should not affect the test in the second script
"""
import sys
import os
import json

if os.path.basename(sys.argv[1]) == 'autotest_01.sh':
  print(json.dumps({'output': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
else:
  print(json.dumps({'name': 'name_missing_good_test', 'output': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
