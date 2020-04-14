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
# See https://github.com/chef/bento/issues/661 for details on this command.
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
# Note: autotester install.sh requires Python 3.7
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install build-essential openssl
yes | server/bin/install.sh

# Note: install jdbc jar
JAVA_JAR_PATH=${AUTOTEST_ROOT}/testers/testers/java/bin/
wget -P ${JAVA_JAR_PATH} https://jdbc.postgresql.org/download/postgresql-42.2.5.jar

# install all testers

yes | ${AUTOTEST_ROOT}/testers/testers/custom/bin/install.sh
yes | ${AUTOTEST_ROOT}/testers/testers/haskell/bin/install.sh
yes | ${AUTOTEST_ROOT}/testers/testers/java/bin/install.sh
yes | ${AUTOTEST_ROOT}/testers/testers/py/bin/install.sh
yes | ${AUTOTEST_ROOT}/testers/testers/pyta/bin/install.sh
yes | ${AUTOTEST_ROOT}/testers/testers/racket/bin/install.sh
