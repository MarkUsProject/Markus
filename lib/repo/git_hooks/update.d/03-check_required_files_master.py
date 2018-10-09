#!/usr/bin/env python3

import json
import os
import sys
import subprocess

if __name__ == '__main__':

    ref_name = sys.argv[1]
    old_commit = sys.argv[2]
    new_commit = sys.argv[3]
    # check 1: allow branches other than master
    if ref_name != 'refs/heads/master':
        sys.exit()
    # no need to check at this point if old_commit or new_commit are 0, master can't be deleted or created
    # check 2: allow MarkUs through
    if os.environ.get('REMOTE_USER') is None:
        sys.exit()
    req = subprocess.run(['git', 'show', '{}:{}'.format(old_commit, '.required.json')], stdout=subprocess.PIPE,
                         universal_newlines=True)
    requirements = json.loads(req.stdout)
    changes = subprocess.run(['git', 'diff', '--name-status', '--no-renames', old_commit, new_commit],
                             stdout=subprocess.PIPE, universal_newlines=True)
    # check 3: honor required files
    # check if the assignment forbids adding non-required files; everything else is allowed, which is safe against
    # changes to the assignment after students already pushed some work:
    # A required is ok
    # A non-required is rejected or warned, depending on required_only flag
    # D required is warned
    # D non-required is ok
    # M required is ok
    # M non-required is warned
    for change in changes.stdout.splitlines():
        status, path = change.split(maxsplit=1)
        if '/' not in path:  # ignore top-level changes
            continue
        assignment, file = path.split('/', maxsplit=1)
        assignment_req = requirements.get(assignment)
        if assignment_req is None:
            # this can happen only if an assignment becomes hidden after being visible for a while
            # (the top level hook prevents the creation of an arbitrary assignment directory)
            continue
        req_files = assignment_req['required']
        if not req_files:
            continue
        if status == 'A':
            if file not in req_files:
                msg = f"you are adding non-required '{file}' to assignment '{assignment}', which only requires " \
                      f"'{', '.join(req_files)}'"
                if assignment_req['required_only']:
                    print(f'[MARKUS] Error: {msg}!')
                    sys.exit(1)
                else:
                    print(f'[MARKUS] Warning: {msg}.')
        elif status == 'D' and file in req_files:
            print(f"[MARKUS] Warning: you are deleting required '{file}' from assignment '{assignment}'.")
        elif status == 'M' and file not in req_files:
            print(f"[MARKUS] Warning: you are modifying non-required '{file}' in assignment '{assignment}', which only "
                  f"requires '{', '.join(req_files)}'.")
    # check 4: warn about missing files
    new_ls = subprocess.run(['git', 'ls-tree', '-r', '--name-only', new_commit], stdout=subprocess.PIPE,
                            universal_newlines=True)
    files = {tuple(path.split('/', maxsplit=1)) for path in new_ls.stdout.splitlines()}
    for assignment in requirements.keys():
        for req_file in requirements[assignment]['required']:
            if (assignment, req_file) not in files:
                print(f"[MARKUS] Warning: required '{req_file}' is missing in assignment '{assignment}'.")
