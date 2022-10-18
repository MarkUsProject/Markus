#!/usr/bin/env python3

import os
import subprocess
import sys

if __name__ == '__main__':

    hook_type = os.path.basename(__file__)
    hooks_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), '{}.d'.format(hook_type))
    if os.path.exists(hooks_dir):
        scripts = sorted([os.path.join(hooks_dir, f) for f in os.listdir(hooks_dir)])
        for script in scripts:
            argv2 = sys.argv[1:]
            hook = subprocess.run([script] + argv2, input=sys.stdin.read(), stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, universal_newlines=True)
            sys.stdout.write(hook.stdout)
            sys.stderr.write(hook.stderr)
            if hook.returncode != 0:
                sys.exit(hook.returncode)
