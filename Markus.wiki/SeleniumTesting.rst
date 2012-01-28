================================================================================
How to run Selenium tests
================================================================================

.. TODO: Update this tutorial

First, install Java to be able to run the Selenium server (RC).

Second, install the selenium-client gem with this command::

    #>sudo gem install selenium-client

Since MarkUs is only fully compliant with Firefox, the Selenium tests will use this browser.

Selenium needs the MarkUs application to be running to run tests. Start the
application with this command::

    #> bundle exec ruby script/server -e test -p 3001

This will start MarkUs with the test environment on port 3001.

After that, run this rake task::

    #> bundle exec rake test:selenium RAILS_ENV=test

This will load the fixtures into the database, start the Selenium server, run
all the tests in the selenium folder and stop the server.

It is also possible to specify a file and method with these options::

    #> bundle exec rake test:selenium RAILS_ENV=test TEST=selenium/file_test.rb TESTOPTS="--name=method_name"

You can also start and stop the Selenium server manually with these commands::

    #> bundle exec rake selenium:rc:start
    #> bundle exec rake selenium:rc:stop

With the server started manually, run the tests with the following command::

    #> bundle exec rake test:selenium_with_server_started
