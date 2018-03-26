#!/usr/bin/env bash
echo "- - - Installing Ruby 2.5.0, Step 1 - - -"
source /etc/profile.d/rvm.sh
echo "- - - Installing Ruby 2.5.0, Step 2 - - -"
rvm install 2.5.0 --disable-binary
echo "- - - Installing Ruby 2.5.0, Step 3 - - -"
rvm --default use 2.5.0

# Update package manager
echo "- - - Updating Package Manager, Step 1 - - -"
sudo apt-get update
echo "- - - Updating Package Manager, Step 2 - - -"
sudo apt-get -y upgrade

# Change time zone
echo "- - - Changing Time Zone, Step 1 - - -"
sudo rm -f /etc/localtime
echo "- - - Changing Time Zone, Step 2 - - -"
sudo ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime

# Install dependencies
echo "- - - Installing Dependencies - - -"
sudo apt-get install -y build-essential libv8-dev imagemagick libmagickwand-dev redis-server cmake libssh2-1-dev ghostscript libaprutil1-dev swig

# Git installation.
echo "- - - Installing Git - - -"
sudo apt-get install -y git

# Install postgres
echo "- - - Installing Postgres - - -"
sudo apt-get install -y postgresql postgresql-client postgresql-contrib libpq-dev

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

# Clone the Markus repository.
echo "- - - Cloning Markus - - -"
git clone https://github.com/MarkUsProject/Markus.git

echo "- - - Switch to Markus - - -"
cd Markus

# Project-specific dependencies now
echo "- - - Installing Project-specific Dependencies, Step 1 - - -"
gem install bundler
echo "- - - Installing Project-specific Dependencies, Step 2 - - -"
bundle config libv8 -- --with-system-v8
bundle config github.https true
echo "- - - Installing Project-specific Dependencies, Step 3 - - -"
bundle install --without mysql

echo "- - - Install JavaScript dependencies - - -"
yarn install

# Setup the postgres database.
echo "- - - Setup Postgres Database, Step 1 - - -"
sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'postgres';"
echo "- - - Setup Postgres Database, Step 2 - - -"
sudo -u postgres psql -U postgres -d postgres -c "create role markus createdb login password 'markus';"

# Editing postgres configuration file needed to setup the database.
echo "- - - Edit Postgres Configuration, Step 1 - - -"
cd ../../../etc/postgresql/9.3/main
echo "- - - Edit Postgres Configuration, Step 2 - - -"
sudo sed -i 's/local   all             all                                     peer/local   all             all         md5/g' pg_hba.conf

# Restarting the postgres server after changing the database.
echo "- - - Restart Postgres Database, Step 1 - - -"
cd ../../../
echo "- - - Restart Postgres Database, Step 2 - - -"
sudo init.d/postgresql restart

# Switching back to the Markus folder.
echo "- - - Switching to Markus Folder - - -"
cd ../home/vagrant/Markus/

# Copy the new database file.
echo "- - - Copy Postgres Database File - - -"
cp config/database.yml.postgresql config/database.yml

echo "- - - Switch Repository Type - - -"
sed -i "s/REPOSITORY_TYPE = 'svn'/REPOSITORY_TYPE = 'git'/g" config/environments/development.rb

# Setup the database.
echo "- - - Setup Database via Rake - - -"
rake db:setup

# Update .bashrc and .profile
echo "- - - Update .bashrc - - -"
cat >> /home/vagrant/.bashrc <<EOL
cd /home/vagrant/Markus
EOL
echo "- - - Update .profile - - -"
cat >> /home/vagrant/.profile <<EOL
PATH=$PATH:/home/vagrant/Markus/bin
EOL
