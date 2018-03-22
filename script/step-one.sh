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
