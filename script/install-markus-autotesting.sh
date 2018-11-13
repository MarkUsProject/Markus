#!/usr/bin/env bash

# Install MarkUs autotesting server
if [ $# -ne 1 ]; then
  echo "Usage: $0 markus-autotesting-root-dir"
else
  AUTOTEST_ROOT="$1"
fi

echo "- - - Cloning the markus-autotesting repo - - -"
git clone https://github.com/MarkUsProject/markus-autotesting.git ${AUTOTEST_ROOT} || exit 1
cd ${AUTOTEST_ROOT}

echo "- - - Setting up the autotester - - -"
# Note: autotester install.sh requires Python 3.7
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
yes | ./install.sh || exit 1
