#!/usr/bin/env bash

# Change time zone
echo "- - - Changing Time Zone, Step 1 - - -"
sudo rm -f /etc/localtime
echo "- - - Changing Time Zone, Step 2 - - -"
sudo ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime

# Clone the Markus repository.
echo "- - - Cloning Markus - - -"
git clone https://github.com/MarkUsProject/Markus.git

echo "- - - Switch to Markus - - -"
cd Markus

echo "- - - Installing Ruby 2.5.1, Step 1 - - -"
source /etc/profile.d/rvm.sh
echo "- - - Installing Ruby 2.5.1, Step 2 - - -"
rvm install 2.5.1 --disable-binary
echo "- - - Installing Ruby 2.5.1, Step 3 - - -"
rvm --default use 2.5.1

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
bundle exec rake db:setup

# Update .bashrc and .profile
echo "- - - Update .bashrc - - -"
cat >> /home/vagrant/.bashrc <<EOL
cd /home/vagrant/Markus
EOL
echo "- - - Update .profile - - -"
cat >> /home/vagrant/.profile <<EOL
PATH=$PATH:/home/vagrant/Markus/bin
EOL
