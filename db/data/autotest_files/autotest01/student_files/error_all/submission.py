#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The submission passes one test but then the second test
  prompts an "error_all" status which should invalidate
  the first test result
"""
import json
print(json.dumps({'name': 'error_all_test1', 'output': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
print(json.dumps({'name': 'error_all_test2', 'output': 'NA', 'marks_earned': 0, 'marks_total': 0, 'status': 'error_all'}))
print(json.dumps({'name': 'error_all_test3', 'output': 'NA', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
