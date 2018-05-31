#!/usr/bin/env bash

# Install MarkUs autotesting server
MARKUS_ROOT=~/Markus
AUTOTEST_ROOT=~/markus-autotesting

echo "- - - Cloning the markus-autotesting repo - - -"
# TODO: revert these changes
git clone https://github.com/mishaschwartz/markus-autotesting.git ${AUTOTEST_ROOT} || exit 1
cd ${AUTOTEST_ROOT}
git checkout queue-rewrite

echo "- - - Setting up the autotester - - -"
# Note: autotester install.sh requires Python 3.5+
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
./install.sh server/config.py || exit 1
