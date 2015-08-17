#!/usr/bin/python
# Interface for python to interact with MarkUs API.
#
# The purpose of this Python module is for users to be able to 
# perform MarkUs API functions without having to 
# specify the API auth key and URL with each call.
#
##  DISCLAIMER
#
# This script is made available under the OSI-approved
# MIT license. See http://www.markusproject.org/#license for
# more information. WARNING: This script is still considered
# experimental.
#
# (c) by the authors, 2008 - 2015.
#

import http.client, sys, socket, os
from urllib.parse import urlparse, urlencode
import json

class Markus:
    """A class for interfacing with the MarkUs API."""

    def __init__(self, api_key, url, protocol='https'):
        """ (str, str, str) -> Markus
        Initialize an instance of the Markus class.

        A valid API key can be found on the dashboard page of the GUI,
        when logged in as an admin.

        Keywork arguments:
        api_key  -- any admin API key for the MarkUs instance.
        url      -- the root domain of the MarkUs instance.
        protocol -- the protocol requests should use (either http or https).
        """
        self.api_key = api_key
        self.parsed_url = urlparse(url.strip())
        self.protocol = protocol

    def get_all_users(self):
        """ (Markus, str) -> list of dict
        Return a list of every user in the MarkUs instance.
        Each user is a dictionary object, with the following keys:
        'id', 'user_name', 'first_name', 'last_name',
        'type', 'grace_credits', 'notes_count'.
        """
        params = None
        response = self.submit_request(params, '/api/users.json', 'GET')
        return Markus.decode_response(response)

    def new_user(self, user_name, user_type, first_name,
                 last_name, section_name=None, grace_credits=None):
        """ (Markus, str, str, str, str, str, int) -> list
        Add a new user to the MarkUs database.
        Returns a list containing the response's status,
        reason, and data.

        Requires: user_name, user_type, first_name, last_name
        Optional: section_name, grace_credits
        """
        params = { 
            'user_name': user_name,
            'type': user_type,
            'first_name': first_name,
            'last_name': last_name
            }
        if section_name != None:
            params['section_name'] = section_name
        if grace_credits != None:
            params['grace_credits'] = grace_credits
        return self.submit_request(params, '/api/users', 'POST')

    def get_assignments(self):
        """ (Markus) -> list of dict
        Return a list of all assignments.
        """
        params = None
        response = self.submit_request(params, '/api/assignments.json', 'GET')
        return Markus.decode_response(response)

    def get_groups(self, assignment_id):
        """ (Markus, int) -> list of dict
        Return a list of all groups associated with the given assignment.
        """
        params = None
        path = self.get_path(assignment_id) + '.json'
        response = self.submit_request(params, path, 'GET')
        return Markus.decode_response(response)

    def get_groups_by_name(self, assignment_id):
        """ (Markus, int) -> dict of str:int
        Return a dictionary mapping group names to group ids.
        """
        params = None
        path = self.get_path(assignment_id) + '/group_ids_by_name.json'
        response = self.submit_request(params, path, 'GET')
        return Markus.decode_response(response)

    def upload_test_results(self, assignment_id, group_name, title, contents):
        """ (Markus, int, str, str, str) -> list of str
        Upload test results to Markus.

        Keyword arguments:
        assignment_id -- the assignment's id
        group_name    -- the name of the group to which we are uploading
        title         -- the file name that will be displayed
        contents      -- what will be in the file
        """
        groupname_id_map = self.get_groups_by_name(assignment_id)
        group_id = groupname_id_map[group_name]
        params = {}
        params['filename'] = title
        params['file_content'] = contents
        path = self.get_path(assignment_id, group_id) + 'test_results.xml'
        return self.submit_request(params, path, 'POST')

    def update_marks_single_group(self, criteria_mark_map,
                                  assignment_id, group_name):
        """ (Markus, dict, int, int) -> list of str
        Update the marks of a single group. 
        Only the marks specified in criteria_mark_map will be changed.
        To set a mark to unmarked, use 'nil' as it's value.
        Otherwise, marks must have valid numeric types (floats or ints).
        Criteria are specified by their title. Titles must be formatted
        exactly as they appear in the MarkUs GUI, punctuation included.

        Keyword arguments:
        criteria_mark_map -- maps criteria to the desired grade
        assignment_id     -- the assignment's id
        group_name        -- the name of the group whose marks we are updating
        """
        groupname_id_map = self.get_groups_by_name(assignment_id)
        group_id = groupname_id_map[group_name]
        params = criteria_mark_map
        path = self.get_path(assignment_id, group_id) + 'update_marks'
        return self.submit_request(params, path, 'PUT')

    def submit_request(self, params, path, request_type):
        """ (Markus, dict, str, str) -> list of str
        Perform the HTTP/HTTPS request. Return a list 
        containing the response's status, reason, and content.

        Keyword arguments:
        params       -- contains the parameters of the request
        path         -- route to the resource we are targetting
        request_type -- the desired HTTP method (usually 'GET' or 'POST')
        """
        auth_header = 'MarkUsAuth {}'.format(self.api_key)
        print(auth_header)
        headers = { 'Authorization': auth_header,
                    'Content-type': 'application/x-www-form-urlencoded' }
        if request_type == 'GET': # we only want this for GET requests
            headers['Accept'] = 'text/plain'
        if params != None:
            params = urlencode(params)
        try:
            resp = None; conn = None
            if self.protocol == 'http':
                conn = http.client.HTTPConnection(self.parsed_url.netloc)
            elif self.protocol == 'https':
                conn = http.client.HTTPSConnection(self.parsed_url.netloc)
            else:
                print('Panic! Neither http nor https URL.')
                sys.exit(1)
            conn.request(request_type,
                         self.parsed_url.path + path,
                         params,
                         headers)
            resp = conn.getresponse()
            lst = [resp.status, resp.reason, resp.read()]
            conn.close()
            return lst
        except http.client.HTTPException as e: # Catch HTTP errors
            print(str(e), file=sys.stderr)
            sys.exit(1)
        except OSError as e:
            print('OSError: ' + str(e))
            sys.exit(1)

    # Helpers
    def get_path(self, assignment_id, group_id=None):
        """Return a path to an assignment's groups, or a single group."""
        path = '/api/assignments/' + str(assignment_id) + '/groups'
        if group_id != None:
            path += '/' + str(group_id) + '/'
        return path

    def decode_response(resp):
        """Converts response from submit_request into python dict."""
        return json.loads(resp[2].decode('utf-8'))


