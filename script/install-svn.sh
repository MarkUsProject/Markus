#!/usr/bin/env bash

SVN_BASE=subversion-1.9.7

echo "- - - Detecting Ruby version - - -"
source /etc/profile.d/rvm.sh
rvm use
RUBY_DIR=$(dirname $(dirname $(which ruby)))
echo $RUBY_DIR

echo "- - - Installing subversion dependencies - - -"
sudo apt-get install -y libaprutil1-dev swig

echo "- - - Downloading subversion and sqlite source - - -"
wget http://apache.parentingamerica.com/subversion/${SVN_BASE}.tar.gz
tar xzf ${SVN_BASE}.tar.gz
wget https://www.sqlite.org/sqlite-amalgamation-3071501.zip
unzip sqlite-amalgamation-3071501.zip
mv sqlite-amalgamation-3071501 ${SVN_BASE}/sqlite-amalgamation

cd $SVN_BASE

echo "- - - ./configure - - -"
LDFLAGS="-L$RUBY_DIR/lib/" ./configure --prefix=$RUBY_DIR

echo "- - - make - - -"
make
echo "- - - make swig-rb - - -"
make swig-rb
echo "- - - make install - - -"
make install
echo "- - - make install-swig-rb - - -"
make install-swig-rb

cd ..
