# Setup the postgres database.
sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'postgres';"
sudo -u postgres psql -U postgres -d postgres -c "create role markus createdb login password 'markus';"

# Editing postgres configuration file needed to setup the database.
cd ../../../etc/postgresql/9.3/main
sudo sed -i 's/local   all             all                                     peer/local   all             all         md5/g' pg_hba.conf

# Restarting the postgres server after changing the database.
cd ../../../
sudo init.d/postgresql restart

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
rake db:setup
