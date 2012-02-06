================================================================================
Setting up a development environment for MarkUs development on GNU/Linux
================================================================================

**Please note the difference between $> and #>. The $ means execute the command
as simple user, the # means execute the command as the super-user or use sudo
as normal user (#> is equivalent to $> sudo)**

If your system complains about gems not found when trying to run, for example,
`bundle install`, it is because you don't have the path of the binary in your
PATH variable. Find the path of the gem (usually `/var/lib/gems/1.8/bin/`) and
add it to your $PATH.

Setting up Git
--------------------------------------------------------------------------------

Git is the Source Content Management used by MarkUs. You can find some
documentation on GitHub. You will also have to set-up a GitHub account. [[How
to set-up Git on GNU/Linux|http://help.github.com/linux-set-up-git]]

Setting up Ruby, Ruby on Rails, Subversion and the Subversion Ruby bindings
--------------------------------------------------------------------------------

Issue the following command on a terminal. You need to be root or use "sudo"
(the Ubuntu way) to do that. Both methods are correct. Use only one of the
following methods :

(as root)::

    $> su  # and then enter your root password
    #> apt-get install ruby-full build-essential rubygems rake libsvn-ruby
    subversion #make sure ruby-full points to the correct ruby version (1.8)

(as normal user, with the "sudo" method)::

    $> sudo apt-get install ruby-full build-essential rubygems rake libsvn-ruby
    subversion # and then enter your root password, make sure ruby-full points to the correct ruby version (1.8)

**Note : You can either use PostgreSQL or MySQL or SQLite3 as database**

SQLite3 is easier to install, but should only used in development, not in
production. You may also experience database conflicts, in particular if you
want to test **PDF Conversion**. In case of PDF Conversion, you **MUST** use
PostgreSQL or MySQL

Installing ImageMagick
--------------------------------------------------------------------------------

If you need to use test and work on image and PDF annotation, you will need
ImageMagick. Otherwise, you can skip this part.

* [[Setting up ImageMagick|ImageMagick]]

If your want to test PDF conversion on MarkUs, don't forget to set to true the
`PDF_SUPPORT` variable in `config/environments/development.rb`


Setting up the Database
--------------------------------------------------------------------------------

Once you have decided what database best suits you :

* [[Setting up the Database (SQLite)|SettingUpSQLite]]
* [[Setting up the Database (MySQL)|SettingUpMySQL]]
* [[Setting up the Database (PostgreSQL)|SettingUpPostgreSQL]]


Required gems for MarkUs
--------------------------------------------------------------------------------

First, you will need rubygems (previously installed)

To ensure you have the good version of rubygems, please do::

    $> gem --version

if your version of rubygems is < 1.3.6, please update it !

This section assumes, you have gem version >= 1.3.6 (required for rails version
> 2.3.7).

So, the list of gems required for MarkUs is as follows:

* rails
* db_populate
* i18n
* mongrel_cluster
* routing-filter
* rake
* mongrel
* fastercsv
* will_paginate
* rubyzip
* ya2yaml

specific gems for databases:

* pg
* mysql
* sqlite3-ruby, sqlite3

specific gems for tests and development:

* shoulda
* selenium-client
* machinist
* faker
* factory_data_preloader
* time-warp
* ruby-debug
* mocha

and a gem to manage them all:

* bundler

Note that ruby-postgres is unmaintained and does not compile against
postgresql-8.3+. Therefore, do **not** install it. Instead, install pg
which works just fine. 

We are now using bundler to manage all gems. Install only bundler as a gem and 
bundler will install all other Gems.

To install the **all** gems, go in the project folder, and execute the following::

    #> gem install bundler
    $> bundle install

If you get the error "Could not locate Gemfile", it means you are not in the
correct folder.

Please note that bundler may ask you for your root password.

Bundle allows also some selective installation. To install only sqlite3
support, execute the following::

    $> bundle install --without postgresql mysql

To install only postgresql support support, execute the following::

    $> bundle install --without sqlite mysql

To install only mysql support, execute the following::

    $> bundle install --without postgresql sqlite

On Ubuntu and Debian systems, the system can't find bundler. You need to add
bundler to your PATH or run it directly ::

    $> /var/lib/gems/1.8/bin/bundle install

If you get a message saying "Missing these required gems", then it is likely
that some new gems have been integrated into Markus development and also need
to be installed using ``bundle install`` as described above.

Now, check that everything worked fine. Do the following on a terminal (as an
ordinary user, **not** root)::

    $> irb
    irb(main):001:0> require 'rubygems'
    => true
    irb(main):003:0> require 'fastercsv'
    => true
    irb(main):003:0> require 'ruby-debug'
    => true


The "true" output indicates that everything went fine and you are ready to go
to the next step. Also, <code>rake --version</code> should report a version >=
0.8.7 and <code>rails --version</code> should report a rails version >= 2.2.x

You can also run the following to check your gems::

    $> bundle exec gem list --local
    *** LOCAL GEMS ***

    actionmailer (2.3.10)
    actionpack (2.3.10)
    activerecord (2.3.10)
    activeresource (2.3.10)
    activesupport (2.3.10)
    bundler (1.0.12)
    cgi_multipart_eof_fix (2.5.0)
    columnize (0.3.2)
    daemons (1.1.0)
    db_populate (0.2.6)
    factory_data_preloader (0.5.2)
    faker (0.9.4)
    fastercsv (1.5.4)
    fastthread (1.0.7)
    gem_plugin (0.2.3)
    i18n (0.5.0)
    linecache (0.43)
    machinist (1.0.6)
    mocha (0.9.10)
    mongrel (1.1.5)
    mongrel_cluster (1.0.5)
    rack (1.1.0)
    rails (2.3.10)
    rake (0.8.7)
    routing-filter (0.2.2)
    ruby-debug (0.10.4)
    ruby-debug-base (0.10.4)
    rubyzip (0.9.4)
    selenium-client (1.2.18)
    shoulda (2.11.3)
    sqlite3 (1.3.3)
    sqlite3-ruby (1.3.3)
    time-warp (1.0.7)
    will_paginate (2.3.15)
    ya2yaml (0.30

Configure MarkUs
--------------------------------------------------------------------------------

Precondition: You have the MarkUs source-code checked out and do not plan to
use RadRails (see the following sections if you _plan_ to use RadRails for
development).

Read through all settings in environment.rb

Look at config/environments/development.rb

* Change the REPOSITORY_STORAGE path to an appropriate path for your setup. NOTE: it is unlikely that you need to change these values for development

Test plain MarkUs installation
--------------------------------------------------------------------------------

If you followed the above installation instructions in order, you should have
a working MarkUs installation (in terms of required software and required
configuration). But first you would need to create the development database,
load relations into it and populate the db with some data. You can do so by
the following series of commands (as non-root user, assuming you are in the
application-root of the MarkUs source code;)(please adapt the following
command)::

    # gets gems that you do not have yet, like thoughtbot-shoulda 
    $> bundle install  --without (postgresql) (sqlite) (mysql)
    $> bundle exec rake db:create:all        # creates all the databases uncommented in config/database.yml
    $> bundle exec rake db:schema:load   # loads required relations into database
    $> bundle exec rake db:populate      # populates database with some data
    $> bundle exec rake db:test:prepare
    $> bundle exec rake test:units
    $> bundle exec rake test:functionals

Note: if you are using RVM, follow [[these instuctions|RVM]] to install subversion into the correct path

Now, you are ready to test your plain MarkUs installation. The most straight
forward way to do this is to start the mongrel server on the command-line. You
can do so by::

    $> bundle exec rails server  #boots up mongrel (or WebRink, if mongrel is not installed/found)

If this doesn't work try::
    $> rails s

**Common Problems**

If some of the previous commands fail with error message similar to
``LoadError: no such file to load -- \<some-ruby-gem\>``, try to install the
missing Ruby gem by issuing ``gem install \<missing-ruby-gem\>`` and retry the
step which failed.

If everything above went fine: Congratulations! You have a working MarkUs
installation. Go to http://0.0.0.0:3000/ and enjoy MarkUs!

However, since you are a MarkUs developer, this is only _half_ of the game.
You also **need** (yes, this is not optional!) _some_ sort of IDE for MarkUs
development. For instance, the next section describes how to install RadRails
IDE, an Eclipse based Rails development environment. If you plan to use
something _else_ for MarkUs development, such as JEdit (with some tweaks) or
VIM, you should now start configuring them.

But if you _do_ plan to use RadRails for development, you should get rid of
some left-overs from previous steps, so that the following instructions run as
smoothly as possible for you. This is what you'd need to do (If you know what
you are doing, you might find this silly. But this guide tries to give
detailed instructions for Rails newcomers)::

    $> bundle exec rake db:drop          # get rid of the database, created previously (it'll be recreated again later)
    $> rm -rf markus_trunk   # get rid of the MarkUs source code possibly checked out previously (you might do a "cd .." prior to that)

**Happy Coding!**
