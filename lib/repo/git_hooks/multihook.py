#!/usr/bin/env python3

import os
import subprocess
import sys

if __name__ == '__main__':

    hook_type = os.path.basename(__file__)
    real_dir = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(real_dir, 'max_file_size')) as f:
        max_file_size = f.read().strip()
    hooks_dir = os.path.join(real_dir, '{}.d'.format(hook_type))
    if os.path.exists(hooks_dir):
        scripts = sorted([os.path.join(hooks_dir, f) for f in os.listdir(hooks_dir)])
        for script in scripts:
            argv2 = sys.argv[1:]
            hook = subprocess.run([script] + argv2, input=sys.stdin.read(), stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, universal_newlines=True, env=env)
            sys.stdout.write(hook.stdout)
            sys.stderr.write(hook.stderr)
            if hook.returncode != 0:
                sys.exit(hook.returncode)
