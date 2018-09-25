#!/usr/bin/env python3

import os
import subprocess
import sys

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
    # check 3: forbid creating/deleting top-level files/directories
    exceptions = {'.gitignore'}  # top-level exceptions
    old_ls = subprocess.run(['git', 'ls-tree', '--name-only', old_commit], stdout=subprocess.PIPE,
                            universal_newlines=True)
    new_ls = subprocess.run(['git', 'ls-tree', '--name-only', new_commit], stdout=subprocess.PIPE,
                            universal_newlines=True)
    old_ls = [line for line in old_ls.stdout.splitlines() if line not in exceptions]
    new_ls = [line for line in new_ls.stdout.splitlines() if line not in exceptions]
    if old_ls != new_ls:
        print('[MARKUS] Error: creating/deleting top level files and directories is not allowed on master!')
        sys.exit(1)
    # check 4: forbid modifying top-level files
    changes = subprocess.run(['git', 'diff', '--name-only', '--no-renames', old_commit, new_commit],
                             stdout=subprocess.PIPE, universal_newlines=True)
    if any('/' not in change for change in changes.stdout.splitlines() if change not in exceptions):
        print('[MARKUS] Error: modifying top level files is not allowed on master!')
        sys.exit(1)
