#!/usr/bin/env python3

import sys
import markus_sql_config as cfg
from markus_sql_tester import MarkusSQLTester
# from markusapi import Markus


if __name__ == '__main__':

    # Modify uppercase variables with your settings
    # The dataset files to be used for testing each student sql file; the student sql file names are the keys, the lists
    # of dataset files are the values.
    DATA_FILES = {'correct.sql': cfg.ALL_DATA_FILES, 'badcolumnnames.sql': cfg.ALL_DATA_FILES,
                  'badcolumntypes.sql': cfg.ALL_DATA_FILES, 'badnumrows.sql': cfg.ALL_DATA_FILES,
                  'badrowscontent.sql': cfg.ALL_DATA_FILES, 'badrowsorder.sql': cfg.ALL_DATA_FILES}
    # The schema name
    SCHEMA_NAME = 'ate'
    tester = MarkusSQLTester(oracle_database=cfg.ORACLE_DATABASE, test_database=cfg.TEST_DATABASE, user_name=cfg.USER,
                             user_password=cfg.PASSWORD, data_files=DATA_FILES, schema_name=SCHEMA_NAME,
                             path_to_solution=cfg.PATH_TO_SOLUTION)
    tester.run()
    # use markus apis if needed (uncomment import markusapi)
    root_url = sys.argv[1]
    api_key = sys.argv[2]
    assignment_id = sys.argv[3]
    group_id = sys.argv[4]
    # file_name = 'result.txt'
    # api = Markus(api_key, root_url)
    # with open(file_name) as open_file:
    #     api.upload_feedback_file(assignment_id, group_id, file_name, open_file.read())
