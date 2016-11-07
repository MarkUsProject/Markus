import os
import psycopg2
import markus_sql_config as cfg
from markus_utils import MarkusUtilsMixin
# from markusapi import Markus


class MarkusSQLTester(MarkusUtilsMixin):

    def print_result_file(self, name, actual, oracle_results, test_results, output_open):
        output_open.write('{} - {}:\n'.format(name, actual))
        output_open.write('Expected:\n{}'.format(oracle_results))
        output_open.write('Actual:\n{}'.format(test_results))

    def run(self):

        test_connection = psycopg2.connect(database=cfg.TEST_DATABASE, user=cfg.USER, password=cfg.PASSWORD)
        test_cursor = test_connection.cursor()
        oracle_connection = psycopg2.connect(database=cfg.ORACLE_DATABASE, user=cfg.USER, password=cfg.PASSWORD)
        oracle_cursor = oracle_connection.cursor()
        with open(cfg.OUTPUT_FILE) as output_open:
            for sql_file in os.listdir():
                if not sql_file.endswith('.sql'):
                    continue
                test_name = sql_file.partition('.')[0]
                try:
                    # fetch results from oracle
                    for data_file in cfg.DATA_FILES:
                        data_name = data_file.partition('.')[0]
                        oracle_cursor.execute('SELECT * FROM %(view)s',
                                              {'view': '{}.oracle_{}'.format(data_name, test_name)})
                        oracle_results = oracle_cursor().fetchall()
                        # drop and recreate test schema + dataset
                        test_cursor.execute('DROP SCHEMA IF EXISTS %(schema)s CASCADE',
                                            {'schema': psycopg2.extensions.AsIs(cfg.SCHEMA_NAME)})
                        test_cursor.execute('CREATE SCHEMA %(schema)s',
                                            {'schema': psycopg2.extensions.AsIs(cfg.SCHEMA_NAME)})
                        test_cursor.execute('SET search_path TO %(schema)s, public',
                                            {'schema': psycopg2.extensions.AsIs(cfg.SCHEMA_NAME)})
                        with open(os.path.join(cfg.PATH_TO_SCHEMA, cfg.SCHEMA_FILE)) as schema_open:
                            schema = schema_open.read()
                            test_cursor.execute(schema)
                        with open(os.path.join(cfg.PATH_TO_SCHEMA, data_file)) as data_open:
                            data = data_open.read()
                            test_cursor.execute(data)
                        # run test sql
                        with open(sql_file) as sql_open:
                            sql = sql_open.read()
                            test_cursor.execute(sql)
                            test_connection.commit()
                            test_results = test_cursor.fetchall()
                            # compare results with oracle
                            out = ''
                            marks = 1
                            status = 'pass'
                            # TODO check 1: column names
                            # check 2: num rows
                            test_num_results = len(test_results)
                            oracle_num_results = len(oracle_results)
                            if test_num_results != oracle_num_results:
                                out = 'Expected {} results but got {}'.format(oracle_num_results, test_num_results)
                                marks = 0
                                status = 'fail'
                            # TODO check 3: rows content
                            self.print_result(name=test_name, input='', expected='', actual=out, marks=marks,
                                              status=status)
                            self.print_result_file(name=test_name, actual=out, oracle_results=oracle_results,
                                                   test_results=test_results)
                except Exception as e:
                    test_connection.commit()
                    self.print_result(name=test_name, input='', expected='', actual=str(e), marks=0, status='error')
            oracle_cursor.close()
            oracle_connection.close()
            test_cursor.close()
            test_connection.close()
