#!/usr/bin/env python3

import subprocess
import sys

if __name__ == '__main__':

    ref_name = sys.argv[1]
    if ref_name == 'refs/heads/master':
        old_commit = sys.argv[2]
        new_commit = sys.argv[3]
        proc = subprocess.run(['git', 'rev-list', old_commit, '^{}'.format(new_commit)], stdout=subprocess.PIPE,
                              universal_newlines=True)
        if proc.stdout:
            # there are commits reachable from old_commit but not from new_commit, i.e. the old tree was replaced
            print('Forced push is not allowed on master!')
            exit(1)
