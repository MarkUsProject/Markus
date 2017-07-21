#!/usr/bin/env python3

import os
import subprocess
import sys

if __name__ == '__main__':

    ref_name = sys.argv[1]
    old_commit = sys.argv[2]
    new_commit = sys.argv[3]
    # no need to check if old_commit or new_commit are 0, master can't be deleted or created
    if ref_name == 'refs/heads/master' and os.environ.get('REMOTE_USER') is not None:  # push not coming from MarkUs
        # check 1: created/deleted top level files/directories
        old_ls = subprocess.run(['git', 'ls-tree', '--name-only', old_commit], stdout=subprocess.PIPE,
                                universal_newlines=True)
        new_ls = subprocess.run(['git', 'ls-tree', '--name-only', new_commit], stdout=subprocess.PIPE,
                                universal_newlines=True)
        if old_ls.stdout != new_ls.stdout:
            print('[MARKUS] Error: creating/deleting top level files and directories is not allowed on master!')
            exit(1)
        # check 2: modified top level files
        changes = subprocess.run(['git', 'diff', '--name-only', '--no-renames', old_commit, new_commit],
                                 stdout=subprocess.PIPE, universal_newlines=True)
        if any(os.sep not in change for change in changes.stdout.splitlines()):
            print('[MARKUS] Error: modifying top level files is not allowed on master!')
            exit(1)
