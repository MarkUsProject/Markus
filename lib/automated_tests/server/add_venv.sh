#!/usr/bin/env bash

if [ $# -ne 2 ]; then
    echo usage: $0 install_dir venv_name
    exit 1
fi

INSTALLDIR=$1
NAME=$2
VENVDIR=venvs
cd ${INSTALLDIR}
mkdir -p ${VENVDIR}
pyvenv ${VENVDIR}/${NAME}
source ${VENVDIR}/${NAME}/bin/activate
pip install wheel
if [ -f requirements.txt ]; then
    pip install -r requirements.txt
fi
# TODO handle requirements better, e.g. assume there is a tester subdir and take them from there
# TODO create links to tester files, e.g. assume there is a tester subdir and link them
