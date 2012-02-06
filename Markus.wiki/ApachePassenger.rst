================================================================================
Configuration of Apache with Phusion Passenger
================================================================================

Passenger is not interesting when you are in development mode. It is only
useful for production.::
 
  sudo aptitude install libapache2-mod-passenger
  sudo passenger-install-apache2-module

Eventually passenger-install-apache2-module will tell you to copy & paste some
settings into the Apache configuration file; something that looks along the
lines of: ::

  LoadModule passenger_module ...
  PassengerRoot ...
  PassengerRuby ...

A typical Virtual Host on Apache2 and Passenger : ::

  <VirtualHost *:80>
    ServerName markus.ec-nantes.fr 
    DocumentRoot /home/markus/markus/public
    <Directory /home/markus/markus/public>
        Allow from all
        Options -MultiViews
    </Directory>
  </VirtualHost>

Much more simple than the one with Mongrel :D

**Be Careful** : There is a bug with Rake and Rails. Passenger use the
production environment given with MarkUs. If you have issues loading the schema
in the database, just give the same database name to the production and the
development environments (in config/databases.yml)
