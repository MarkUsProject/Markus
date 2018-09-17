#!/usr/bin/env python3

import subprocess
import sys

if __name__ == '__main__':

    ref_name = sys.argv[1]
    old_commit = sys.argv[2]
    new_commit = sys.argv[3]
    # check 1: allow branches other than master
    if ref_name != 'refs/heads/master':
        sys.exit()
    # no need to check at this point if old_commit or new_commit are 0, since master can't be deleted or created
    # check 2: forbid commits reachable from old_commit but not from new_commit, i.e. the old tree was replaced
    rev_list = subprocess.run(['git', 'rev-list', old_commit, '^{}'.format(new_commit)], stdout=subprocess.PIPE,
                              universal_newlines=True)
    if rev_list.stdout:
        print('[MARKUS] Error: forced push is not allowed on master!')
        sys.exit(1)
