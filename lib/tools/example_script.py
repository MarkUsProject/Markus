"""
This file contains an example script that allows a user to upload raw test
results files, and then extract and submit marks from them.

Either section can be commented out safely without affecting the other,
in case only one of the two tasks is desired.

There will be some variance in set up between users, so it is possible
that the user will need to make some modifications to suit their own needs.
Still, we hope this template is useful.

Usage:
-Place this file in the folder containing all your group repos.
-Make sure the api_python_module.py is somewhere it can be imported from.
-Fill in the macros with the correct information, following the
 format of the given examples.
-Run the script with python3.

Macros:
API_KEY       -- an Admin API key. It can be found on the admin dashboard page.
ROOT_URL      -- the root domain of the MarkUs instance.
ROOT_DIR      -- the directory containing the group repos.
ASSIGMENT_ID  -- the ID of the assignment.
FILE_NAME     -- the name of the test results file .
process_marks -- function for converting test results into a map from criteria
                 to grade. See process_marks docstring below.

"""

from markusapi import Markus

# Required macros
API_KEY = 'MjA5MDdkMjlmZzTlmMXTc5NmZEjNTgE0ODIa0Mm1UQ='
ROOT_URL = 'http://localhost:3000/'
ROOT_DIR = 'root/repos'
ASSIGNMENT_ID = 1
FILE_NAME = 'test_results.txt'

def process_marks(file_contents):
    """ (str) -> dict of str:float
    Parse the contents of a test results file (as a string),
    returning a map from criteria title to mark.

    Criteria titles need to be properly formatted, as they appear
    in the assignment's rubric (punctuation included).
    Marks need to be valid numerics, or 'nil'.
    """
    d = {}
    d['My Criteria 1.'] = 1.0
    d['My Criteria 2.'] = 'nil'
    return d


""" --------Ideally, nothing below need be touched-------- """

# Initialize an instance of the API class
api = Markus(API_KEY, ROOT_URL)
print('Initialized Markus object successfully.')
group_names = api.get_groups(ASSIGNMENT_ID).keys()

# Upload the test results.
for group in group_names:
    with open(ROOT_DIR + '/' + group + '/' + FILE_NAME) as open_file:
        try:
            file_contents = open_file.read()
            api.upload_test_results(ASSIGNMENT_ID, group,
                                    FILE_NAME, file_contents)
        except:
            print('Error: uploading results for {} failed.'.format(locals()))
print('Done uploading results.')
        
# All test results files are now uploaded.
# We now want to extract marks from each file.
for group in group_names:
    with open(ROOT_DIR + '/' + group + '/' + FILE_NAME) as open_file:
        try:
            file_contents = open_file.read()
            results = process_marks(file_contents)
            api.update_marks_single_group(results, ASSIGNMENT_ID, group)
        except:
            print('Error: updating marks for {} failed.'.format(locals()))
print('Done updating marks.')
print('Finished')


