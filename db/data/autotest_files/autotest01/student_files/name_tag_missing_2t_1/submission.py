#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The xml is missing the name tag in the first test which should not
  affect the second test
"""

import json

print(json.dumps({'input': 'NA', 'expected': 'NA', 'actual': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
print(json.dumps({'name': 'missing_name_good_test', 'input': 'NA', 'expected': 'NA', 'actual': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
