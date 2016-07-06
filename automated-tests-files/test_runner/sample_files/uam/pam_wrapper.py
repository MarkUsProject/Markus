#!/usr/bin/env python3

import json
import os
import subprocess
import sys


class CourseraWrapper:

    test_files = {'tx6bS': 'test.py'}

    def print_result(self, fractional_score, feedback):
        print(json.dumps({'fractionalScore': fractional_score, 'feedback': feedback}))

    def print_results(self, result_filename, timeout_filename):
        try:
            with open(result_filename) as result_file:
                result = json.load(result_file)
                passed = 0
                failed = 0
                feedback = []
                for test_class_result in result['results'].values():
                    if 'passes' in test_class_result:
                        for test_name, test_desc in test_class_result['passes'].items():
                            passed += 1
                    if 'failures' in test_class_result:
                        for test_name, test_stack in test_class_result['failures'].items():
                            failed += 1
                            feedback.append(test_stack['message'])
                    if 'errors' in test_class_result:
                        for test_name, test_stack in test_class_result['errors'].items():
                            failed += 1
                            feedback.append(test_stack['message'])
                total = passed + failed
                fractional_score = passed/total if total > 0 else 0.0
                feedback.append('All tests passed.') if len(feedback) == 0 else feedback.insert(0, 'Some tests failed:')
                self.print_result(fractional_score=fractional_score, feedback='\n'.join(feedback))
        except OSError:
            if os.path.isfile(timeout_filename):
                self.print_result(fractional_score=0.0, feedback='Test timeout')
            else:
                print('Test framework error: no result or timeout file generated')
                exit(1)

    def run(self):
        """
        Does this, this and that.
        """
        # get partId from stdin
        part_id = None
        for i, arg in enumerate(sys.argv):
            if arg == 'partId' and len(sys.argv) > (i+1):
                part_id = sys.argv[i+1]
                break
        if part_id is None:
            print('Missing part id')
            exit(1)
        test_file = self.test_files[part_id]
        if test_file is None:
            print('No test file matching part id {}'.format(part_id))
            exit(1)
        # run pam
        path_to_pam = '/grader/uam/pam/pam.py'
        result_filename = 'result.json'
        timeout_filename = 'timedout'
        shell_command = [path_to_pam, result_filename, test_file]
        try:
            subprocess.run(shell_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
            self.print_results(result_filename=result_filename, timeout_filename=timeout_filename)
        except subprocess.CalledProcessError as e:
            print('Test framework error: stdout: {stdout}, stderr: {stderr}'.format(stdout=e.stdout, stderr=e.stderr))
            exit(1)
        except Exception as e:
            print('Test framework error: {exception}'.format(exception=e))
            exit(1)


class MarkusWrapper:

    def print_result(self, name, input, expected, actual, marks, status):
        print('''
            <test>
                <name>{name}</name>
                <input>{input}</input>
                <expected>{expected}</expected>
                <actual>{actual}</actual>
                <marks_earned>{marks}</marks_earned>
                <status>{status}</status>
            </test>
        '''.format(name=name, input=input, expected=expected, actual=actual, marks=marks, status=status))

    def print_results(self, result_filename, timeout_filename):
        try:
            with open(result_filename) as result_file:
                result = json.load(result_file)
                for test_class_result in result['results'].values():
                    if 'passes' in test_class_result:
                        for test_name, test_desc in test_class_result['passes'].items():
                            self.print_result(name=test_name, input=test_desc, expected='', actual='', marks=1,
                                              status='pass')
                    if 'failures' in test_class_result:
                        for test_name, test_stack in test_class_result['failures'].items():
                            self.print_result(name=test_name, input=test_stack['description'], expected='',
                                              actual=test_stack['message'], marks=0, status='fail')
                    if 'errors' in test_class_result:
                        for test_name, test_stack in test_class_result['errors'].items():
                            self.print_result(name=test_name, input=test_stack['description'], expected='',
                                              actual=test_stack['message'], marks=0, status='fail')
        except OSError:
            if os.path.isfile(timeout_filename):
                self.print_result(name='All tests', input='', expected='', actual='Timeout', marks=0, status='fail')
            else:
                self.print_result(name='All tests', input='', expected='', actual='The test framework failed', marks=0,
                                  status='fail')

    def run(self):
        """
        Does this, this and that.
        """
        # run pam
        test_file = 'test.py'
        path_to_virtualenv = '/home/adisandro/Code/uam-virtualenv'
        path_to_uam = '/home/adisandro/Desktop/uam'
        path_to_pam = path_to_uam + '/pam/pam.py'
        result_filename = 'result.json'
        timeout_filename = 'timedout'
        shell_command = '''
            . {path_to_virtualenv}/bin/activate;
            PYTHONPATH={path_to_uam} {path_to_pam} {result_filename} {test_file}
        '''.format(path_to_virtualenv=path_to_virtualenv, path_to_uam=path_to_uam, path_to_pam=path_to_pam,
                   result_filename=result_filename, test_file=test_file)
        try:
            subprocess.run(shell_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True, shell=True)
            self.print_results(result_filename=result_filename, timeout_filename=timeout_filename)
        except subprocess.CalledProcessError as e:
            print('Test framework error: stdout: {stdout}, stderr: {stderr}'.format(stdout=e.stdout, stderr=e.stderr))
            exit(1)
        except Exception as e:
            print('Test framework error: {exception}'.format(exception=e))
            exit(1)


if __name__ == '__main__':
    """
    This wrapper file allows to run the Python AutoMarker (pam) from https://github.com/ProjectAT/uam within Markus'
    test framework, or as a Coursera custom grader.
    """
    # TODO set pam timeout other than the default?
    wrapper = CourseraWrapper()  # or MarkusWrapper()
    wrapper.run()
