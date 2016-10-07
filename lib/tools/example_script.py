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
FILE_NAME     -- the name of the test results file.
process_marks -- function for converting test results into a map from criteria
                 to grade. See process_marks docstring below.

"""

from markusapi import Markus

# Required macros
API_KEY = 'MjA5MDdkMjlmZzTlmMXTc5NmZEjNTgE0ODIa0Mm1UQ='
ROOT_URL = 'http://localhost:3000/'
ROOT_DIR = 'repos'
ASSIGNMENT_ID = 1
FILE_NAME = 'report.txt'


def process_marks(file_contents):
    """ (str) -> dict of str:float
    Parse the contents of a test results file (as a string),
    returning a map from criteria title to mark.

    Criteria titles need to be properly formatted, as they appear
    in the assignment's marking scheme (punctuation included).
    Marks need to be valid numerics, or 'nil'.
    If the criterion is a Rubric, the mark just needs to be the
    rubric level, and will be multiplied by the weight automatically.
    """
    d = {'My Criterion 1.': 1.0, 'My Criterion 2.': 'nil'}
    return d

""" --------Ideally, nothing below need be touched-------- """

# Initialize an instance of the API class
api = Markus(API_KEY, ROOT_URL)
print('Initialized Markus object successfully.')
groups = api.get_groups(ASSIGNMENT_ID)

for group in groups:
    group_name = group['group_name']
    group_id = group['id']
    try:
        with open(ROOT_DIR + '/' + group_name + '/' + FILE_NAME) as open_file:
            file_contents = open_file.read()
            # Upload the feedback file
            try:
                response = api.upload_feedback_file(ASSIGNMENT_ID, group_id, FILE_NAME, file_contents)
                print('Uploaded feedback file for {}, Markus responded: {}'.format(group_name, response))
            except:
                print('Error: uploading feedback file for {} failed'.format(group_name))
            # Extract and upload marks from the feedback file
            try:
                results = process_marks(file_contents)
                response = api.update_marks_single_group(results, ASSIGNMENT_ID, group_id)
                print('Uploaded marks for {}, Markus responded: {}'.format(group_name, response))
                response = api.update_marking_state(ASSIGNMENT_ID, group_id, 'complete')
                print('Updated marking state for  {}, Markus responded: {}'.format(group_name, response))
            except:
                print('Error: uploading marks for {} failed'.format(group_name))
    except:
        print('Error: accessing repository {} failed.'.format(group_name))

print('Finished')
