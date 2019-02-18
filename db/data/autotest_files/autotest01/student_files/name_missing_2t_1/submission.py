#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The json is missing the 'name' field in the first test which should not
  affect the second test
"""

import json

print(json.dumps({'output': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
print(json.dumps({'name': 'missing_name_good_test', 'output': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
