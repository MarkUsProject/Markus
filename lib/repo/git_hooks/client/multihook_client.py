#!/usr/bin/env python3

import os
import subprocess
import sys

if __name__ == '__main__':
    # Only perform checks when on the master branch.
    branch = subprocess.run(['git', 'rev-parse', '--abbrev-ref', 'HEAD'], stdout=subprocess.PIPE,
                            universal_newlines=True)

    if branch.stdout.strip() != 'master':
        print('[MarkUs] Skipping checks because you aren\'t on the master branch.')
        print('[MarkUs] But please remember that only files on your master branch will be graded!')
        sys.exit(0)

    hook_type = 'pre-commit'
    hooks_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), '{}.d'.format(hook_type))
    if os.path.exists(hooks_dir):
        print('[MarkUs] Running pre-commit checks...')
        scripts = sorted([os.path.join(hooks_dir, f) for f in os.listdir(hooks_dir)])
        for script in scripts:
            hook = subprocess.run([sys.executable, script], input=sys.stdin.read(), stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, universal_newlines=True)
            sys.stdout.write(hook.stdout)
            sys.stderr.write(hook.stderr)
            if hook.returncode != 0:
                sys.exit(hook.returncode)

        print("[MarkUs] Commit looks good! Don't forget to push your work to the MarkUs server.")
