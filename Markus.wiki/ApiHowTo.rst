================================================================================
Introduction to the MarkUs API
================================================================================

This document is still a **draft**. Details as to how to use the API and might
change in future.

MarkUs Versions > 0.7: Steps to Get Your Token for Authentication
--------------------------------------------------------------------------------

 1. Log on to MarkUs as admin/TA
 2. Use API key/token as is

MarkUs Versions <= 0.7: Steps to Produce a Token for Authentication
--------------------------------------------------------------------------------

 1. Get your key by loggin on to MarkUs (API token/key).
 2. Use this key to generate a MD5 sum digest (32 character string length). On
    Linux systems the *md5sum* utility could be used.
 3. Then encode the resulting hash from step two using the Base 64 encoding.
    Again, there's a Linux tool which does this for you. It's called *base64*.
    Example:<pre> $ echo -n 'your-key-here' | md5sum | cut -f1 -d' ' |
    base64</pre>
 4. Finally, use the Base 64 encoded token to construct a HTTP header of the
    form:
    ``<pre>Authorization: MarkUsAuth
    \<your-Base64-encoded-MD5-hash-here\></pre>``:w


Then, for example, you could use **curl** to send requests to the MarkUs
server. An example for sending a request to the MarkUs API looks like this::

    $ file_content=`cat app/controllers/assignments_controller.rb`; curl --header 'Authorization: MarkUsAuth NmY3NGUxNjEyY2FlNzk0NTMwMmQ5YTY1YTE1NzNhZmY=' \
      -F group_name=c5anthei -F assignment=A1 -F filename=test.txt -F "file_content=$file_content" http://example.com/markus/api/test_results

RESTful Resources
================================================================================

Resources available via the MarkUs API conform to Rails' RESTful routes.
Basically, one has to distinguish between the following HTTP request types and
according operations:

1. **Create:** Issue a HTTP POST request to the resource in question with
   required parameters
2. **Update:** Issue a HTTP PUT request to the resource in question with
   required parameters
2. **Destroy:** Issue a HTTP DELETE request to the resource in question with
   required parameters
2. **Show:** Issue a HTTP GET request to the resource in question with required
   parameters

MarkUs API Specifics
================================================================================

As of now, the only available resources via the MarkUs API are test results.
Apart from the above actions (see section RESTful Resources), filenames of
test results per submission have to be unique. Several HTTP POST requests with
the same filename, but different file_content parameter, will overwrite
already existing test results.

Rake Tasks
================================================================================

In case of stolen authentication tokens, API keys can be globally reset by the
system administrator using the *markus:reset_api_key* rake task. Example::

    $ cd path/to/markus/app
    $ bundle exec rake markus:reset_api_key

Loading Test Results into MarkUs
================================================================================

A typical request in order to load test results into MarkUs looks like the
following (using curl)::

    $ file_content=`cat app/controllers/assignments_controller.rb`; curl --header 'Authorization: MarkUsAuth NmY3NGUxNjEyY2FlNzk0NTMwMmQ5YTY1YTE1NzNhZmY=' \
      -F group_name=c5anthei -F assignment=A1 -F filename=test.txt -F "file_content=$file_content" http://example.com/markus/api/test_results

**NOTE** This only works, if for the specified assignment and group a
submission has been "collected". This usually happens after the assignment due
date and after the grace period.

**IMPORTANT** The current implementation of
test results, does not allow binary files to be pushed into MarkUs. The
behaviour of submitting binary test results this way is undefined.

The test_results URL (e.g. http://example.com/markus/api/test_results) follows
REST-like semantics. I.e. in order to update a test result, use a PUT request.
In order to delete a test result, use a DELETE request.

**Note:** MarkUs versions > 0.7 ship with a Python (api_helper.py) and Ruby
(api_helper.rb) script in lib/tools/ which may be of some help for generating
those requests.

What follows is a list of parameters required for each request:

|Request Type| Effect| Parameters| Comments |
|POST| Creates/updates test result| group_name, filename, file_content, assignment| Use short identifier of assignment as value for the assignment parameter.|
|PUT| Updates a test result's content (nothing else)| group_name, filename, file_content, assignment| |
|DELETE| Deletes a test result| group_name, filename, assignment| |
|GET| Renders the test result content of the specified filename| group_name, filename, assignment| |
