#!/usr/bin/env bash

MARKUS_ROOT=${TRAVIS_BUILD_DIR}
BRANCH=$(grep -Po 'VERSION=\K[^,]+' "${MARKUS_ROOT}/app/MARKUS_VERSION")

cd ${MARKUS_ROOT}/..

echo "- - - Cloning the markus-autotesting repo - - -"
git clone https://github.com/MarkUsProject/markus-autotesting.git || exit 1
cd markus-autotesting
git checkout ${BRANCH}

echo "- - - Setting up the autotester - - -"
OLD_GEMFILE=${BUNDLE_GEMFILE}
export BUNDLE_GEMFILE=$(readlink -f ./server/Gemfile)

yes "" | ./install.sh "$(dirname ${MARKUS_ROOT})/autotest" -t 'tester' || exit 1

export BUNDLE_GEMFILE=${OLD_GEMFILE}

echo "- - - Starting resque worker on the markus side - - -"
cd ${MARKUS_ROOT}
TERM_CHILD=1 BACKGROUND=yes QUEUES=CSC108_autotest_run bundle exec rake environment resque:work || exit 1
