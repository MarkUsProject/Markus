#!/usr/bin/python
# Interface for python to interact with API.

# The behaviour we seek is for a user to be able to import
# this module, and perform API functions without having to 
# specify the API auth key and URL with each call.

#TODO debug https requests.

import http.client, urllib, sys, socket, os
import urllib.request
from urllib.parse import urlparse
import json
import csv
import socket

class ApiInterface:
    def __init__(self, api_key, url, protocol="http", verbose=True):
        self.api_key = api_key
        self.url = url
        self.parsed_url = urlparse(url.strip())
        self.protocol = protocol
        self.verbose = verbose

    def get_all_users(self): # Done (unless we add functionality)
        """ (ApiInterface, str) -> list of dict
        Return a list of all users. (we could filter by type if we just want students/tas/admins)
        For now, let's treat a user as a dictionary object.
        """
        params = None
        users = self.submit_request(params, "/api/users.json", 'GET')
        decoded_users = json.loads(users[2].decode('utf-8'))
        return decoded_users

    def new_user(self, user_name, user_type, first_name, last_name, section_name=None, grace_credits=None):
        """ (ApiInterface, str, str, str, str, str) -> bool
        Add a new user to the markus database.
        Returns True if successful, False otherwise.
        Requires: user_name, user_type, first_name, last_name
        Optional: section_name, grace_credits
        """
        params = {'user_name': user_name, 'type': user_type, 'first_name': first_name, 'last_name': last_name}
        if section_name != None:
            params['section_name'] = section_name
        if grace_credits != None:
            params['grace_credits'] = grace_credits
        students = self.submit_request(params, "/api/users", "POST")
        return students

    def get_assignments(self):
        """ (ApiInterface) -> list of dict
        Return a list of all assignments.
        """
        #params = urllib.parse.urlencode({'limit':1})
        params = None
        assignments = self.submit_request(params, "/api/assignments.json", 'GET')
        decoded_assignments = json.loads(assignments[2].decode('utf-8'))
        return decoded_assignments

    def get_groups(self, assignment):
        """ (ApiInterface, int) -> list of dict
        Return a list of all groups associated with the given assignment.
        """
        params = None
        groups = self.submit_request(params, "/api/assignments/" + str(assignment) + "/groups.json", 'GET') # obvsly needs to be changed.
        decoded_groups = json.loads(groups[2].decode('utf-8'))
        return decoded_groups

    def get_groups_by_name(self, assignment):
        """ (ApiInterface, int) -> dict of str to int
        Return a dictionary mapping group names to group ids.
        """
        # use assignment/id/groups/group_ids_by_name route
        params = None
        pairs = self.submit_request(params, "api/assignments/" + str(assignment) + "/groups/group_ids_by_name.json", 'GET')
        return json.loads(pairs[2].decode('utf-8'))

    # Works
    def upload_test_results_old(self, assignment_id, group_id, FILE): # should take name and contents
        """ (ApiInterface, FILE) -> bool
        Take an open file, upload it to Markus.
        """
        params = {}
        params['filename'] = FILE.name
        params['file_content'] = FILE.read() # put this in script
        url = self.get_path(assignment_id, group_id) + 'test_results.xml'
        return self.submit_request(params, url, 'POST')

    def upload_test_results(self, assignment_id, group_id, title, content): # should take name and contents
        """ (ApiInterface, int, int, string, string) -> bool
        Take a string and title, upload it to Markus.
        """
        params = {}
        params['filename'] = title
        params['file_content'] = content
        url = self.get_path(assignment_id, group_id) + 'test_results.xml'
        return self.submit_request(params, url, 'POST')

    def get_path(self, assignment_id, group_id):
        # Helper for formatting path
        return ('/api/assignments/' + str(assignment_id) + '/groups/' + str(group_id) + '/')

    def get_group_submission_downloads(self):
        pass

    def update_marks_single_group(self, titles_to_mark, assignment_id, group_id):
        """ (ApiInterface, dict, int, int) -> bool
        Update the marks of a single group.
        Requires: - titles_to_mark matches criteria titles to the grades we want.
                  - assignment_id is the assignment id.
                  - group_id is the group id.
        """
        params = titles_to_mark
        url_parts = ["/api/assignments/",
                         str(assignment_id),
                         "/groups/",
                         str(group_id),
                         "/update_marks"]
        return self.submit_request(params, ''.join(url_parts), "PUT")

    # Defunct (no longer what we want)
    def update_marks_all(self, open_csv_file):
        """ (ApiInterface, csv) -> bool
        Take a csv file object (formatted properly), read it, and upload the marks.
        Return True if the operation succeeds.
        """
        # First, we are going to need to read and parse the file.
        # What should a line in the file look like?
        # >> groupname/id,crit1,crit2,crit3
        # >> c9magnar,3,1,2
        
        groups_by_name = self.get_groups_by_name(1) # fix
        reader = csv.reader(open_csv_file)
        for row in reader:
            print(row)
            assignment_id = row[0]
            params = {}
            group_name = str(row[1])
            self.update_marks_single_group(params, assignment_id, groups_by_name[group_name])
        return True

    def submit_request(self, params, path, request_type):
        auth_header = "MarkUsAuth %s" % self.api_key
        headers = { "Authorization": auth_header,
            "Content-type": "application/x-www-form-urlencoded" }
        if request_type == "GET": # we only want this for GET requests
            headers["Accept"] = "text/plain"
        try:
            resp = None; conn = None
            if self.protocol == "http":
                conn = http.client.HTTPConnection(self.parsed_url.netloc)
            elif self.protocol == "https":
                conn = http.client.HTTPSConnection(self.parsed_url.netloc)
                print('conn established')
            else:
                print("Panic! Neither http nor https URL.")
                sys.exit(1)
            if (params) != None:
                params = urllib.parse.urlencode(params)
            print('request ready')
            conn.request(request_type, (self.parsed_url.path + path), params, headers)
            print('request sent')
            resp = conn.getresponse()
            lst = [resp.status, resp.reason]
            if self.verbose: # Is verbose turned on?
                data = resp.read()
                lst.append(data)
            conn.close()
            return lst # currently a list of json formatted strings.
        except http.client.HTTPException as e: # Catch HTTP errors
            print(str(e), file=sys.stderr)
            sys.exit(1)
    #    except socket.error (value, message):
    #        if value == 111: # Connection Refused
    #            print("%s: %s" % (self.parsed_url.netloc, message), file=sys.stderr)
    #            sys.exit(1)
    #        else:
    #            print("%s: %s (Errno: %s)" % (self.parsed_url.netloc, message, value), file=sys.stderr)
    #            sys.exit(1)

