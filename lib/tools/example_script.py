"""
This file contains an example script that allows a user to upload test results
and then submit marks.
"""
import api_python_module
import os

# Required macros
API_KEY = "MjA5MDdkMjlmZTlmMTc5NmZjNTg0ODI0MmU2NGQyZjQ=" # Admin API key.
ROOT_URL = "http://localhost:3000/" # Root url for markus instance
				    # TODO naming convention discuss
ROOT_DIR = "test_root" # Folder that contains subfolders for each group.
ASSIGNMENT = 1
# assignment short id

F = lambda x: {"Vel.":4.0} # F needs to take a file  and return a dict of criteria_title:mark

FILE_NAME = "test_results.txt" # TODO right now this fails if there is already a file uploaded with same name. What should we do
                               # in this case? Replace or ???
                               # Also, the uploaded file is showing the full path + name. Is this okay?

""" --------Nothing below need be touched-------- """

# Initialize an instance of the API class
api = api_python_module.ApiInterface(API_KEY, ROOT_URL)
print("Initialized Api Successfully.")
group_id = 1

name_to_id = api.get_groups_by_name(ASSIGNMENT)
#better loop structure
#for repo in ROOT_DIR:

group_names = ['group_0001', 'group_0002', 'group_0003']
#file = ROOT_DIR + '/' + group_name + '/' + FILE_NAME
for group in group_names:
    with open(ROOT_DIR + '/' + group + '/' + FILE_NAME) as open_file:
        file_contents = open_file.read()
        print(file_contents)
        group_id = name_to_id[group]
        api.upload_test_results(ASSIGNMENT, group_id, FILE_NAME, file_contents)
        
'''
for subdir, dirs, files in os.walk(ROOT_DIR):
    # perform some processing to get correct file path.
    # How should we identify which files have test results?
    for file in files:
        if str(file) == FILE_NAME:
            with open(subdir + '/' + file) as open_file:
                file_contents = open_file.read()
                api.upload_test_results(ASSIGNMENT, group_id, FILE_NAME, file_contents)
                group_id = 2
'''
# All test results files are now uploaded.
# Now we want to extract marks from each file.
# Since the format of the test results file is 
# not standardized, we require the user to submit a function
# that takes an open FILE object, and returns a float.
"""
group_id = 1
print(ROOT_DIR)
for subdir, dirs, files in os.walk(ROOT_DIR):
    for file in files:
        if str(file) == FILE_NAME:
            open_file = open(subdir + '/' + file)
            result = F(open_file) # apply our function to get the desired mark.
            api.update_marks_single_group(result, ASSIGNMENT, group_id)
            group_id = 2 # change. How can we find this?
            open_file.close()
"""
print('Completed Successfully')
