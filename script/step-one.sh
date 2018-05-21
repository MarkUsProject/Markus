#!/usr/bin/env bash
# Update package manager
echo "- - - Updating Package Manager, Step 1 - - -"
sudo apt-get update
echo "- - - Updating Package Manager, Step 2 - - -"
sudo apt-get -y upgrade

# Install dependencies
echo "- - - Installing Dependencies - - -"
sudo apt-get install -y build-essential libv8-dev imagemagick libmagickwand-dev redis-server cmake libssh2-1-dev ghostscript libaprutil1-dev swig

# Git installation.
echo "- - - Installing Git - - -"
sudo apt-get install -y git

# Install postgres (note: on 16.04+, can install postgres through the standard repository)
echo "- - - Installing Postgres - - -"
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" >> /etc/apt/source s.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y postgresql-9.5 postgresql-client-9.5 postgresql-contrib-9.5 libpq-dev

# Install node
echo "- - - Installing Node, Step 1 - - -"
curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
echo "- - - Installing Node, Step 2 - - -"
sudo apt-get install -y nodejs

# Install yarn
echo "- - - Installing Yarn, Step 1 - - -"
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "- - - Installing Yarn, Step 2 - - -"
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
echo "- - - Installing Yarn, Step 3 - - -"
sudo apt-get update && sudo apt-get install -y yarn


# This is where RVM is initially installed.
echo "- - - Installing RVM, Step 1 - - -"
sudo apt-add-repository -y ppa:rael-gc/rvm
echo "- - - Installing RVM, Step 2 - - -"
sudo apt-get update
echo "- - - Installing RVM, Step 3 - - -"
sudo apt-get -y install rvm
echo "- - - Installing RVM, Step 4 - - -"
source /etc/profile.d/rvm.sh

# This is where the permissions with RVM are fixed.
echo "- - - Fixing RVM Installation, Step 1 - - -"
command curl -sSL https://rvm.io/mpapis.asc | sudo gpg --import -
echo "- - - Fixing RVM Installation, Step 2 - - -"
rvmsudo rvm get stable --auto-dotfiles
echo "- - - Fixing RVM Installation, Step 3 - - -"
rvm reload
echo "- - - Fixing RVM Installation, Step 4 - - -"
rvm fix-permissions system
echo "- - - Fixing RVM Installation, Step 5 - - -"
rvm group add rvm $USER
