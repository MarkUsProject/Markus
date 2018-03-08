source /etc/profile.d/rvm.sh
echo "- - - Setup step 1 of 23 - - -"
rvm install 2.4.0
echo "- - - Setup step 2 of 23 - - -"
rvm --default use 2.4.0

# Update package manager
echo "- - - Setup step 3 of 23 - - -"
sudo apt-get update
echo "- - - Setup step 4 of 23 - - -"
sudo apt-get -y upgrade

# Change time zone
echo "- - - Setup step 5 of 23 - - -"
sudo rm -f /etc/localtime
echo "- - - Setup step 6 of 23 - - -"
sudo ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime

# Install dependencies
echo "- - - Setup step 7 of 23 - - -"
sudo apt-get install -y build-essential libv8-dev imagemagick libmagickwand-dev redis-server cmake libssh2-1-dev ghostscript libaprutil1-dev swig

# Git installation.
echo "- - - Setup step 8 of 23 - - -"
sudo apt-get install -y git

# Install postgres
echo "- - - Setup step 9 of 23 - - -"
sudo apt-get install -y postgresql postgresql-client postgresql-contrib libpq-dev

# Install node
echo "- - - Setup step 10 of 23 - - -"
curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
echo "- - - Setup step 11 of 23 - - -"
sudo apt-get install -y nodejs

# Install yarn
echo "- - - Setup step 12 of 23 - - -"
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "- - - Setup step 13 of 23 - - -"
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
echo "- - - Setup step 14 of 23 - - -"
sudo apt-get install -y yarn

# Project-specific dependencies now
echo "- - - Setup step 15 of 23 - - -"
# Likely not needed to use sudo, this is a quick-fix.
gem install bundler
echo "- - - Setup step 16 of 23 - - -"
bundle config libv8 -- --with-system-v8
echo "- - - Setup step 17 of 23 - - -"
bundle install --without mysql

# Add webpacker
echo "- - - Setup step 18 of 23 - - -"
yarn add @rails/webpacker
# TODO: Is this really necessary?
echo "- - - Setup step 19 of 23 - - -"
cp node_modules/@rails/webpacker/lib/install/config/webpacker.yml config

# TODO: change to `rails webpacker:install` when rails5 upgrade is done.
echo "- - - Setup step 20 of 23 - - -"
bundle exec rake webpacker:install

# Clone the Markus repository.
echo "- - - Setup step 21 of 23 - - -"
git clone https://github.com/MarkUsProject/Markus.git

# Install dependencies
echo "- - - Setup step 22 of 23 - - -"
cd Markus
echo "- - - Setup step 23 of 23 - - -"
bundle install
