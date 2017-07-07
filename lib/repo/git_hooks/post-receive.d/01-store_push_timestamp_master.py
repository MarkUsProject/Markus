#!/usr/bin/env python3

import datetime
import sys

if __name__ == '__main__':

    new_commit = None
    for line in sys.stdin:
        old_commit, new_commit, ref_name = line.split(' ')
        if ref_name != 'refs/heads/master':
            continue
    if new_commit:  # store timestamp only if it's a push to master
        # TODO get the current time, then invoke api to create entry in table X (repo, new_commit, time)
        timestamp = str(datetime.datetime.now())  # TODO Figure out the timezone problem
