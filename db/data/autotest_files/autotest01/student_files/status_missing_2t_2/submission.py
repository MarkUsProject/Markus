#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The json is missing the 'status' field in the first test which should not
  affect the second test
"""
import json

print(json.dumps({'name': 'missing_status_bad_test', 'output': 'NA', 'marks_earned': 2, 'marks_total': 2}))
print(json.dumps({'name': 'missing_status_good_test', 'output': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))

