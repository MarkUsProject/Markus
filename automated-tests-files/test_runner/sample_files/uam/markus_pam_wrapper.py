#!/usr/bin/env python3

import json
import os
import subprocess
from enum import Enum


class PAMResult:
    """
    A test result from pam.
    """

    class Status(Enum):
        PASS = 1
        FAIL = 2
        ERROR = 3

    def __init__(self, name, status, description='', message=''):
        self.name = name
        self.status = status
        self.description = description
        self.message = message


class PAMWrapper:
    """
    A base wrapper class to run the Python AutoMarker (pam - https://github.com/ProjectAT/uam).
    """

    def __init__(self, path_to_uam, test_files, result_filename='result.json', timeout_filename='timedout',
                 path_to_virtualenv=None):
        """
        Initializes the various parameters to run pam.
        :param path_to_uam: The path to the uam installation.
        :param test_files: A list of test files to be run by pam.
        :param result_filename: The file name of pam's json output.
        :param timeout_filename: The file name of pam's output when a test times out.
        :param path_to_virtualenv: The path to the virtualenv to be used to run pam, can be None if all necessary
        dependencies are installed system-wide.
        """
        self.path_to_uam = path_to_uam
        self.path_to_pam = path_to_uam + '/pam/pam.py'
        self.test_files = test_files
        self.result_filename = result_filename
        self.timeout_filename = timeout_filename
        self.path_to_virtualenv = path_to_virtualenv

    def collect_results(self):
        """
        Collects pam results.
        :return: A list of results (possibly empty), or None if the tests timed out.
        """
        results = None
        try:
            with open(self.result_filename) as result_file:
                results = []
                result = json.load(result_file)
                for test_class_result in result['results'].values():
                    if 'passes' in test_class_result:
                        for test_name, test_desc in test_class_result['passes'].items():
                            results.append(
                                PAMResult(name=test_name, status=PAMResult.Status.PASS, description=test_desc))
                    if 'failures' in test_class_result:
                        for test_name, test_stack in test_class_result['failures'].items():
                            results.append(
                                PAMResult(name=test_name, status=PAMResult.Status.FAIL,
                                          description=test_stack['description'], message=test_stack['message']))
                    if 'errors' in test_class_result:
                        for test_name, test_stack in test_class_result['errors'].items():
                            results.append(
                                PAMResult(name=test_name, status=PAMResult.Status.ERROR,
                                          description=test_stack['description'], message=test_stack['message']))
        except OSError:
            if not os.path.isfile(self.timeout_filename):
                print('Test framework error: no result or time out generated')
                exit(1)
        return results

    def print_results(self, results):
        """
        Prints pam results: must be overridden.
        :param results: A list of results (possibly empty), or None if the tests timed out.
        """
        pass

    def run(self):
        """
        Runs pam.
        """
        if self.path_to_virtualenv is None:
            shell_command = [self.path_to_pam, self.result_filename]
            shell_command.extend(self.test_files)
            shell = False
        else:
            shell_command = '''
                . {cmd.path_to_virtualenv}/bin/activate;
                {cmd.path_to_pam} {cmd.result_filename} {files}
            '''.format(cmd=self, files=' '.join(self.test_files))
            shell = True
        try:
            env = os.environ.copy()
            env['PYTHONPATH'] = self.path_to_uam  # some needed libs are here
            subprocess.run(shell_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True, shell=shell,
                           env=env)
            results = self.collect_results()
            self.print_results(results)
        except subprocess.CalledProcessError as e:
            print('Test framework error: stdout: {stdout}, stderr: {stderr}'.format(stdout=e.stdout, stderr=e.stderr))
            exit(1)
        except Exception as e:
            print('Test framework error: {exception}'.format(exception=e))
            exit(1)


class MarkusPAMWrapper(PAMWrapper):
    """
    A wrapper to run the Python AutoMarker (pam - https://github.com/ProjectAT/uam) within Markus' test framework.
    """

    def print_result(self, name, input, expected, actual, marks, status):
        """
        Prints one pam result in the format expected by Markus' test framework.
        """
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

    def print_results(self, results):
        """
        Prints pam results.
        :param results: A list of results (possibly empty), or None if the tests timed out.
        """
        if results is None:
            self.print_result(name='All tests', input='', expected='', actual='Timeout', marks=0, status='fail')
        else:
            for result in results:
                marks = 1 if result.status == PAMResult.Status.PASS else 0
                status = 'pass' if result.status == PAMResult.Status.PASS else 'fail'
                self.print_result(name=result.name, input=result.description, expected='', actual=result.message,
                                  marks=marks, status=status)


if __name__ == '__main__':
    # TODO set pam timeout other than the default?
    markus_test_files = ['test.py']
    wrapper = MarkusPAMWrapper(path_to_uam='/home/adisandro/Desktop/uam', test_files=markus_test_files,
                               path_to_virtualenv='/home/adisandro/Code/uam-virtualenv')
    wrapper.run()
