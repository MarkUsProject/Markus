![MarkUs logo](app/assets/images/markus_logo_small.png)

Welcome to MarkUs! Online Marking Made Easy
===========================================

MarkUs is a web application for the submission and grading of student programming assignments. The primary purpose of MarkUs is to provide TAs with simple tools that will help them to give high quality feedback to students. MarkUs also provides a straight-forward interface for students to submit their work, form groups, and receive feedback. The administrative interface allows instructors to manage groups, organize the grading, and release grades to students.

Since 2008, more than 140 undergraduate students have participated in the development of MarkUs; some as full-time summer interns, but most working part time on MarkUs as a project course. The fact that we have have uncovered so few major bugs, and that MarkUs has been so well-received by instructors is a testament to the high quality work of these students. MarkUs is used in more than a dozen courses at the University of Toronto, in several courses at the University of Waterloo, and at École Centrale Nantes (in French).

MarkUs is written using Ruby on Rails, and uses Subversion (with a Git back-end in progress) to store the student submissions. 


## 1. Features

- Graders can easily annotate students' code (overlapping annotations, graded source code remains untouched)
- Subversion storage back-end
- Instructors can form teams
- Students can form groups on their own
- Supports different course models:

  - Web-based file upload for first-year courses
  - Subversion client commits for upper year courses (disabled Web-upload)
  - Allows students to work on code of other groups from one assignment to the next

- Web-based course administration
- One MarkUs application per course (independent databases across courses)

Please see the INSTALL file for installation instructions.

## 2. System Requirements

- Rails 3.0/Ruby 1.9.3+ (2.1.2 recommended)
- Unicorn/Passenger
- PostgreSQL/MySQL
- Subversion

Note: As of now, the latest stable version is MarkUs 0.10.0. Here is our current
deployment/configuration documentation. Please send us email if you have any
trouble installing MarkUs---we'd be happy to help you out.


## 3. Who is Using MarkUs?

- Department of Computer Science, University of Toronto, Canada
- School of Computer Science, University of Waterloo, Canada
- École Centrale de Nantes, France

## 4. Credits

MarkUs grew out of OLM, which was built using the TurboGears framework. We are
grateful to everyone who worked on or funded both projects, and to the creators
of Ruby on Rails for building such a great framework.

MarkUs' development has been supported by the University of Toronto, École
Centrale de Nantes, et. al. Kudos to everyone who turned that support into
working code, which you can see in our [Contributors list](doc/markus-contributors.txt)

**Supervisors:** Karen Reid, Morgan Magnin, Benjamin Vialle, David Liu
