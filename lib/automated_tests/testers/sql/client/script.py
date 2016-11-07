#!/usr/bin/env python3

import sys
from markus_sql_tester import MarkusSQLTester
# from markusapi import Markus


if __name__ == '__main__':

    tester = MarkusSQLTester()
    tester.run()
    # use markus apis if needed (uncomment import markusapi)
    root_url = sys.argv[1]
    api_key = sys.argv[2]
    assignment_id = sys.argv[3]
    group_id = sys.argv[4]
    # file_name = 'result.json'
    # api = Markus(api_key, root_url)
    # with open(file_name) as open_file:
    #     api.upload_feedback_file(assignment_id, group_id, file_name, open_file.read())
