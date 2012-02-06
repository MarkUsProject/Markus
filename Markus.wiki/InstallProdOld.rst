================================================================================
MarkUs Version 0.5 Deployment Documentation (A System Administrator's Guide)
================================================================================

**Note:** Please notice that this documentation is not maintained anymore. Use
it as a guideline for buildind old versions of MarkUs.

**Supported version:** This documentation should cover all MarkUs version from
*0.5* to *0.8*.

How to Install MarkUs
================================================================================

For more detailed instructions, please see our INSTALL file.

Required Software (including known to be working versions)
================================================================================

We know that the following versions work and believe that whatever version
"gem" provides by issuing "gem install package" should also work.

* Ruby (>=1.8.7) including development package (e.g. ruby-dev)
* net/https Ruby library ('libopenssl-ruby' Debian package)
* Gem (>= 1.3.x) see [Update gem on Debian](wiki:UpdateRailsDebian)
    * rails (gem) (2.3.2)
    * daemons (gem) (1.0.10)
    * mongrel (gem) (1.1.5)
    * mongrel_cluster (gem) (1.0.5)
    * ruby-pg (gem) (>=0.7.9.2008.01.28)
    * postgres (gem) (>=0.7.9.2008.01.28)
    * fastercsv (gem) (>=1.4.0)
    * rake (gem) (0.8.7)
    * ruby-debug (gem)
* PostgreSQL including libpq-dev (>= 8.2, but any PostgreSQL version should
  work; We also know that MarkUs works with MySQL)
* Apache httpd (1.3/2.x) (including mod_proxy, mod_rewrite, Subversion server
  modules if using Subversion as a backend) Note: Any other Webserver with
  similar features should also work.
* 'build-essential' Debian package (required to build/compile some gem
  packages from source)
* 'subversion' and 'libsvn-ruby1.8' (Ruby bindings for Subversion) if using an
  SVN Repository as back-end

Installation Proceedings (using a PostgreSQL database) 
================================================================================

**NOTE:**  An important thing to have installed prior installing the Rails gems
is the libpq-dev package (i.e. development files for PostgreSQL).


Install PostgreSQL (make sure that the created cluster is UTF-8 encoded; If not
required, it also works with latin-1 and ) and Apache Httpd  
  
Update gem, so that a version >= 1.3.x is installed.

Install gem packages:  
--------------------------------------------------------------------------------

::

    sudo gem install rails daemons mongrel mongrel_cluster ruby-pg postgres
    fastercsv rake ruby-debug

Create an administrative database user and allow this user to connect using md5
passwords  
  
Take the MarkUs application and extract it to an appropriate location  
  
Set an environment variable `RAILS_ENV="production"`  
  
Change to the "root" of the MarkUs Rails application  
  
Set database connection settings accordingly in `config/database.yml` (see
`config/database.yml.postgresql` for a sample setup)  

If you are using a rails version >2.3.2, please uncomment the line featuring
"RAILS_GEM_VERSION = 2.3.2 unless defined? RAILS_GEM_VERSION" in
config/environment.rb
  
Run the following rake tasks (non-root): ::

    rake db:create                # creates the "production" database according to database.yml
    rake db:schema:load           # creates the necessary database schema relations

Create an "instructor" user for the person responsible for the course::

    rake markus:instructor first_name='Markus' last_name='Maximilian' user_name='markus'

Optionally, load some default data into the database (The database can be reset
using `rake db:reset`) ::

    rake db:populate

Configure the MarkUs application in config/environment.rb.

**Note:** Please pay particular attention to the "secret" in the cookies
related configuration section of your MarkUs instance (see
<http://api.rubyonrails.org/classes/ActionController/Session/CookieStore.html>)
  
Configure the mongrel cluster (see config/mongrel_cluster.yml) and start the mongrel servers:

:: 

    mongrel_rails cluster::start   # uses config settings defined in config/mongrel_cluster.yml

The `mongrel_cluster` gem isn't really necessary. It is a nice utility for
starting/stopping mongrels for your MarkUs app, though.  For more information
concerning mongrel clusters see:
http://mongrel.rubyforge.org/wiki/MongrelCluster.

Configure an httpd VirtualHost similar to the following (Reverse-Proxy-Setup)  

::

  RewriteEngine On

  # define proxy balancer
  <Proxy balancer://mongrel_cluster>
    BalancerMember http://127.0.0.1:8000 retry=10
    BalancerMember http://127.0.0.1:8001 retry=10
    BalancerMember http://127.0.0.1:8002 retry=10
  </Proxy>

  DocumentRoot /opt/olm/\<MarkUs-APP-Root\>/public

  <Directory />
    Options FollowSymLinks
    AllowOverride None
  </Directory>

  <Directory /opt/olm/\<MarkUs-APP-Root\>/public>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Order allow,deny
    allow from all
  </Directory>

  RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
  RewriteRule ^/(.*)$ balancer://mongrel_cluster%{REQUEST_URI} [P,QSA,L]


See Also: 
================================================================================
* [[Hosting several MarkUs applications on one machine (for Production)|MultipleHosting]]
* [[How to use LDAP with MarkUs|LDAP]]
* [[How to use Phusion Passenger instead of Mongrel|Passenger]]
* See available rake tasks for MarkUs: `rake -T`


MarkUs Configuration Options
================================================================================

The main application-wide configuration file for MarkUs is
`config/environment.rb`.

Allow Subversion Commandline Commits Only
================================================================================

When using Subversion as a storage backend for students' submissions, it is
capable of exposing created Subversion repositories. Example: An instructor
configures an assignment so that students can submit using the Subversion
command-line client only (i.e. the Web interface will be disabled). In that
case, the Subversion repositories will be created once the student logs in.
Hence, the workflow is as follows:

1. The instructor creates users and (at least one) assignment
2. The instructor tells students to log in to MarkUs and find out their
   repository URL
3. Students can connect to their repositories using svn

**Requirements**

In order to be able to use this feature, one requires a working
(Subversion/Apache configuration as documented in the Subversion
book: http://svnbook.red-bean.com/en/1.5/svn.serverconfig.httpd.html). We
assume that user authentication is handled by Apache httpd (whatever
authentication scheme one chooses). Once a username (the identical
username/user-id as defined in MarkUs) has been authenticated by the httpd,
authorization (i.e. checking read/write permissions) is handled by Subversion.
MarkUs writes appropriate Subversion configuration files when users and/or
groups are determined.

**Minimal Subversion/Apache httpd configuration**

A minimal Apache httpd configuration (sippet of httpd.conf) would look similar to the following:

::

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

This enables you to let your students access repositories created by MarkUs via
the http:// uri scheme, once you have created an assignment and set up
Groups/Users appropriately in MarkUs.

Use Externally Created Subversion Repositories with MarkUs
================================================================================

If you already have Subversion repositories created by some third-party, it is
possible to use them with MarkUs. 

**Instructions**

1. Set `IS_REPOSITORY_ADMIN = false` in environment.rb

2. Point MarkUs to the correct path where your repositories reside by setting
   REPOSITORY_STORAGE in environment.rb correctly (of course you would also use
   `REPOSITORY_TYPE = "svn"`)

3. Prepare a csv file adhering to the following field order:
   `group_name,repo_name,user_name,user_name` (Note: the repo_name
   field is important here, since this is the link with your third-party tool)

4. Use this file to upload groups for your course (go to Assignment => Groups &
   Graders => Upload/Download)

5. This configures MarkUs to use externally created repositories. **Please
   note:** MarkUs won't write any permissions related files in this kind of
   setup. The third party tool is in charge of that. 
