#!/usr/bin/env bash

# Install MarkUs autotesting server
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 markus-autotesting-root-dir"
else
  AUTOTEST_ROOT=$(readlink -f "$1")
fi

echo "- - - Cloning the markus-autotesting repo - - -"
git clone https://github.com/MarkUsProject/markus-autotesting.git ${AUTOTEST_ROOT} || exit 1
cd ${AUTOTEST_ROOT}

echo "- - - Setting up the autotester - - -"
# Note: autotester install.sh requires Python 3.7
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
yes | server/bin/install.sh

# Note: install jdbc jar
JAVA_JAR_PATH=${AUTOTEST_ROOT}/testers/testers/jdbc/bin/
wget -P ${JAVA_JAR_PATH} https://jdbc.postgresql.org/download/postgresql-42.2.5.jar

# install all testers

yes | ${AUTOTEST_ROOT}/testers/testers/custom/bin/install.sh
yes | ${AUTOTEST_ROOT}/testers/testers/haskell/bin/install.sh
yes | ${AUTOTEST_ROOT}/testers/testers/java/bin/install.sh
yes | ${AUTOTEST_ROOT}/testers/testers/py/bin/install.sh
yes | ${AUTOTEST_ROOT}/testers/testers/pyta/bin/install.sh
yes | ${AUTOTEST_ROOT}/testers/testers/racket/bin/install.sh
#yes | ${AUTOTEST_ROOT}/testers/testers/sql/bin/install.sh  #TODO: install after the autotester is ready
#yes | ${AUTOTEST_ROOT}/testers/testers/jdbc/bin/install.sh "${JAVA_JAR_PATH}/postgresql-42.2.5.jar"
