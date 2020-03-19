import sys
import subprocess

MAX_FILE_SIZE = 5_000_000  # this should be changed to match the config.max_file_size config option

if __name__ == '__main__':
    # get new/updated files:
    changes = subprocess.run(['git', 'diff', '--name-status', '--no-renames', '--diff-filter=d', 'HEAD'],
                             stdout=subprocess.PIPE, universal_newlines=True)
    # check all changed/added files
    for change in changes.stdout.splitlines():
        status, path = change.split(maxsplit=1)
        path = path.strip()
        file_sha = subprocess.run(['git', 'ls-files', '--stage', path],
                                  stdout=subprocess.PIPE, universal_newlines=True).stdout.strip().split()[1]
        file_size_proc = subprocess.run(['git', 'cat-file', '-s', file_sha],
                                   stdout=subprocess.PIPE, universal_newlines=True)
        file_size = file_size_proc.stdout.strip()
        if int(file_size) > MAX_FILE_SIZE:
            mb_size = round(int(file_size) / 1_000_000, 2)
            print(f'[MARKUS] Error: The size of the uploaded file {path} exceeds the maximum of {mb_size} MB.')
            sys.exit(1)
