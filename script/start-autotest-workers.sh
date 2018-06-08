#!/usr/bin/env bash

# start up autotest (rq) workers which are managed by supervisor
source /home/vagrant/markus-autotesting/server/venv/bin/activate
supervisord -c /home/vagrant/markus-autotesting/server/supervisord.conf
deactivate
