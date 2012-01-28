================================================================================
MarkUs Version > 0.9 Deployment Documentation (A System Administrator's Guide)
================================================================================

How to Install MarkUs
================================================================================

**Note: This documentation is made for System Administrators. We expect some
technical background from people using this documentation. All commands won't
be fully described here. If you need tips and help, you can look at [[the
GNU/Linux documentation for developers|InstallationGnuLinux]] or [[the MacOSX
documentation for developers|InstallationMacOsX]]**

.. TODO: Update Documentation for Bundler
.. TODO: Add svn webdav explanation
.. TODO: Add different authentication mechanisms (see InstallProdOld.rst)
.. TODO: Add externaly created repositories documentation
.. TODO: Don't forget to add a part for setting timezone !
.. TODO: ImageMagick
.. TODO: Ant
.. TODO: Libsvn-ruby

Required Software (including known to be working versions)
--------------------------------------------------------------------------------

We know that the following versions work and believe that whatever version
"gem" provides by issuing "gem install package" should also work.

* Ruby 1.8.7 including development package (e.g. ruby-dev) (see 'ruby-full'
  Debian package)
* net/https Ruby library ('libopenssl-ruby' Debian package)
* Gem (>= 1.3.7)
* PostgreSQL including libpq-dev (>= 8.2, but any PostgreSQL version should
  work; We also know that MarkUs works with MySQL)
* Apache httpd (1.3/2.x) (including mod_proxy, mod_rewrite, Subversion server
  modules if using Subversion as a backend) Note: Any other Webserver with
  similar features should also work.
* 'build-essential' Debian package (required to build/compile some gem packages
  from source)
* 'subversion' and 'libsvn-ruby1.8' (Ruby bindings for Subversion) if using an
  SVN Repository as back-end
* ImageMagick (>=6.5.7, older versions should be fine too) Only required if you
  plan to be able to view and annotate pdfs within the browser (PDF_SUPPORT
  setting in config files) 
* Ant (any recent version) if you plan to use the Test Framework (still in
  alpha) Don't forget to embed all tools you would need to complete your test
  toolchain (like gcc, make,…)

Issue the following command on a terminal.::

    #> aptitude install ruby-full build-essential rubygems rake libsvn-ruby
    subversion imagemagick ruby-dev libopenssl-ruby ant

Install Bundler, a gem for managing gems. ::

    #> gem install bundler

**NOTE** Apache installation will not be described here. Only configuration
will be.

**NOTE** In Production, you MUST either use PostgreSQL or MySQL databases. NOT
SQLite3

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

* [[Setting up the Database (MySQL)|SettingUpMySQL]]
* [[Setting up the Database (PostgreSQL)|SettingUpPostgreSQL]]


Get MarkUs
--------------------------------------------------------------------------------

[[Get latest stable release |
http://www.markusproject.org/download/markus-latest-stable.tar.gz]]

Extract it and setup all gems with bundler.::

    $> bundle install


Setting up the Rack Server
--------------------------------------------------------------------------------

Once you have decided what rack server best suits you :

* [[Setting up Apache with Mongrel|ApacheMongrel]]
* [[Setting up Apache with Passenger|ApachePassenger]]

Configuring Requirements
--------------------------------------------------------------------------------
  
Run the following rake tasks (non-root)::

    bundle exec rake db:create                # creates the "production" database according to database.yml
    bundle exec rake db:schema:load           # creates the necessary database schema relations

Create an "instructor" user for the person responsible for the course::

    bundle exec rake markus:instructor first_name='Markus' last_name='Maximilian' user_name='markus'

Optionally, load some default data into the database (The database can be
reset using ``rake db:reset``)::

    bundle exec rake db:populate

Configure the MarkUs application in
\<MarkUs-APP-Root\>/config/environments/production.rb (see our MarkUs
configuration documentation below). 

**Note:** Please change the "secret" in the cookies related configuration
section in config/environment.rb of your MarkUs instance (see 
[[ Rails API for cookies | http://api.rubyonrails.org/classes/ActionController/Session/CookieStore.html]])

Configure the mongrel cluster (see config/mongrel_cluster.yml) and start the
mongrel servers::

    mongrel_rails cluster::start   # uses config settings defined in config/mongrel_cluster.yml

The ``mongrel_cluster`` gem isn't really necessary. It is a nice utility for starting/stopping mongrels for your MarkUs app, though.
For more information concerning mongrel clusters see: [[http://mongrel.rubyforge.org/wiki/MongrelCluster | http://mongrel.rubyforge.org/wiki/MongrelCluster]].

Configure an httpd VirtualHost similar to the following (Reverse-Proxy-Setup)::

     RewriteEngine On

     # define proxy balancer
     <Proxy balancer://mongrel_cluster>
         BalancerMember http://127.0.0.1:8000 retry=10
         BalancerMember http://127.0.0.1:8001 retry=10
         BalancerMember http://127.0.0.1:8002 retry=10
     </Proxy>


     DocumentRoot /opt/markus/\<MarkUs-APP-Root\>/public
     <Directory />
         Options FollowSymLinks
         AllowOverride None
     </Directory>
     <Directory /opt/markus/\<MarkUs-APP-Root\>/public>
         Options Indexes FollowSymLinks MultiViews
         AllowOverride None
         Order allow,deny
         allow from all
     </Directory>
     RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
     RewriteRule ^/(.*)$ balancer://mongrel_cluster%{REQUEST_URI} [P,QSA,L]

See Also:
--------------------------------------------------------------------------------

* [[How to host several MarkUs applications on a single server | MultipleHosting]]
* [[Example Apache httpd virtual host configuration file | http://www.markusproject.org/dev/markus_httpd_vhost.conf]]
* You might find it worthwhile skimming through one or more of our [[development environment setup instructions | InstallationGnuLinux ]]
* See available rake tasks for MarkUs: ``rake -T``
* Our current [[INSTALL | http://www.markusproject.org/INSTALL]] file

------------------------

MarkUs Configuration Options
================================================================================

Timezone
--------------------------------------------------------------------------------
Every Ruby on Rails application needs to have its timezone set correctly.

As MarkUs uses deadlines, it is needed to have a correct timezone.

The timezone is set in `config/environment.rb`::

    config.time_zone = 'Eastern Time (US & Canada)'

Or, for France::

    config.time_zone = 'Paris'

All timezone availables for RoR applications can be found using the rake command::

    bundle exec rake time:zones:all

or::

    bundle exec rake time:zones:local




The main application-wide configuration file for MarkUs is::

    <app-root>/config/environments/production.rb

What follows is an example of 'production.rb'::

    # Settings specified here will take precedence over those in config/environment.rb

    # The production environment is meant for finished, "live" apps.
    # Code is not reloaded between requests
    config.cache_classes = true # set this to false, if you want automatic reload of changed code

    # Log error messages when you accidentally call methods on nil.
    config.whiny_nils = true

    # Use a different logger for distributed setups
    # config.logger = SyslogLogger.new
    #
    config.log_level = :info	# set log-level (:debug, :info, :warn, :error, :fatal)

    # Full error reports are disabled and caching is turned on
    config.action_controller.consider_all_requests_local = true # set to false to turn off traces
    config.action_view.debug_rjs			     = true
    config.action_controller.perform_caching             = true
    config.action_view.cache_template_loading            = true

    # Use a different cache store in production
    # config.cache_store = :mem_cache_store # place where to put cached files is configured in config/environment.rb
    config.action_controller.allow_forgery_protection    = true

    # Enable serving of images, stylesheets, and javascripts from an asset server
    # config.action_controller.asset_host                  = "http://assets.example.com"

    # Disable delivery errors, bad email addresses will be ignored
    config.action_mailer.raise_delivery_errors = false

    # Required gems for development (we are passing :lib => false,
    # because we don't want them to be loaded just yet)
    # Install them by using "rake gems:install"
    config.gem 'fastercsv', :lib => false
    config.gem 'will_paginate', :lib => false

    ###################################################################
    # MarkUs SPECIFIC CONFIGURATION
    #   - use "/" as path separator no matter what OS server is running
    ###################################################################

    ###################################################################
    # Set the course name here
    COURSE_NAME         = "CSC108 Fall 2009: Introduction to Computer Programming"

    ###################################################################
    # MarkUs relies on external user authentication: An external script
    # (ideally a small C program) is called with username and password
    # piped to stdin of that program (first line is username, second line
    # is password). 
    #
    # If and only if it exits with a return code of 0, the username/password
    # combination is considered valid and the user is authenticated. Moreover,
    # the user is authorized, if it exists as a user in MarkUs.
    #
    # That is why MarkUs does not allow usernames/passwords which contain
    # \n or \0. These are the only restrictions.
    VALIDATE_FILE = "#{RAILS_ROOT}/config/dummy_validate.sh"

    ###################################################################
    # File storage (Repository) settings
    ###################################################################
    # Options for Repository_type are 'svn' and 'memory' for now
    # 'memory' is by design not persistent and only used for testing MarkUs
    REPOSITORY_TYPE = "svn" # use Subversion as storage backend

    ###################################################################
    # Directory where Repositories will be created. Make sure MarkUs is allowed
    # to write to this directory
    REPOSITORY_STORAGE = "/home/markus/svn-repos-root"

    ###################################################################
    # Change this to 'REPOSITORY_EXTERNAL_SUBMITS_ONLY = true' if you
    # are using Subversion as a storage backend and the instructor wants his/her
    # students to submit to repositories via Subversion clients only. Set this
    # to true if you intend to make students submit via a Subversion
    # client only. This disables submissions through MarkUs' Web interface
    REPOSITORY_EXTERNAL_SUBMITS_ONLY = false

    ###################################################################
    # This config setting only makes sense, if you are using
    # 'REPOSITORY_EXTERNAL_SUBMITS_ONLY = true'. If you have Apache httpd
    # configured so that the repositories created by MarkUs will be available to
    # the outside world, this is the URL which internally "points" to the
    # REPOSITORY_STORAGE directory configured earlier. Hence, Subversion
    # repositories will be available to students for example via URL
    # http://www.example.com/markus/svn/Repository_Name. Make sure the path
    # after the hostname matches your <Location> directive in your Apache
    # httpd configuration
    REPOSITORY_EXTERNAL_BASE_URL = "http://www.example.com/markus/svn"

    ###################################################################
    # This setting is important for two scenarios:
    # First, if MarkUs should use Subversion repositories created by a
    # third party, point it to the place where it will find the Subversion
    # authz file. In that case, MarkUs would need at least read access to
    # that file.
    # Second, if MarkUs is configured with REPOSITORY_EXTERNAL_SUBMITS_ONLY
    # set to 'true', you can configure as to where MarkUs should write the
    # Subversion authz file.
    REPOSITORY_PERMISSION_FILE = REPOSITORY_STORAGE + "/svn_authz"

    ###################################################################
    # This setting configures if MarkUs is reading Subversion
    # repositories' permissions only OR is admin of the Subversion
    # repositories. In the latter case, it will write to
    # REPOSITORY_SVN_AUTHZ_FILE, otherwise it doesn't. Change this to
    # 'false' if repositories are created by a third party. 
    IS_REPOSITORY_ADMIN = true

    ###################################################################
    # Session Timeouts
    ###################################################################
    USER_STUDENT_SESSION_TIMEOUT        = 1800 # Timeout for student users
    USER_TA_SESSION_TIMEOUT             = 1800 # Timeout for grader users
    USER_ADMIN_SESSION_TIMEOUT          = 1800 # Timeout for admin users

    ###################################################################
    # CSV upload order of fields (usually you don't want to change this)
    ###################################################################
    # Order of student CSV uploads
    USER_STUDENT_CSV_UPLOAD_ORDER = [:user_name, :last_name, :first_name]
    # Order of graders CSV uploads
    USER_TA_CSV_UPLOAD_ORDER  = [:user_name, :last_name, :first_name]

    ###################################################################
    # Logging Options
    ###################################################################
    # If set to true then the rotation of the logfiles will be defined
    # by MARKUS_LOGGING_ROTATE_INTERVAL instead of the size of the file
    MARKUS_LOGGING_ROTATE_BY_INTERVAL = false
    # Set the maximum size file that the logfiles will have before rotating
    MARKUS_LOGGING_SIZE_THRESHOLD = 1024000000
    # Sets the interval which rotations will occur if
    # MARKUS_LOGGING_ROTATE_BY_INTERVAL is set to true,
    # possible values are: 'daily', 'weekly', 'monthly'
    MARKUS_LOGGING_ROTATE_INTERVAL = 'daily'
    # Name of the logfile that will carry information, debugging and
    # warning messages
    MARKUS_LOGGING_LOGFILE = "log/info_#{RAILS_ENV}.log"
    # Name of the logfile that will carry error and fatal messages
    MARKUS_LOGGING_ERRORLOGFILE = "log/error_#{RAILS_ENV}.log"
    # This variable sets the number of old log files that will be kept
    MARKUS_LOGGING_OLDFILES = 10

    ###################################################################
    # END OF MarkUs SPECIFIC CONFIGURATION
    ###################################################################
------------------------------

Allow Subversion Client Commits
================================================================================

When using Subversion as a storage backend for students' submissions, MarkUs is
capable of exposing created Subversion repositories. Example: An instructor
configures an assignment so that students can submit using a Subversion client
directly (i.e. the MarkUs Web interface will not allow submissions). In that
case, the Subversion repositories will be created once the student logs in.
Hence, the workflow is as follows:

1. The instructor creates users and (at least one) assignment
2. The instructor tells students to log in to MarkUs and find out their repository's Subversion URL
3. Students checkout/submit to their repositories using a Subversion client

**Requirements**

In order to be able to use this feature, one requires a working
[[ Subversion/Apache configuration as documented in the Subversion
book | http://svnbook.red-bean.com/en/1.5/svn.serverconfig.httpd.html ]]. We
assume that user authentication is handled by Apache httpd (whatever
authentication scheme one chooses). Once a username (the identical
username/user-id as defined in MarkUs) has been authenticated by the httpd,
authorization (i.e. checking read/write permissions) is handled by Subversion.
MarkUs writes appropriate Subversion configuration files when users and/or
groups are determined.

**Minimal Subversion/Apache httpd configuration**

A minimal Apache httpd configuration (sippet of httpd.conf) would look similar
to the following::

    LoadModule dav_module
    LoadModule dav_svn_module
    LoadModule authz_svn_module   # we are using per-directory based access control

    # make sure you have a ServerName or ServerAlias directive matching your
    # hostname MarkUs is hosted on (uncomment the following line)
    # ServerAlias your_hostname

    # Make sure that the path after the hostname of
    # REPOSITORY_EXTERNAL_BASE_URL matches the path of your
    # Location directive
    <Location /markus/svn>
      DAV svn

      # any "/markus/svn/foo" URL will map to a repository /home/svn-repos-root/foo
      # This should usually be identical to the REPOSITORY_STORAGE constant in
      # config/environment.rb of your markus app
      SVNParentPath /home/svn-repos-root 

      # configure your Apache httpd authentication scheme here
      # for example, one could use Basic authentication
      # how to authenticate a user
      Require valid-user
      AuthType Basic                  # the authentication scheme to be used
      AuthUserFile /path/to/users/file  

      # Arbitrary name: Should probably match your COURSE_NAME constant in
      # config/environment.rb
      AuthName "Your Course Name"

      # Location of Subversions authz file. Make sure it matches with
      # $REPOSITORY_SVN_AUTHZ_FILE in your config/environment.rb
      AuthzSVNAccessFile /path/to/authz/file
    </Location>

This enables you to let your students access repositories created by MarkUs
via the http:// uri scheme, once you have created an assignment and set up
Groups/Users appropriately in MarkUs.

Setting Up REMOTE_USER Support
--------------------------------------------------------------------------------

As of 0.9, MarkUs follows the CGI $REMOTE_USER standard. It relies on the
REMOTE_USER variable being passed as the X-Forwarded-User HTTP header.
Configuring Apache for REMOTE_USER support is simple, in your apache
configuration just add::

    # Read REMOTE_USER variable and set HTTP header so that it gets
    # passed on to Mongrel/Passenger
    RewriteCond %{LA-U:REMOTE_USER} (.+)
    RewriteRule . - [E=RU:%1]
    RequestHeader add X-Forwarded-User %{RU}e

Then set REMOTE_USER_AUTH to true in the config/environments/production.rb
file. You can also specify a custom page for the logout link to redirect to
via the LOGOUT_REDIRECT option in production.rb.

A 403 error page is rendered if MarkUs is configured to use REMOTE_USER but
the header is not set for some reason (e.g. the auth cookie of the central
authentication mechanism has expired and, hence, REMOTE_USER would not be
set). In that case, you can use Apache's httpd ErrorHandler to redirect to a
login page of your choosing.

Use Externally Created Subversion Repositories with MarkUs
================================================================================

If you already have Subversion repositories created by some third-party, it is
possible to use them with MarkUs. 

**Instructions**

1. Set ``IS_REPOSITORY_ADMIN = false`` in environment.rb
2. Point MarkUs to the correct path where your repositories reside by setting
REPOSITORY_STORAGE in environment.rb correctly (of course you would also use
``REPOSITORY_TYPE = "svn"``)
2. Prepare a csv file adhering to the following field order:
``group_name,repo_name,user_name,user_name``> (Note: the repo_name field is important here, since this is the link with your third-party tool)
3. Use this file to upload groups for your course (go to Assignment => Groups & Graders => Upload/Download)
4. This configures MarkUs to use externally created repositories. **Please note:** MarkUs won't write any permissions related files in this kind of setup. The third party tool is in charge of that. 

