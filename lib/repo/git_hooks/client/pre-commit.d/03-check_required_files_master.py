#!/usr/bin/env python3

import json
import os
import sys
import subprocess


if __name__ == '__main__':

    branch = subprocess.run(['git', 'rev-parse', '--abbrev-ref', 'HEAD'], stdout=subprocess.PIPE,
                            universal_newlines=True)
    # Only check master branch
    if branch.stdout.strip() != 'master':
        sys.exit(0)

    requirements = subprocess.run(['git', 'show', 'HEAD:.required.json'], stdout=subprocess.PIPE,
                                  universal_newlines=True)
    required_files = json.loads(requirements.stdout)
    changes = subprocess.run(['git', 'diff-index', '--name-status', '--no-renames', 'HEAD'], stdout=subprocess.PIPE,
                             universal_newlines=True)
    staged_dirs = []

    # Check if the assignment forbids adding non-required files.
    # A required is ok
    # A non-required is rejected
    # D required is warned
    # D non-required is ok
    # M required is ok
    # M non-required is warned
    for change in changes.stdout.splitlines():
        status, path = change.split(maxsplit=1)
        if '/' not in path:  # ignore top-level changes
            continue
        assignment, file_path = path.split('/', maxsplit=1)
        staged_dirs.append(assignment)
        req = required_files.get(assignment)
        if req is None or not req.get('required'):
            # This can happen if either:
            # 1) an assignment becomes hidden after being visible for a while
            #    (the top level hook prevents the creation of an arbitrary assignment directory)
            # 2) the assignment has no required files
            continue
        if status == 'A':
            if file_path not in req['required']:
                msg = "you are adding '{}' to assignment '{}', but it only requires '{}'".format(
                    file_path, assignment, ', '.join(req['required']))
                if req['required_only']:
                    print('[MarkUs] Error: {}!'.format(msg))
                    sys.exit(1)
                else:
                    print('[MarkUs] Warning: {}.'.format(msg))
        elif status == 'D' and file_path in req['required']:
            print("[MarkUs] Warning: you are deleting required file '{}' from assignment '{}'.".format(
                  file_path, assignment))
        elif status == 'M' and file_path not in req['required'] and req['required_only']:
            print("[MarkUs] Warning: you are modifying non-required '{}' in assignment '{}', but it only requires '{}'.".format(
                  file_path, assignment, ', '.join(req['required'])))

    # warn about missing files
    new_ls = subprocess.run(['git', 'ls-files'], stdout=subprocess.PIPE, universal_newlines=True)
    files = {tuple(path.split('/', maxsplit=1)) for path in new_ls.stdout.splitlines()}
    for assignment in staged_dirs:
        if assignment not in required_files:
            continue
        for file_path in required_files[assignment]['required']:
            if (assignment, file_path) not in files:
                print("[MarkUs] Warning: required file '{}' is missing in assignment '{}'.".format(
                      file_path, assignment))
