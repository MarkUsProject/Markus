#!/usr/bin/env bash
# Update package manager
echo "- - - Updating Package Manager, Step 1 - - -"
sudo apt-get update
echo "- - - Updating Package Manager, Step 2 - - -"
# See https://github.com/chef/bento/issues/661 for details on this command.
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

# Install dependencies
echo "- - - Installing Dependencies - - -"
sudo apt-get install -y build-essential libv8-dev imagemagick libmagickwand-dev redis-server cmake libssh2-1-dev ghostscript libaprutil1-dev swig graphviz

# Install Ruby
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:brightbox/ruby-ng
sudo apt-get update
sudo apt-get install ruby2.5 ruby2.5-dev -y
sudo update-alternatives --config ruby
sudo update-alternatives --config gem
sudo gem install bundler

# Install git
echo "- - - Installing Git - - -"
sudo apt-get install -y git

# Install postgres
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

# Change time zone
echo "- - - Changing Time Zone, Step 1 - - -"
sudo rm -f /etc/localtime
echo "- - - Changing Time Zone, Step 2 - - -"
sudo ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime

# MarkUs installation
MARKUS_ROOT=~/Markus

# Clone the Markus repository.
echo "- - - Cloning Markus - - -"
git clone https://github.com/MarkUsProject/Markus.git $MARKUS_ROOT
cd $MARKUS_ROOT

# Project-specific dependencies now
echo "- - - Installing Project-specific Dependencies, Step 1 - - -"
bundle config libv8 -- --with-system-v8
bundle config github.https true
echo "- - - Installing Project-specific Dependencies, Step 2 - - -"
bundle install --without mysql sqlite unicorn --path vendor/bundle

echo "- - - Install JavaScript dependencies - - -"
yarn install

# Setup the postgres database.
echo "- - - Setup Postgres Database, Step 1 - - -"
sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'postgres';"
echo "- - - Setup Postgres Database, Step 2 - - -"
sudo -u postgres psql -U postgres -d postgres -c "create role markus createdb login password 'markus';"

# Editing postgres configuration file needed to setup the database.
echo "- - - Edit Postgres Configuration, Step 1 - - -"
cd ../../../etc/postgresql/9.5/main
echo "- - - Edit Postgres Configuration, Step 2 - - -"
sudo sed -i 's/local   all             all                                     peer/local   all             all         md5/g' pg_hba.conf

# Restarting the postgres server after changing the database.
echo "- - - Restart Postgres Database, Step 1 - - -"
cd ../../../
echo "- - - Restart Postgres Database, Step 2 - - -"
sudo init.d/postgresql restart

# Switching back to the Markus folder.
echo "- - - Switching to Markus Folder - - -"
cd $MARKUS_ROOT

# Copy the new database file.
echo "- - - Copy Postgres Database File - - -"
cp config/database.yml.postgresql config/database.yml

# Setup the database.
echo "- - - Setup Database - - -"
bundle exec rails db:setup

# Update .bashrc and .profile
echo "- - - Update .bashrc - - -"
cat >> /home/vagrant/.bashrc <<EOL
cd /home/vagrant/Markus
EOL
echo "- - - Update .profile - - -"
cat >> /home/vagrant/.profile << 'EOL'
export PATH="${PATH}:/home/vagrant/Markus/bin"
export HOST="0.0.0.0"

EOL
