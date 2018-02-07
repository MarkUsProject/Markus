# Install rvm.
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -sSL https://get.rvm.io | bash -s stable --ruby
rvm install ruby-2.4.0
rvm --default use 2.4.0

# Update package manager
sudo apt-get update
sudo apt-get upgrade

# Change time zone
sudo rm -f /etc/localtime
sudo ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime

# Install dependencies
sudo apt-get install -y build-essential libv8-dev imagemagick libmagickwand-dev redis-server cmake libssh2-1-dev ghostscript libaprutil1-dev swig

# Git clone the repository
sudo apt-get install -y git
git clone https://github.com/MarkUsProject/Markus.git
cd Markus

# Install rvm
sudo apt-add-repository -y ppa:rael-gc/rvm
sudo apt-get install -y rvm
source ~/.rvm/scripts/rvm

# Installing ruby 2.5 causes issues with nokogiri 1.8.1 which requires the version to be before 2.5.
# rvm get stable
# rvm install 2.5
# rvm use 2.5 --default

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
