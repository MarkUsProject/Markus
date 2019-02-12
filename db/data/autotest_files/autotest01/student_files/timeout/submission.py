#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The submission runs longer than the timeout limit (10 seconds)
"""
import time
import json

time.sleep(15)

# should be killed before reaching the following:

print(json.dumps({'name': 'timeout_test', 'output': 'script should have timed out but did not', 'marks_earned': 2, 'marks_total': 2, 'status': 'pass'}))
