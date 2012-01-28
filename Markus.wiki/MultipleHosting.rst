================================================================================
Hosting Multiple MarkUs-App Instances on a Server
================================================================================

Say, one wants to host a Markus application per course offered by the CS
department. Each single application instance would share the same application
code (by facilitating symbolic links) and uses its own configuration (hence,
database), log files and tmp directory. The architecture might be as follows.
Apache acts as a reverse-proxy and establishes the connection the the locally
listening mongrel clusters depending on the requested URL: ::

  apache (or any other reverse proxy)
    |
    |
    `-> mongrel_cluster1: ports 8000-8002
    |-> mongrel_cluster2: ports 8003-8005
    \-> mongrel_cluster3: ports 8006-8008


Each mongrel cluster would serve the MarkUs application for one course. Say we
would want to host the MarkUs apps on machine 'master.example.com'. The
URI-scheme could then look like so: ::

  http://master.example.com/markus/csc108/  # MarkUs for course 108
  http://master.example.com/markus/csc209/  # MarkUs for course 209
  http://master.example.com/markus/csc148/  # MarkUs for course 148

and so on.

One application will provide the "main" MarkUs application. All subsequent
applications will use their own copy of configuration files, tmp and log
directories with the rest of the application "symlinked" to the "main" MarkUs
application. Next we assume the following directory structure for the "main"
MarkUs app: ::

  <path-to-main-markus-app>/
     app                  # application code
     config               # application configuration
     db                   # db-setup files
     doc
     lib                  # ruby/rails libraries
     log                  # directory where logging information goes
     public               # public files (might be configured as DocumentRoot when using Apache httpd)
     script               # rails utility scripts
     test                 # application tests
     tmp                  # pid-files, session-files, other temporary data
     vendor               # rails plugins, vendor code, etc.

These are the directories typically present for a Rails application. The public
directory should be accessible by the Webserver. For information as to how to
set up the "main" application, see the [deployment notes](wiki:InstallProd)

MarkUs applications running in parallel to the "main" application do not
require their own copy of the Rails application code. In fact, they require
their own copy of the following directories only: ::

  <path-to-additional-markus-app>/
    config               # copy
    log                  # copy
    script               # copy
    tmp                  # copy

All other files and directories should be symlinked to the "main" MarkUs
application. Hence the structure would look as follows: ::

  <path-to-additional-markus-app>/
    app                  # symlink
    config               # copy
    db                   # symlink
    doc                  # symlink
    lib                  # symlink
    log                  # copy
    public               # symlink (not necessary actually, Webserver can be configured to serve those files from the main olm app)
    script               # copy
    test                 # symlink
    tmp                  # copy
    vendor               # symlink

Make sure the "tmp" directory of your "slim" MarkUs application contains a
directory "pids". This is the place where mongrel places its PID files.

Edit the configurations for your second application. In particular make sure
that you use a different database name in config/database.yml and make your
course specific changes in config/environment.rb. Pay particular attention to
the following lines: ::

  # ignore URL prefix specified below
  config.action_controller.relative_url_root = "/somepath"

The above line should say: ::

  # ignore URL prefix specified below
  config.action_controller.relative_url_root = "/markus/csc108"  # "main" app

Moreover, change the session cookie name of each MarkUs instance to a more specific name. Snippet: ::

  config.action_controller.session = {
    :session_key => '_markus_session_csc108'

If the application is accessible by the URL
"http://master.example.com/markus/csc108/". Also, change
config/mongrel_cluster.yml so that the ports on which the mongrel servers are
listening for this application do not overlap with any other configured MarkUs
app. For the "main" application in our example the file would look like so: ::

  log_file: log/mongrel.log
  port: "8000"
  environment: production
  pid_file: tmp/pids/mongrel.pid
  servers: 3

and for the additional MarkUs app as follows: ::

  log_file: log/mongrel.log
  port: "8003"
  environment: production
  pid_file: tmp/pids/mongrel.pid
  servers: 3

Hence, the main application would listen on ports 8000-8002 on localhost, the
additional application on ports 8003-8005 on localhost. Finally we need to tell
the Webserver, what requests to pass on to what MarkUs application (what
port-range). An exemplary Apache httpd config snipped would look as follows: ::

  # mod_proxy (incl. mod_proxy_balancer required)
  # Define proxy balancer(s); One per course
  <Proxy balancer://mongrel_cluster_csc108>
     BalancerMember http://127.0.0.1:8000 retry=10
     BalancerMember http://127.0.0.1:8001 retry=10
     BalancerMember http://127.0.0.1:8002 retry=10
  </Proxy>
  <Proxy balancer://mongrel_cluster_csc209>
    BalancerMember http://127.0.0.1:8003 retry=10
    BalancerMember http://127.0.0.1:8004 retry=10
    BalancerMember http://127.0.0.1:8005 retry=10
  </Proxy>

  DocumentRoot /opt/markus-apps/markus-main/public
  <Directory />
    Options FollowSymLinks
    AllowOverride None
  </Directory>

  # Directory should match DocumentRoot
  <Directory /opt/markus-apps/markus-main/public>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Order allow,deny
    allow from all
  </Directory>
  # Images, Stylesheets, JavaScripts and error pages amongst others are served by Apache
  RewriteRule ^/markus/(?:csc108|csc209)/(404.html|500.html|422.html|favicon.ico|blank_iframe.html)$ /$1 [R=301,L]
  RewriteRule ^/markus/(?:csc108|csc209)/((?:stylesheets|images|javascripts)/.*)$ /$1 [R=301,L]
  # If requested files are not found in DocumentRoot, pass them on to the mongrels
  RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
  RewriteRule ^/(markus/csc108.*)$ balancer://mongrel_cluster_csc108/$1 [P,QSA,L]
  RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
  RewriteRule ^/(markus/csc209.*)$ balancer://mongrel_cluster_csc209/$1 [P,QSA,L]

Starting/Stopping of mongrel-clusters is documented in the [[deployment
notes|InstallProdStable]].
