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
