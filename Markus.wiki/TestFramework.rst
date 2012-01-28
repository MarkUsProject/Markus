================================================================================
Test Framework
================================================================================

Definition
================================================================================
The Test Framework is a system in MarkUs allowing the automatic testing of students' code.


How does it work ?
================================================================================
Check these blog articles :

* http://blog.markusproject.org/?p=1561
* http://blog.markusproject.org/?p=1634
* http://blog.markusproject.org/?p=2198

Can I use it ?
================================================================================
The Test Framework is still in alpha. Use it at your own risks!

How can I use it ?
================================================================================
The Test Framework is not yet in the stable release of MarkUs. You will have to
use the master branch of the code on GitHub to be able to test it.

As a SysAdmin of MarkUs instance
--------------------------------------------------------------------------------
You will need **Ant**. Install *ant* and *ant-contrib* packages on Debian/Ubuntu
distributions. 

In particular, if you have errors about a *for task not found*, it is because
Ant has difficulties with ant-contrib.  This could be a result of not using a high enough version.

As an Administrator
--------------------------------------------------------------------------------
The administrator can define tests to be private or public. Public tests
results will be available to Students. Private tests results won't be. Both
private and public tests results will be available for Graders and
Administrator.


.. figure:: images/Test_Framework-01.png
   :width: 1280px
   :height: 1024px
   :scale: 100%
   :align: center
   :alt: Default Test Framework configuration page

   Default Test Framework configuration page

.. figure:: images/Test_Framework-02.png
   :width: 1280px
   :height: 1024px
   :scale: 100%
   :align: center
   :alt: Test Framework configuration page once completed

   Test Framework configuration page once completed

Student access to the test framework is controlled using test tokens.  
A student or group can run tests as many times as they have tokens.
On the test framework configuration page, the administrator can decide 
how many tokens to allocate to each student/group.  Currently tokens
refresh every day, but very soon it will be possible for an administrator to
choose how often to refresh tokens (daily, hourly or never).

As a Grader
--------------------------------------------------------------------------------
A Grader can run tests as many times as they want. Results will
show up on the grading page.  If tests don't run properly, 
graders have access to the test logs to determine problems,
but do not have the ability to correct **Ant** files. 

.. figure:: images/Test_Framework-07.png
   :width: 1280px
   :height: 703px
   :scale: 100%
   :align: center
   :alt: Grader View

   The Grader has the same tool to run the tests.

.. figure:: images/Test_Framework-08.png
   :width: 1280px
   :height: 703px
   :scale: 100%
   :align: center
   :alt: Grader View

   The Grader can see the result of the tests in a modal window

Graders will have to report to the Admin if tests do not run.

As a Student
--------------------------------------------------------------------------------
As mentioned above, the Student is assigned tokens for running tests. 
Tokens are reset every day by default, though this will easily be
changeable. If a group or student has remaining tokens, they 
do not carry over to the new day. 

.. figure:: images/Test_Framework-03.png
   :width: 1280px
   :height: 586px
   :scale: 100%
   :align: center
   :alt: Test frame is not available if the group is not valid

   Test frame is not available if the group is not valid

.. figure:: images/Test_Framework-04.png
   :width: 1276px
   :height: 735px
   :scale: 100%
   :align: center
   :alt: Test frame is available once the group is valid

   Test frame is available once the group is valid

.. figure:: images/Test_Framework-05.png
   :width: 1280px
   :height: 703px
   :scale: 100%
   :align: center
   :alt: Test Frame

   The student can see the revision used for the tests.
   The student can click to see the results of the public tests.

.. figure:: images/Test_Framework-06.png
   :width: 1280px
   :height: 703px
   :scale: 100%
   :align: center
   :alt: Test Frame

   The student has access to the history of all test runs.


Writting a build.xml
================================================================================

You can find some useful ressources here : http://www.markusproject.org/dev/ant_files.zip

Ant uses a file called build.xml to construct the project. It is this file
that will describe all tasks that Ant will run when running tests.

There is also a file called build.properties where we put some variable
definitions. 

MarkUs will create a folder where it will put students' files :

:: 
  
  automated_tests/group_0001/A1/
                             |
                             |-build/
                             |
                             |-lib/
                             |
                             |-parse/
                             |
                             |-reports/
                             |
                             |-src/
                             |
                             |-test/
                             |
                             |-api.txt
                             |
                             |-api_helper.py
                             |
                             |-api_helper.rb
                             |
                             |-build.properties
                             |
                             |-build.xml


MarkUs will put student's files in src. MarkUs will put test files given by the
Administrator in test. It will also pul librairies given by the Administrator
in lib.

api_helper.py and api_helper.rb are two identical scripts used by Ant to return
test results to MarkUs.  api.txt contains the user api key. It allows api_helper to
communicate with MarkUs.

Java
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
build.xml
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
build.properties
--------------------------------------------------------------------------------

:: 

  #build.properties
  #Here you can add some properties for your project

  src.dir = src
  build.dir = build
  test.dir = test

  reports.dir = reports

  api_key.file = api.txt

Usage of the API Key
================================================================================
