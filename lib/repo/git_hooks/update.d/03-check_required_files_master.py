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
        # TODO {'A1': {'required': [], 'required_only': true}}
        req = json.loads(requirements.stdout)
        changes = subprocess.run(['git', 'diff', '--name-status', '--no-renames', old_commit, new_commit],
                                 stdout=subprocess.PIPE, universal_newlines=True)
        for change in changes.stdout.splitlines():
            status, path = change.split(maxsplit=1)
            assignment, file_path = path.split(os.sep, maxsplit=1)  # never a top level file/dir
            # TODO Think about an assignment that is hidden after being enabled for a while, it goes through for now
            req_a = req.get(assignment)
            # check if the assignment forbids adding non-required files
            # (everything else is allowed, which is safe against policy changes to the assignment after students
            # already pushed: A required, D required and non-required, M required and non-required)
            # warn about..
            if req_a is not None and status == 'A' and req_a['required_only'] and file_path not in req_a['required']:
                print('[MARKUS] Error: {} is required by {} and cannot be deleted!'.format(file_path, assignment))
                exit(1)
                # TODO for each assignment in the changes, warn about missing files
                # print('[MARKUS] Warning: some required files are missing.')
