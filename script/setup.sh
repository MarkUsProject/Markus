# Install node
curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn

# Add webpacker
yarn add @rails/webpacker
# TODO: Is this really necessary?
cp node_modules/@rails/webpacker/lib/install/config/webpacker.yml config

# TODO: change to `rails webpacker:install` when rails5 upgrade is done.
bundle exec rake webpacker:install
bundle exec rake webpacker:install:react
