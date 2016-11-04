#!/usr/bin/env python3

import os
import psycopg2
import markus_sql_config as cfg
from markus_utils import MarkusUtilsMixin
# from markusapi import Markus


if __name__ == '__main__':

    # prerequisite: run solutions and store them somewhere in the test database
    connection = psycopg2.connect(database=cfg.DATABASE, user=cfg.USER, password=cfg.PASSWORD)
    cursor = connection.cursor()
    for file in os.listdir():
        if not file.endswith('.sql'):
            continue
        try:
            # drop and recreate test schema
            cursor.execute('DROP SCHEMA %s', (cfg.SCHEMA_NAME, ))
            with open(cfg.PATH_TO_SCHEMA) as schema_open:
                schema = schema_open.read()
                cursor.execute(schema)
            with open(file) as file_open:
                sql = file_open.read()
                cursor.execute(sql)
                results = cursor.fetchall()
        except Exception as e:
            MarkusUtilsMixin.print_result(name='All tests', input='', expected='', actual=str(e), marks=0,
                                          status='error')
    cursor.close()
    connection.close()
    # drop and create test schema using schema.ddl, populate it using dataset
    # run .sql file, check results with
    # grant permission to ate_test user to do all the various things
