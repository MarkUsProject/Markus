#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The json is malformed in the first test in the first script
  which causes the second test to be ignored
"""
import sys
import os
import json

if os.path.basename(sys.argv[1]) == 'autotest_01.sh':
  print(json.dumps({'name': 'bad_json_good_test', 'output': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'})[2:])
else:
  print(json.dumps({'name': 'bad_json_good_test', 'output': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
