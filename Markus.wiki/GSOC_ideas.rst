================================================================================
Google Summer of Code Ideas
================================================================================
MarkUs is a web application for grading programming assignments.  The main project page is http://markusproject.org.  There is a demo instance of MarkUs running there that you can play with.  Login with user id "a" and any non-empty password.

Here is the summary of all the ideas we have for GSoC.  We are also open to student-suggested projects.  Our user base is growing which means that the number of things people want to do with MarkUs is expanding as well!

.. contents::

Performance analysis 
================================================================================

As we begin to use MarkUs is classes larger than 500 students, we need to get a better picture of the performance limitations, and what we can do to mitigate them. If a large number of students try to submit their assignments using MarkUs in a short time window, where are the performance bottlenecks? Rails? The database? Subversion?

This project would involve setting up a test environment, profiling, and stress testing MarkUs. An applicant should have enough Linux knowledge to be able to set up concurrent tests and measure performance, and enough database knowledge to be able to do some profiling. Basic Ruby and Rails knowledge, web application knowledge would be a strong asset. (We realize this is a lot to ask, but for the right student, this could be a really rewarding project.)

Integrate Git, Bazaar and Mercurial into MarkUs
================================================================================

MarkUs can be configured either to allow students to submit code through a
web interface, or to provide students an svn repository. As DCVS
becomes more and more popular, students often use svn2X tools in order to
use DCVS, hosting the code on hosting platforms such as Github, Launchpad or
Bitbucket. The idea would be to create an interface for MarkUs to retrieve
the code to be graded automatically (students provide a URL to their clone of the repository).

Requirements for this project are good familiarity with at least one DCVS, and preferably some experience with Ruby to explore the library bindings.

Web based PDF annotations
================================================================================

MarkUs has a web-based PDF annotations module that uses ImageMagick (http://www.imagemagick.org) to convert a PDF file into an image, in order to be able to annotate it. There are several limitations to this approach: the PDF document is limited to 30pages, substantial processing time is required to perform the conversion, documents cannot easily be viewed in different sizes. This project is of an exploratory nature, to find a better solution to PDF annotations.



A VM harness for the automated test framework
================================================================================

We have been working towards an automated test framework that allows students to submit their work and receive immediate feedback. To run student submitted code on a server, we need to think carefully about how to do this securely. Running the tests inside a locked down VM seems to be the most promising solution. 

This project requires Linux and VM knowledge, preferably with some system administration skills.



Integrated Microsoft docx/Open Document Format Support
================================================================================

Convert Microsoft's docx or Open Document suite of formats (such as ODT,ODF and ODP) into a reasonable format which can be annotated. Suggested format conversions could be properly styled HTML, images, or plain text. For HTML and plain text conversion XSL-T stylesheets could be used to leverage XSL-T translation support of modern Web browsers.


MarkUs e-learning Platform Integration
================================================================================

E-learning platforms have become a keystone to educational environment. Free software-based platforms arise and are now widely used (at least in Europe). The major two software are Claroline and Moodle. For every course, it provides features like publishing documents w.r.t. courses, manage public and private forums, create groups of students, prepare online exercises, … The MarkUs tool nowadays appears as an additional tool to branch to the existing e-learning environment in many institutions, which could restrain its use. It would be useful, for both teachers and students, to be able to access to MarkUs features through the usual platform they use in their daily tasks. This will result in no differentiation between CS courses and other courses, meaning that everyone would be benefit from the annotation features provided by MarkUs. 

The idea of this proposal is to create a MarkUs plug-in for either Claroline or Moodle. Claroline has the advantage to be currently in use in École Centrale de Nantes (France) and in many french schools. This engineering school collaborates with École Centrale de Lyon, which is part of the consortium leading the Claroline development. 

[1] http://www.claroline.net/
[2] http://moodle.org/


Here are a few other projects that we would like to tackle but may not be as appealing to Summer of Code students.  However, if you want to propose one of these, please feel free! 

Mapping Graders to Groups
================================================================================

The feature in MarkUs that maps Graders to the groups that they are responsible for marking currently provides only very simple mapping functions. Professors can either assign graders randomly to groups, or can upload a specific mapping. We have had requests to implement more sophisticated mappings.  For example:

- Assign graders such that students previously graded by these graders are prioritized
- Assign graders such that students who haven't been graded by these graders so far are prioritized
- Assign graders to all students of a specific section
- Assign graders randomly to students of a specific section

This project will require Ruby and Rails skills. It will involve some interesting UI work, but should be a fairly straightforward project overall. A student who chooses this project will likely end up working on additional other small projects.

Migrating MarkUs to Rails 3
================================================================================

Ruby on Rails version 3 is the new major release of Ruby on Rails. MarkUs is now three years old and we would do good by migrating it to be Ruby on Rails 3 compatible. Work has already started (see branch 'rails_3_migration'). Moreover, Ruby on Rails 3 has been designed to work with Ruby 1.8.7 and 1.9.2. MarkUs currently uses Ruby on Rails 2.3.10 which works with Ruby 1.8.6.

The following issues have been determined so far due to Ruby on Rails 3 migration: MarkUs tests (units and functionals) will require updates. Some gems we currently use are not supported anymore and replacements will have to be found or code has to be adapted accordingly.

It is an important goal to make MarkUs Ruby on Rails 3 ready.

This project requires good Ruby and Ruby on Rails skills, with deployment abilities. While working on this task the student should keep ease of deployment in mind.


Integrated documentation system
================================================================================

As the user base for MarkUs grows, the need for better documentation becomes clear. It will be an interesting software design problem to create an integrated documentation system that tracks versions and configurations.

This project requires some Ruby/Rails knowledge and a desire to create simple, elegant software.
