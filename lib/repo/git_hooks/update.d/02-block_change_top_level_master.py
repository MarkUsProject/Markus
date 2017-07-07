#!/usr/bin/env python3

import subprocess
import sys

if __name__ == '__main__':

    ref_name = sys.argv[1]
    old_commit = sys.argv[2]
    new_commit = sys.argv[3]
    if ref_name == 'refs/heads/master':
        # no need to check if old_commit or new_commit are 0, master can't be deleted or created
        old_ls = subprocess.run(['git', 'ls-tree', '--name-only', old_commit], stdout=subprocess.PIPE,
                                universal_newlines=True)
        new_ls = subprocess.run(['git', 'ls-tree', '--name-only', new_commit], stdout=subprocess.PIPE,
                                universal_newlines=True)
        if old_ls.stdout != new_ls.stdout:  # there are changes to the top level files/directories
            log = subprocess.run(['git', 'log', '--format=format:%ae', '{}...{}'.format(old_commit, new_commit)],
                                 stdout=subprocess.PIPE, universal_newlines=True)
            for email in log.stdout.splitlines():
                if email != 'markus@markus.com':  # user change
                    # TODO Add signature for markus commits and verify it here? Or rely on env variable set by Alan?
                    print('[MARKUS] Modifying top level files and directories is not allowed on master!')
                    exit(1)
