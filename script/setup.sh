echo "- - - Installing RVM - - -"
sudo apt-get install software-properties-common
sudo apt-add-repository -y ppa:rael-gc/rvm
sudo apt-get update
sudo apt-get -y install rvm
source /etc/profile.d/rvm.sh

echo "- - - Fixing RVM Permissions - - -"
command curl -sSL https://rvm.io/mpapis.asc | sudo gpg --import -
rvmsudo rvm get stable --auto-dotfiles
rvm reload
rvm fix-permissions system
rvm group add rvm $USER

echo "- - - Installing Ruby Using RVM - - -"
rvm install 2.4.0
rvm --default use 2.4.0

# Update package manager
sudo apt-get update
sudo apt-get -y upgrade

# Change time zone
sudo rm -f /etc/localtime
sudo ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime

# Install dependencies
sudo apt-get install -y build-essential libv8-dev imagemagick libmagickwand-dev redis-server cmake libssh2-1-dev ghostscript libaprutil1-dev swig

# Git installation.
sudo apt-get install -y git

# Install postgres
sudo apt-get install -y postgresql postgresql-client postgresql-contrib libpq-dev

# Install node
curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get install -y yarn

# Project-specific dependencies now
gem install bundler
bundle config libv8 -- --with-system-v8
bundle install --without mysql

# Add webpacker
yarn add @rails/webpacker
# TODO: Is this really necessary?
cp node_modules/@rails/webpacker/lib/install/config/webpacker.yml config

# TODO: change to `rails webpacker:install` when rails5 upgrade is done.
bundle exec rake webpacker:install

# Clone the Markus repository.
git clone https://github.com/MarkUsProject/Markus.git

# Install dependencies
cd Markus
bundle install

# Setup the postgres database.
sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'postgres';"
sudo -u postgres psql -U postgres -d postgres -c "create role markus createdb login password 'markus';"

# Editing postgres configuration file needed to setup the database.
cd ../../../etc/postgresql/9.3/main
sudo sed -i 's/local   all             all                                     peer/local   all             all         md5/g' pg_hba.conf

# Restarting the postgres server after changing the database.
cd ../../../
init.d/postgresql restart

# Switching back to the Markus folder.
cd ../home/vagrant/Markus/

# Copy the new database file.
cp config/database.yml.postgresql config/database.yml

# Set the permissions so that the log file is writeable.
chmod 0664 log/development.log

# Switch the repository type to be git and not SVN.
cd Markus
sed -i "s/REPOSITORY_TYPE = 'svn'/REPOSITORY_TYPE = 'git'/g" config/environments/development.rb

# Setup the database.
rake db:seed
