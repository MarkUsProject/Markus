#!/usr/bin/env python3

import sys
from markus_pam_wrapper import MarkusPAMWrapper
# from markusapi import Markus


if __name__ == '__main__':
    # Modify uppercase variables with your settings
    # The path to the UAM root folder
    PATH_TO_UAM = '/path/to/uam'
    # A list of test files uploaded as support files to be executed against the student submission
    MARKUS_TEST_FILES = ['test.py']
    # The max time to run a single test on the student submission.
    TEST_TIMEOUT = 5
    # The max time to run all tests on the student submission.
    GLOBAL_TIMEOUT = 20
    # The path to a Python virtualenv that has the test dependencies
    # (if None, dependencies must be installed system-wide)
    PATH_TO_VIRTUALENV = None
    wrapper = MarkusPAMWrapper(path_to_uam=PATH_TO_UAM, test_files=MARKUS_TEST_FILES, test_timeout=TEST_TIMEOUT,
                               global_timeout=GLOBAL_TIMEOUT, path_to_virtualenv=PATH_TO_VIRTUALENV)
    wrapper.run()
    # use with markusapi.py if needed (uncomment import markusapi)
    ROOT_URL = sys.argv[1]
    API_KEY = sys.argv[2]
    ASSIGNMENT_ID = sys.argv[3]
    GROUP_ID = sys.argv[4]
    # FILE_NAME = 'result.json'
    # api = Markus(API_KEY, ROOT_URL)
    # with open(FILE_NAME) as open_file:
    #     api.upload_feedback_file(ASSIGNMENT_ID, GROUP_ID, FILE_NAME, open_file.read())
