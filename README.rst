.. image:: http://markusproject.org/markus_logo_big.png
   :align: center
   :alt: MarkUs logo

================================================================================
Welcome to MarkUs! Online Marking Made Easy
================================================================================

http://markusproject.org/

MarkUs (pronounced "mark us") is an open-source tool which recreates the ease
and flexibility of grading assignments with pen on paper, within a web
application. It also allows students and instructors to form groups, and
collaborate on assignments. Its predecessor OLM (Online Marking) was originally
written in Python on top of the TurboGears framework.

The MarkUs project is a re-implementation of the Online Marking system using
Ruby on Rails. The goal of this project is to take what we learned from OLM and
our forays into Web-CAT, and build a web-based marking tool that includes an
early submission and testing system in support of test driven development.


1. Features
================================================================================

* Graders can easily annotate students' code (overlapping annotations, graded
  source code remains untouched)
* Subversion storage back-end
* Instructors can form teams
* Students can form groups on their own
* Supports different course models:

  * Web-based file upload for first-year courses
  * Subversion client commits for upper year courses (disabled Web-upload)
  * Allows students to work on code of other groups from one assignment to the next

* Web-based course administration
* One MarkUs application per course (independent databases across courses)

Please see the INSTALL file for installation instructions.

2. Links
================================================================================

* Email a security alert: security@markusproject.org
* Email a general inquiry: info@markusproject.org
* Blog: http://blog.markusproject.org/
* Sandbox: http://www.markusproject.org/admin-demo
* Source Code: http://github.com/MarkUsProject/Markus
* Review Board: http://review.markusproject.org/r/
* MarkUs RDoc: http://www.markusproject.org/dev/app_doc/
* Test Coverage: http://www.markusproject.org/dev/test_coverage/
* Units Test Report: http://www.markusproject.org/dev/unit_tests_report.html
* Functional Test Report: http://www.markusproject.org/dev/functional_tests_report.html
* IRC Channel: irc://irc.freenode.net/#markus  (Logs): http://www.markusproject.org/irc/
* Mailing list: markus-users@cs.toronto.edu


3. Sandbox
================================================================================

If you are interested in MarkUs and would like to try it out, there is a MarkUs sandbox installation available (http://www.markusproject.org/admin-demo). For information as to how to use the demo instance please see our "How to use the demo server" (http://blog.markusproject.org/?p=219) blog post. We hope you will enjoy it and please let us know how you liked it: info@markusproject.org.

4. System Requirements
================================================================================

* Rails 3.0/Ruby 1.8.7 or Ruby 1.9.3
* Unicorn/Passenger
* PostgreSQL/MySQL
* Subversion

Note: As of now, the latest stable version is MarkUs 0.10.0. Here is our current
deployment/configuration documentation. Please send us email if you have any
trouble installing MarkUs---we'd be happy to help you out.

5. Who is Using MarkUs?
================================================================================

* Department of Computer Science, University of Toronto, Canada
* School of Computer Science, University of Waterloo, Canada
* École Centrale de Nantes, France

6. Staying in Touch
================================================================================

Want the latest MarkUs news? It's available several ways:

* General queries can be sent to info@markusproject.org.
* The development team has a blog at http://blog.markusproject.org.
* There is a mailing list for MarkUs users. You can also find us on IRC in the
  #markus channel on FreeNode.
* We use Review Board to manage code reviews. You can view our development
  activity using our event log.

7. Screencasts
================================================================================

Here are are some screencasts of MarkUs (reverse chronological order):

* Student File Submission: September 2, 2009 http://www.youtube.com/watch?v=ofpyaty20FQ

  This screencast demonstrates how students can upload, replace and delete
  files using MarkUs' easy to use Web interface. The nice part is that files
  really end up in a Subversion repository (without students ever noticing).

* Student Group Formation: August 17, 2009 http://www.youtube.com/watch?v=Ed_z_tHCAg8

  MarkUs supports various course models. One possibility of which is that an
  instructor can allow students to work in teams. If an Assignment is set up
  this way, students can go and start form groups on their own using MarkUs.

* The Grader View: June 6, 2009 http://www.cs.toronto.edu/~reid/screencasts/OLM-2009-06-03.swf

  The grader view is one of the core functionalities of MarkUs, which allows
  graders (usually TAs) to mark a student's/group's work for an assignment. He
  or she can annotate the submitted source code - which is syntax highlighted -
  and mark according to rubrics defined by the instructor.

8. Helping Out
================================================================================

Found a bug? Want a feature? Please email info@markusproject.org.

9. Credits
================================================================================

MarkUs grew out of OLM, which was build using the TurboGears framework. We are
grateful to everyone who worked on or funded both projects, and to the creators
of Ruby on Rails for building such a great framework.

MarkUs' development has been supported by the University of Toronto, École
Centrale de Nantes, et. al. Kudos to everyone who turned that support into
working code:

Aaron Lee, Adam Goucher, Aimen Khan, Alexandre Lissy, Alex Krassikov, Alysha Kwok,
Amanda Manarin, Andrew Louis, Anthony Le Jallé, Anton Braverman, Benjamin Thorent,
Benjamin Vialle, Bertan Guven, Brian Xu, Bryan Shen, Camille Guérin, Catherine
Fawcett, Christian Jacques, Christine Yu, Clément Delafargue, Clément Schiano,
Danesh Dadachanji, Daryn Lam, Daniel St. Jules, Dina Sabie, Diane Tam, Egor
Philippov, Erik Traikov, Evan Browning, Farah Juma, Fernando Garces, Gabriel Roy-
Lortie, Geoffrey Flores, Ghislain Guiot, Hanson Wu, Horatiu Halmaghi, Ian Smith,
Ibrahim Shahin, Jay Parekh, Jérôme Gazel, Jiahui Xu, Jordan Saleh, Joseph Mate,
Joseph Maté, Justin Foong, Karel Kahula, Kurtis Schmidt, Luke Kysow, Marc Bodmer,
Mélanie Gaudet, Michael Lumbroso, Mike Conley, Mike Gunderloy, Mike Stewart, Mike
Wu, Misa Sakamoto, Neha Kumar, Nelle Varoquaux, Nicolas Bouillon, Nick Lee, Nicolas
Carougeau, Noé Bedetti, Oloruntobi Ogunbiyi, Oussama Ben Amar, Razvan Vlaicu, Robert
Burke, Samuel Gougeon, Sean Budning, Severin Gehwolf, Shion Kashimura, Simon Lavigne-
Giroux, Tara Clark, Tianhai Hu, Valentin Roger, Veronica Wong, Victoria Mui, Victor
Ivri, Vivien Suen, Yansong Zang

Supervisors: Karen Reid, Morgan Magnin
