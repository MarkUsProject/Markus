#!/usr/bin/env bash

# Install MarkUs autotesting server
MARKUS_ROOT=~/Markus
AUTOTEST_ROOT=~/markus-autotesting

echo "- - - Cloning the markus-autotesting repo - - -"
git clone https://github.com/MarkUsProject/markus-autotesting.git ${AUTOTEST_ROOT} || exit 1
cd ${AUTOTEST_ROOT}

echo "- - - Setting up the autotester - - -"
OLD_GEMFILE=${BUNDLE_GEMFILE}
export BUNDLE_GEMFILE=$(readlink -f ./server/Gemfile)

yes "" | ./install.sh "$(dirname ${MARKUS_ROOT})/autotest" -t 'tester' || exit 1

export BUNDLE_GEMFILE=${OLD_GEMFILE}
