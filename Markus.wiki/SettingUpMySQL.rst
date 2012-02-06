================================================================================
Setting up the Database (MySQL)
================================================================================

Installing the Database
================================================================================

GNU/Linux
--------------------------------------------------------------------------------

On Debian and Ubuntu, a simple ::

   apt-get install mysql libmysqlclient-dev
   apt-get install mysql-server

If you are not in admin-mode, then you will need to add ``sudo`` prefix.

Mac OS X
--------------------------------------------------------------------------------

To install MySQL, you can use the installer from this site: [[MySQL Downloads |
(http://dev.mysql.com/downloads/mysql/5.1.html#macosx-dmg]] You can also
install MySQL using MacPorts instead by following the instructions on this
site: [[MySQL 5 MacPorts installation |
http://www.freerobby.com/2009/09/01/installing-mysql-via-macports-on-snow-leopard-for-ruby-development/]]

After the installation is complete, you'll need to update your
`PATH` environment variable. If you installed MySQL via the
installer, add `/usr/local/mysql/bin` to your `PATH`. If
you installed MySQL via MacPorts, add `/opt/local/lib/mysql5/bin`
to your `PATH`. 

Microsoft Windows
--------------------------------------------------------------------------------


Configuring MySQL
================================================================================

Creating a database user
--------------------------------------------------------------------------------

To create a database user, enter the following commands: (In this example, the
user is named 'markus', his password is 'markus', and he will be given
superuser privileges. This user will be used for MarkUs later on.)::

    #>mysql --user=root --password=<my password> mysql
    #>CREATE USER 'markus'@'localhost' IDENTIFIED BY 'markus';
    #>GRANT ALL PRIVILEGES ON *.* TO 'markus'@'localhost' WITH GRANT OPTION;

You can now try connecting to the server using the user you just created::

    #>mysql --user=markus --password=markus

You should see the MySQL console.

Configuring MarkUs
--------------------------------------------------------------------------------

Setup the database.yml file, in the MarkUs' root directory:

* `cp config/database.yml.mysql config/database.yml`

* change the usernames and password to the ones you used in the section above

* uncomment the development and test sections of config/database.yml

Now go back to the MarkUs tutorial :

* Installation on GNU/Linux

  * [[Development environment|InstallationGnuLinux]]
  * [[Production environment|InstallProdStable]]
  * [[Old Stable (deprecated) environment|InstallProdOld]]

* Installation on Mac OS X

  * [[Development environment|InstallationMacOsX]]
  * Production (need to be done)

* Installation on Windows

  * [[Development environment|InstallationWindows]]
