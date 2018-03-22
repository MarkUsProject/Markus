#!/usr/bin/env python3

import json
import os
import sys
import subprocess

if __name__ == '__main__':

    ref_name = sys.argv[1]
    old_commit = sys.argv[2]
    new_commit = sys.argv[3]
    # no need to check if old_commit or new_commit are 0, master can't be deleted or created
    if ref_name == 'refs/heads/master' and os.environ.get('REMOTE_USER') is not None:  # push not coming from MarkUs
        requirements = subprocess.run(['git', 'show', '{}:{}'.format(old_commit, '.required.json')],
                                      stdout=subprocess.PIPE, universal_newlines=True)
        required_files = json.loads(requirements.stdout)
        changes = subprocess.run(['git', 'diff', '--name-status', '--no-renames', old_commit, new_commit],
                                 stdout=subprocess.PIPE, universal_newlines=True)
        # check if the assignment forbids adding non-required files; everything else is allowed, which is safe against
        # changes to the assignment after students already pushed some work:
        # A required is ok
        # A non-required is rejected
        # D required is warned
        # D non-required is ok
        # M required is ok
        # M non-required is warned
        for change in changes.stdout.splitlines():
            status, path = change.split(maxsplit=1)
            assignment, file_path = path.split('/', maxsplit=1)  # it can never be a top level file/dir
            req = required_files.get(assignment)
            if req is None:
                # this can happen only if an assignment becomes hidden after being visible for a while
                # (the top level hook prevents the creation of an arbitrary assignment directory)
                print("[MARKUS] Warning: assignment '{}' is currently hidden".format(assignment))
                continue
            if status == 'A':
                if file_path not in req['required']:
                    msg = "you are adding '{}' to assignment '{}', but it only requires '{}'".format(
                          file_path, assignment, ', '.join(req['required']))
                    if req['required_only']:
                        print('[MARKUS] Error: {}!'.format(msg))
                        exit(1)
                    else:
                        print('[MARKUS] Warning: {}.'.format(msg))
            elif status == 'D' and file_path in req['required']:
                print("[MARKUS] Warning: you are deleting '{}' from assignment '{}', but it requires it.".format(
                      file_path, assignment))
            elif status == 'M' and file_path not in req['required']:
                print("[MARKUS] Warning: you are modifying '{}' in assignment '{}', but it only requires '{}'.".format(
                      file_path, assignment, ', '.join(req['required'])))
        # warn about missing files
        new_ls = subprocess.run(['git', 'ls-tree', '-r', '--name-only', new_commit], stdout=subprocess.PIPE,
                                universal_newlines=True)
        files = {tuple(path.split('/', maxsplit=1)) for path in new_ls.stdout.splitlines()}
        for assignment in required_files.keys():
            for file_path in required_files[assignment]['required']:
                if (assignment, file_path) not in files:
                    print("[MARKUS] Warning: required file '{}' is missing in assignment '{}'.".format(
                          file_path, assignment))
