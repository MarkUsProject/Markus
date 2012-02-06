================================================================================
Configuration of Apache with Mongrel
================================================================================
Configure the MarkUs application in
\<MarkUs-APP-Root\>/config/environments/production.rb (see our MarkUs
[configuration documentation](wiki:InstallProd#Configure) below). **Note:**
Please change the "secret" in the cookies related configuration section in
config/environment.rb of your MarkUs instance (see
<http://api.rubyonrails.org/classes/ActionController/Session/CookieStore.html>)

Configure the mongrel cluster (see config/mongrel_cluster.yml) and start the
mongrel servers::

    mongrel_rails cluster::start   # uses config settings defined in config/mongrel_cluster.yml

The ``mongrel_cluster`` gem isn't really necessary. It is a nice utility for starting/stopping mongrels for your MarkUs app, though.
For more information concerning mongrel clusters see: [http://mongrel.rubyforge.org/wiki/MongrelCluster](http://mongrel.rubyforge.org/wiki/MongrelCluster).

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
