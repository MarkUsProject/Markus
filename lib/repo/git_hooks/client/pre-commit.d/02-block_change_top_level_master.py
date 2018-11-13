#!/usr/bin/env python3

import os
import os.path
import subprocess
import sys


if __name__ == '__main__':
    print('[MarkUs] Checking whether top-level files/directories were created/modified...')
    exceptions = {'.gitignore'}  # top-level exceptions
    against = 'HEAD'
    changed_files = subprocess.run(['git', 'diff-index', '--name-only', against], stdout=subprocess.PIPE,
                            universal_newlines=True)
    current_ls = subprocess.run(['git', 'ls-tree', '--name-only', against], stdout=subprocess.PIPE,
                            universal_newlines=True)
    top_level = current_ls.stdout.splitlines()
    reject = 0
    for filename in changed_files.stdout.splitlines():
        first_component = filename.split('/')[0]
        if first_component in exceptions:
            continue
        if first_component not in top_level:
            print('[MarkUs] Error: Top-level change detected for "{}". (You should unstage this change.)'.format(first_component))
            reject = 1
    exit(reject)
