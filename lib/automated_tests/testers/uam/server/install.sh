#!/usr/bin/env bash

if [ $# -ne 1 ]; then
	echo usage: $0 install_dir
	exit 1
fi

INSTALLDIR=$1
UAMDIR=uam
cd ${INSTALLDIR}
if cd ${UAMDIR}; then
	git pull
	cd ..
else
	git clone https://github.com/ProjectAT/uam.git ${UAMDIR}
fi
