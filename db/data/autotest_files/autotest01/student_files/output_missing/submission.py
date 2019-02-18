#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The json is missing non-necessary field 'output'
"""
import json

print(json.dumps({'name': 'output_missing', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
