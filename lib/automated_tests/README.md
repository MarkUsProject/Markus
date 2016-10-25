Automated Testing Engine (ATE)
==============================

The Automated Testing Engine (ATE) allows instructors and tas to run tests on students submissions and automatically
create marks for them. It consists of a client component integrated into MarkUs, and a server component that can be
deployed together with MarkUs or standalone. Testing jobs are queued and served using a first in first out strategy,
managed by the gem Resque on the client and server side.

## 1. Requirements and Installation

The client requirements are already included in a MarkUs installation. If you are a MarkUs developer, you can skip the
requirements for the server.

The server requires `ruby`, `redis-server`, `bundler` and the gems listed in the Gemfile. Copy the 'server' directory to
the server machine, cd into it and run `bundle install --deployment` to install the gems.

## 2. Running ATE

Examples of architectures:

1) MarkUs development

   One Resque worker to serve client and server (this setup can be used in production too, but it is not recommended).

   `TERM_CHILD=1 QUEUES=* bundle exec rake environment resque:work`

2) MarkUs production with dedicated test server

   One Resque client worker and one dedicated Resque server worker, either on the same machine or on separate machines.

   client:  
   `ATE_FILES_QUEUE_NAME=name_in_config_options`  
   `RAILS_ENV=production TERM_CHILD=1 BACKGROUND=yes QUEUES=${ATE_FILES_QUEUE_NAME} bundle exec rake environment
   resque:work`  
   (The other Resque queues that MarkUs uses for background processing can be added to this command, namely
   `JOB_CREATE_INDIVIDUAL_GROUPS_QUEUE_NAME`, `JOB_COLLECT_SUBMISSIONS_QUEUE_NAME`,
   `JOB_UNCOLLECT_SUBMISSIONS_QUEUE_NAME`)

   server:  
   `ATE_TESTS_QUEUE_NAME=name_in_config_options`  
   `TERM_CHILD=1 BACKGROUND=yes QUEUES=${ATE_TESTS_QUEUE_NAME} bundle exec rake resque:work`

3) MarkUs production with shared test server

   N Resque client workers and one shared Resque server worker, either on the same machine or on separate machines.

   The commands are exactly the same as #2, with one caveat: each client runs a client command, where the queue names
   are different.

Check out Resque on GitHub to get an idea of all the possible queue configurations.

## 3. ATE Config Options

##### AUTOMATED_TESTING_ENGINE_ON
ATE can only be used when this is set to true.
##### ATE_EXPERIMENTAL_STUDENT_TESTS_ON
Allows the instructor to let students run tests periodically.
##### ATE_SERVER_HOST
The test server host. Use 'localhost' for a local server without authentication.
##### ATE_SERVER_FILES_USERNAME
The test server username used to copy the test files over + to run the Resque server worker.
SSH Login must be set up for this username to connect without a password from MarkUs.
Ignored if `ATE_SERVER_HOST` is 'localhost'.
##### ATE_SERVER_TESTS_USERNAME
The test server username used to run the tests.
Can be the same as `ATE_SERVER_FILES_USERNAME`, or `ATE_SERVER_FILES_USERNAME` must be able to sudo -u to it.
Ignored if `ATE_SERVER_HOST` is 'localhost'.
##### ATE_CLIENT_DIR
The directory on the client where test scripts are stored and student repos are temporarily exported.
The user running MarkUs must be able to write here.
##### ATE_SERVER_FILES_DIR
The directory on the test server where to copy test files. Multiple clients can use the same directory.
`ATE_SERVER_FILES_USERNAME` must be able to write here.
##### ATE_SERVER_TESTS_DIR
The directory on the test server where to run tests. Only one test at at time is executed to avoid interference.
Can be the same as `ATE_SERVER_FILES_DIR`.
`ATE_SERVER_FILES_USERNAME` and `ATE_SERVER_TESTS_USERNAME` must be able to write here.
##### ATE_SERVER_RESULTS_DIR
The directory on the test server where to log test results.
`ATE_SERVER_FILES_USERNAME` must be able to write here.
##### ATE_FILES_QUEUE_NAME
The name of the queue on the test client where submission files wait to be copied.
##### ATE_TESTS_QUEUE_NAME
The name of the queue on the test server where tests wait to be executed.

## 4. Test scripts output format

The test scripts the instructors upload and run on the test server must print the following output on stdout for each
test:

```
<test>
    <name>REQUIRED (STRING)</name>
    <input>OPTIONAL (STRING, NOT DISPLAYED YET)</input>
    <expected>OPTIONAL (STRING, NOT DISPLAYED YET)</expected>
    <actual>OPTIONAL (STRING, DISPLAYED AS OUTPUT)</actual>
    <marks_earned>REQUIRED (INTEGER)</marks_earned>
    <status>REQUIRED (ONE OF pass,fail,error)</status>
</test>
```
