#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The json doesn't contain a 'marks_total' field
"""

import json

print(json.dumps({'name': 'no_marks_total_test', 'output': 'NA', 'marks_earned': 0, 'status': 'error'}))
