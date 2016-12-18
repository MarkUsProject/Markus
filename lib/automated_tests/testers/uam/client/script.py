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
    # use markus apis if needed (uncomment import markusapi)
    root_url = sys.argv[1]
    api_key = sys.argv[2]
    assignment_id = sys.argv[3]
    group_id = sys.argv[4]
    # file_name = 'result.json'
    # api = Markus(api_key, root_url)
    # with open(file_name) as open_file:
    #     api.upload_feedback_file(assignment_id, group_id, file_name, open_file.read())
