#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The json is malformed in the second test however the
  first test should be ok
"""
import json

print(json.dumps({'name': 'bad_json_good_test', 'output': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
print(json.dumps({'name': 'bad_json_good_test', 'output': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'})[2:])
