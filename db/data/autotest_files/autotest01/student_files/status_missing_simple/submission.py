#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The json is missing the 'status' field
"""
import json

print(json.dumps({'name': 'status_missing_simple', 'output': 'NA', 'marks_earned': 2, 'marks_total': 2}))
