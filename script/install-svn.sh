#!/usr/bin/env bash

# This file is currently not used but should be kept to install
# svn on travis in case we want to test interactions with svn
# in the future.
# This file may also be used to install the svn ruby bindings on
# a vagrant machine if we are using the non-default version of ruby

SVN_BASE=subversion-1.9.3  # Pinned to version in libsvn1.
MIRROR_PRIMARY=http://archive.apache.org/dist/subversion
MIRROR_SECONDARY=http://www-eu.apache.org/dist/subversion
SQLITE_BASE=sqlite-amalgamation-3290000

echo "- - - Installing subversion dependencies - - -"
sudo apt-get install -y libaprutil1-dev libutf8proc-dev liblz4-dev swig subversion libsvn1 unzip

echo "- - - Downloading subversion and sqlite source - - -"
if ! wget --tries 5 ${MIRROR_PRIMARY}/${SVN_BASE}.tar.gz; then
  if ! wget --tries 5 ${MIRROR_SECONDARY}/${SVN_BASE}.tar.gz; then
    exit 1
  fi
fi
tar xzf ${SVN_BASE}.tar.gz
wget https://www.sqlite.org/2019/${SQLITE_BASE}.zip
unzip ${SQLITE_BASE}.zip
mv ${SQLITE_BASE} ${SVN_BASE}/sqlite-amalgamation

cd $SVN_BASE

echo "- - - ./configure - - -"
./configure
echo "- - - make swig-rb - - -"
make swig-rb
echo "- - - make install-swig-rb - - -"
sudo make install-swig-rb

# Fix the installation.
# TODO: figure out how to fix this properly in ./configure.
sudo cp -r /usr/local/lib/site_ruby/usr/local/lib/x86_64-linux-gnu/site_ruby/svn /usr/lib/ruby/vendor_ruby/2.5.0
sudo cp /usr/local/lib/libsvn* /usr/lib/x86_64-linux-gnu
cd ..
