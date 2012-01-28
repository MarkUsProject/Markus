================================================================================
Setting up the Database (PostgreSQL)
================================================================================

Installing the Database
================================================================================

GNU/Linux
--------------------------------------------------------------------------------

On Debian and Ubuntu, a simple ::

   apt-get install postgresql postgresql-client

Mac OS X
--------------------------------------------------------------------------------

To install postgres 8.3, you can use the one-click installer on the following
site : [[Postgresql 8.3 One-Click Installer |
http://www.postgresql.org/download/macosx]]

You can also follow the instruction on this site : [[Postgresql 8.3 MacPorts
installation |
http://shifteleven.com/articles/2008/03/21/installing-postgresql-on-leopard-using-macports]]

Microsoft Windows
--------------------------------------------------------------------------------


Configuring PostgreSQL
================================================================================

Make sure that you have set an UTF-8 locale/encoding (e.g. set
LANG=en_CA.UTF-8 environment variable). The postgresql cluster will be created
in the encoding which is currently set. Type locale in the term and you should
see something similar to the following::

    $> locale
    LANG=en_CA.UTF-8
    LC_CTYPE="en_CA.UTF-8"
    LC_NUMERIC="en_CA.UTF-8"
    LC_TIME="en_CA.UTF-8"
    LC_COLLATE="en_CA.UTF-8"
    LC_MONETARY="en_CA.UTF-8"
    LC_MESSAGES="en_CA.UTF-8"
    LC_PAPER="en_CA.UTF-8"
    LC_NAME="en_CA.UTF-8"
    LC_ADDRESS="en_CA.UTF-8"
    LC_TELEPHONE="en_CA.UTF-8"
    LC_MEASUREMENT="en_CA.UTF-8"
    LC_IDENTIFICATION="en_CA.UTF-8"
    LC_ALL=


Then execute the following command on a terminal. You need to be root or use
"sudo" (the Ubuntu way) to do that::

    #> aptitude install postgresql postgresql-contrib

You also need the development package of PostreSQL. You can install the
package by executing the following command::

    #> apt-get install libpq-dev

**Creating a Database User and Changing Authentication Scheme**

For simplicity we create a database user "olm_db_admin" with the same
password, to which superuser privileges will be granted. We will use this user
for OLM later. As root execute the following (be careful not to forget any
backslashes or single-/doublequotes)::

    #> su -c "psql -c \"create user olm_db_admin with superuser password
    'olm_db_admin';\"" postgres

The above command should output the following::

    CREATE ROLE

However if you keep getting the following everytime you try to enter your
password::

    #> su -c "psql -c \"create user olm_db_admin with superuser password
    'olm_db_admin';\""
    postgres Password:
    su: Authentication failure

You can run the following instead::

    #>sudo su
    Password:
    #> su -c "psql -c \"create user olm_db_admin with superuser password
    'olm_db_admin';\"" postgres
    CREATE ROLE

Finally, we need to change a line in the configuration file of the PostgreSQL
database. As root open "pg_hba.conf" (sometimes "pg_hdb.conf") in
``/etc/postgres/\<pg-version\>/main/``  or in
``/etc/postgresql/\<pg-version\>/main/`` and look for the following lines (the
first one is actually only a comment)::

    # "local" is for Unix domain socket connections only
    local   all         all                               ident sameuser

Now change the second line like so::

    local   all         all                               md5

Restart PostgresSQL in order to apply those configuration changes to the
server (please adjust the version accordingly)::

    #> /etc/init.d/postgresql-8.3 restart

To test if everything went fine we try to connect to the "postgres" database
using our newly created user::

    #> psql postgres olm_db_admin

You will be asked for a password, so type "olm_db_admin". After that you
should see the console of PostgreSQL.

Install PostgreSQL (make sure that the created cluster is UTF-8 encoded; If not
required, it also works with latin-1)

Configuring MarkUs
--------------------------------------------------------------------------------

Setup the database.yml file, in the MarkUs' root directory:

* `cp config/database.yml.postgresql config/database.yml`

* change the usernames and password to the ones you used in the section above

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
