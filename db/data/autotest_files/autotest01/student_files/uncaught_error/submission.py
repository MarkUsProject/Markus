#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The submission raises an error (writes to stderr) and that
  error is not caught and handled by the autotest script
"""
import sys

sys.stderr.write('uncaught_error_test')
