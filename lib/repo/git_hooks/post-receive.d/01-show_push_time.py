#!/usr/bin/env python3

import subprocess
import sys

if __name__ == '__main__':

    is_master = False
    for ref_info in sys.stdin.readlines():
        _, _, ref_name = ref_info.strip().rpartition(' ')
        if ref_name == 'refs/heads/master':
            is_master = True
            break
    if not is_master:
        sys.exit()
    reflog = subprocess.run(['git', 'reflog', '-n', '1', '--date=local', '--format=format:%gd', 'master'],
                            stdout=subprocess.PIPE, universal_newlines=True)
    if reflog.stdout:
        print('[MARKUS] Your submission has been received: {}'.format(reflog.stdout))
