#!/usr/bin/env python3

import sys
import subprocess

MAX_FILE_SIZE = 5_000_000  # this should be changed to match the config.max_file_size config option

if __name__ == '__main__':
    ref_name = sys.argv[1]
    old_commit = sys.argv[2]
    new_commit = sys.argv[3]

    # get new/updated files:
    changes = subprocess.run(['git', 'rev-list', '--objects', f'{old_commit}..{new_commit}'],
                             stdout=subprocess.PIPE, universal_newlines=True)
    # check all changed/added files
    for change in changes.stdout.splitlines():
        sha, *paths = change.split(maxsplit=1)
        if paths:
            path = paths[0].strip()
            file_size_proc = subprocess.run(['git', 'cat-file', '-s', sha],
                                       stdout=subprocess.PIPE, universal_newlines=True)
            file_size = file_size_proc.stdout.strip()
            if int(file_size) > MAX_FILE_SIZE:
                mb_size = round(int(file_size) / 1_000_000, 2)
                print(f'[MARKUS] Error: The size of the uploaded file {path} exceeds the maximum of {mb_size} MB.')
                sys.exit(1)
