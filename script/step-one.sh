# This is where RVM is initially installed.
echo "- - - Pre-setup step 1 of 10 - - -"
sudo apt-get install software-properties-common
echo "- - - Pre-setup step 2 of 10 - - -"
sudo apt-add-repository -y ppa:rael-gc/rvm
echo "- - - Pre-setup step 3 of 10 - - -"
sudo apt-get update
echo "- - - Pre-setup step 4 of 10 - - -"
sudo apt-get -y install rvm
echo "- - - Pre-setup step 5 of 10 - - -"
source /etc/profile.d/rvm.sh

# This is where the permissions with RVM are fixed.
echo "- - - Pre-setup step 6 of 10 - - -"
command curl -sSL https://rvm.io/mpapis.asc | sudo gpg --import -
echo "- - - Pre-setup step 7 of 10 - - -"
rvmsudo rvm get stable --auto-dotfiles
echo "- - - Pre-setup step 8 of 10 - - -"
rvm reload
echo "- - - Pre-setup step 9 of 10 - - -"
rvm fix-permissions system
echo "- - - Pre-setup step 10 of 10 - - -"
rvm group add rvm $USER
