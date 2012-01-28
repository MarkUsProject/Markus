================================================================================
Drop and Rebuild Database
================================================================================

It's not too difficult to have OLM populate with a bunch of students,
assignments, ta's, etc, while you're testing.

Sometimes, it's nice to just drop it all, and start fresh, with a few users,
and a few assignments.

Here's how you can do it quickly, and easily.

First, drop to the command line, and change directories to the root of your
local OLM copy.

Next, type in the following to reset your database::

    $> bundle exec rake db:reset

This will drop the database, recreate it, and load the latest version of the
schema that was in db/schema.rb.  Finally, you can (optionally) populate the
database with some quick and dirty records to get you going::

    $> bundle exec rake db:populate

Check out the Ruby scripts in db/populate - these are what rake db:populate is
running.
