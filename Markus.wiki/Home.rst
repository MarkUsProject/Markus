================================================================================
Welcome to MarkUs
================================================================================

MarkUs (pronounced "mark us") is an open-source tool which recreates the ease
and flexibility of grading assignments with pen on paper, within a web
application.  It also allows students and instructors to form groups, and
collaborate on assignments. It's predecessor OLM (Online Marking) was
[[originally written|https://stanley.cdf.toronto.edu/drproject/csc49x/olm]]
in Python on top of the TurboGears framework.

The MarkUs project is a re-implementation of the Online Marking system using
Ruby on Rails. The goal of this project is to take what we learned from OLM
and our forays into [[Web-CAT|http://web-cat.cs.vt.edu/]], and build a
web-based marking tool that includes an early submission and testing system in
support of test driven development.


Project Resources
================================================================================

* **Project Website** http://www.markusproject.org
* **Developer's Blog** http://blog.markusproject.org
* **Review Board** http://review.markusproject.org

  * [[How to create a MarkUs review | HowToReviewBoard]]

* **IRC Channel:** Our channel is #markus on irc.freenode.net.
  [[Logs of the channel|http://www.markusproject.org/irc/]] are also available.
* **Sandbox** http://www.markusproject.org/admin-demo/
* **User Guide:** [[MarkUs Documentation | UserGuide]]

  * **Instructor Guide:** [[Instructor Guide | Doc_Admin]]
  * **Grader Guide:** [[Grader Guide | Doc_Grader]]
  * **Student Guide:** [[Student Guide | Doc_Student]]

* **Git Resources:**

  * **MarkUs and Git** [[HowTo| GitHowTo]]
  * [[A Git Tutorial| http://library.edgecase.com/git_immersion/index.html]]
  * [[Progit Book| http://progit.org/book/]]
  * [[Gitref.org| http://gitref.org]]

* **Issue Labels:** [[Their meaning is described here | LabelsWhatTheyMean]]

.. TODO Modify User Guide link

Screencasts
--------------------------------------------------------------------------------

* [[Student File Submission: September 2 2009 |
  http://www.youtube.com/watch?v=ofpyaty20FQ]]
* [[Student Group Formation: August 17, 2009 |
  http://www.youtube.com/watch?v=Ed_z_tHCAg8]]
* [[The Grader View: June 6, 2009 |
  http://www.cs.toronto.edu/~reid/screencasts/OLM-2009-06-03.swf]]
* [[Flexible Marking Scheme Selection: December 1, 2009 |
  http://www.youtube.com/watch?v=x4mbE3WBgog]]
* [[Flexible Marking Scheme Criterion: December 1, 2009 |
  http://www.youtube.com/watch?v=tVkti9y91RA]]
* [[Notes created through the Modal dialog as an Admin: December 3, 2009 |
  http://www.youtube.com/watch?v=eoxriy2cYW0]]
* [[Notes created through the Modal dialog as a TA: December 3, 2009 |
  http://www.youtube.com/watch?v=J4r18LNDwPs]]
* [[Creating and editing a grade entry form as an admin: December 4, 2009 |
  http://www.youtube.com/watch?v=r7UnaNYe2rw]]
* [[Notes tab: December 11, 2009 |
  http://www.youtube.com/watch?v=IcuG6AlJfvQ]]
* [[Entering and releasing the marks for a grade entry form as an admin: April
  4, 2010 | http://www.youtube.com/watch?v=-v6eVy94pdI]]

MarkUs Developer Installation Guides
================================================================================
GNU/Linux
--------------------------------------------------------------------------------
* [[Setting up a development environment on GNU/Linux|InstallationGnuLinux]]

Mac OS X
--------------------------------------------------------------------------------
* [[Setting up a development environment on Mac OS X 10.6 (Snow Leopard) |
  InstallationMacOsX]]

Windows
--------------------------------------------------------------------------------
**(Note: GNU/Linux and Mac OS X development environments generally caused less
problems)**

* [[Setting up a development environment on Windows using
  InstantRails | InstallationWindows]]

Databases
--------------------------------------------------------------------------------

* [[Setting up the Database (SQLite)|SettingUpSQLite]]
* [[Setting up the Database (MySQL)|SettingUpMySQL]]
* [[Setting up the Database (PostgreSQL)|SettingUpPostgreSQL]]


MarkUs Developer Documentation
================================================================================

Project Vitals
--------------------------------------------------------------------------------

Repository: Create a Github account and fork MarkUsProject/MarkUs (see Github
help for more info).

Mailing list address: markus-dev@cs.toronto.edu

Mailing [[list archive at marc.info|http://marc.info/?l=markus-dev&r=1&w=2]]

Project Contributors
--------------------------------------------------------------------------------
Adam Goucher, Alexandre Lissy, Amanda Manarin, Andrew Louis, Anthony Le Jallé, Anton Braverman, Benjamin Thorent, Benjamin Vialle, Bertan Guven, Brian Xu, Bryan Shen, Catherine Fawcett, Christian Jacques, Clément Delafargue, Clément Schiano, Danesh Dadachanji, Diane Tam, Dina Sabie, Evan Browning, Farah Juma, Fernando Garces, Gabriel Roy-Lortie, Geoffrey Flores, Horatiu Halmaghi, Ibrahim Shahin, Jérôme Gazel, Jiahui Xu, Joseph Mate, Joseph Maté, Justin Foong, Karel Kahula, Kurtis Schmidt, Mélanie Gaudet, Michael Lumbroso, Mike Conley, Mike Gunderloy, Misa Sakamoto, Neha Kumar, Nelle Varoquaux, Nicolas Carougeau, Noé Bedetti, Oloruntobi Ogunbiyi, Robert Burke, Samuel Gougeon, Severin Gehwolf, Shion Kashimura, Simon Lavigne-Giroux, Tara Clark, Valentin Roger, Veronica Wong, Victoria Mui, Victor Ivri, Vivien Suen, Yansong Zang

**Supervisors:** Morgan Magnin, Karen Reid


Term Work
--------------------------------------------------------------------------------

.. TODO Some of the following links have been removed during the migration to
  github.
  They should all be out on the blog

* **Fall 2010**

  * [[Who is doing what? (punchlines/minutes) |
    http://blog.markusproject.org/?p=1713]]

* **Winter 2010**

  * [[Who is doing what? (punchlines/minutes) |
    http://blog.markusproject.org/?p=1049]]

* **Fall 2009**

  * [[Who is in charge of what, administratively? |
    http://blog.markusproject.org/?p=504]]

  * [[September 18 - Pre-meeting Status |
    http://blog.markusproject.org/?p=296]]

Everything a Developer Needs to Know about Ruby, Ruby on Rails and MarkUs
--------------------------------------------------------------------------------

* **Getting Started with Ruby, Ruby on Rails and MarkUs**

  * [[Short Rails Debugging HOWTO | RailsDebugging]]
  * [[How to program in Ruby, Rubybook | http://ruby-doc.org/docs/ProgrammingRuby/]]
  * [[Rails API | http://api.rubyonrails.org]]
  * [[Rails Guides | http://guides.rubyonrails.org]]
  * [[General Guide Lines to code - Code review from Mike Gunderloy |
    GeneralGuideLines]]
  * http://apidock.com/rails
  * [[Some notes from a Ruby book taken by Tara Clark |
    http://taraclark.wordpress.com/category/ruby-on-rails]]
  * [[How to run Selenium tests | SeleniumTesting]]
  * [[Acceptance/Cucumber tests | CucumberTesting]]
  * [[How to use the MarkUs API | ApiHowTo]]
  * [[How to use MarkUs Testing Framework | TestFramework]] (still in alpha)


* **MarkUs Coding Style/Coding Practices/Rails Gotchas**

  * [[Basic Guidelines for MarkUs Development | DeveloperGuidelines]] (**IMPORTANT!**)
  * [[How to use Review Board | HowToReviewBoard]]
  * [[Rails erb quirks | RailsERbStyle]]
  * [[Use h (alias for html_escape) and sanitize in
    views | RailsViewsConventions]]
  * **Please document your code according to the RDoc specification** (see
    [[how to use RDOC | http://rdoc.sourceforge.net/doc/]])
  * **Ruby compatibility:** Please check ticket: #206. Also check out the 
    [[difference between COUNT, LENGTH, and
    SIZE | http://blog.hasmanythrough.com/2008/2/27/count-length-size]
  * [[Our Ruby/Rails testing guidelinesi | TestingGuidelines]]
  * [[Security testing guidelines | SecurityTesting]]
  * [[Internationalization | Internationalization]]

* **MarkUs API/Test Coverage**

  * [[MarkUs Ruby Doc | http://www.markusproject.org/dev/app_doc]]
  * [[MarkUs Test Coverage | http://www.markusproject.org/dev/test_coverage]]

* **MarkUs Releases**

  * [[Preparing a Release and Patch | PreparingReleaseAndPatch]]

* **User Roles and Stories for MarkUs**

  * General / Constraints

    * [[MarkUs is internationalized|GeneralUseCase_Internationalized]]
    * [[MarkUs is configurable|GeneralUseCase_Configurable]]
    * [[Rubrics are not allowed to change once Submissions have been
      collected|GeneralUseCase_NoRubricChangesAfterCollection]]

    * [[Instructor|Role_Instructor]]

      * [[Instructors can create / edit assignments|Instructor_CreateEditAssignments]]
      * [[Instructors can download/export files|Instructor_DownloadExportFiles]]
      * [[Instructors can hide students|Instructor_HideStudents]]
      * [[Instructors can do everything that Graders can do|Instructor_CanDoWhatGradersDo]]
      * [[Instructors can release/unrelease completed marking results|Instructor_ReleaseMarkingResults]]
      * [[Instructors can map particular students/groups to Grader_(s) for marking|Instructor_MapGradersToGroupings]]
      * [[Instructors can download / export a file that describes the Student /Grouping mapping to Graders|Instructor_DownloadMapGradersToGroupings]]
      * [[Instructors can upload a file that will do the Student /Grouping mapping to Graders|Instructor_UploadMapGradersToGroupings]]
      * [[Instructors can manage groups without restrictions|Instructor_ManageGroupsWithoutRestrictions]]

    * [[Grader|Role_Grader]]

      * [[Graders can easily tell which submissions are assigned to them to mark|Grader_EasyToSeeWhatToMark]]
      * [[Graders can view a Submission from a Student  / Grouping|Grader_ViewSubmissions]]
      * [[Graders can view/annotate/mark a particular file from a Submission|Grader_ViewAnnotateMarkParticularFile]]
      * [[Graders can add annotations to particular lines of code within a Submission File|Grader_AnnotateLinesOfCode]]
      * [[Graders can create reusable Annotations|Grader_CreateReusableAnnotations]]
      * [[Graders can create short, formatted overall comments on a Submission|Grader_CreateOverallComment]]
      * [[Graders can view and use a Rubric for marking a Submission for an Assignment|Grader_ViewUseRubric]]
      * [[Graders can view a summary of marked submissions|Grader_ViewSummaryOfMarkedSubmissions]]
      * [[Graders can add bonuses / penalties to submissions|Grader_AddBonusesPenalties]]
      * [[Graders can modify the marking state of a submission result|Grader_CanModifyMarkingStatus]]
      * [[Graders can easily switch to the next / previous Submission for marking|Grader_CanSwitchToNextSubmission]]

    * [[Student|Role_Student]]

      * [[Students can view marks of submissions|Student_ViewMarks]]
      * [[Students can view annotations of marked submissions/assignments|Student_ViewAnnotations]]
      * [[Students can submit files for their assignments|Student_SubmitFiles]]
      * [[Students can view/edit submission files for assignments|Student_ViewEditFiles]]

* **Database Schema**

  * AutoGenerate Database Schema

    * [[View Schema Diagram|images/database_20101001.png]]

  * [[Questions and Answers (Old Document) | SchemaQuestions]]

* **MarkUs Component Descriptions**

  * [[Group / Grouping Behaviours | GroupsGrouping]]
  * [[Groupings and Repositories | GroupsGroupingsRepositories]]
  * [[Authentication and Authorization | Authentication]]
  * [[Annotations | Annotations]]
  * [[How Student Work is Graded | HowGradingWorks]]
  * [[Submission Rules | SubmissionRules]]
  * [[The FilterTable Class | FilterTable]]
  * [[Simple Grade Entry | SimpleGradeEntry]]
  * [[Notes System | NotesSystem]]

* **Feedback Notes**

  * [[2009-05-22: Phyliss | PhylissFeedback]]
  * [[2009-06-22: Ryan | RyanFeedback]]

* **Tips and Trick**

  * [[Dropping/Rebuilding Database Quickly and Easily | DropAndRebuildDb]]

* **IDE/Editor Notes**

  * [[jEdit | JEdit]]
  * [[NetBeans | NetBeans]]
  * [[Aptana RadRails / Eclipse | AptanaRadRails]]

MarkUs Deployment Documents (Installation Instructions for MarkUs using RAILS_ENV=production)
===============================================================================================

* [[Setup Instructions for MarkUs Stable (MarkUs 0.10.0)|InstallProdStable]]
* [[Hosting several MarkUs applications on one machine (for Production)|MultipleHosting]]
* [[How to use LDAP with MarkUs|LDAP]]
* [[How to use Phusion Passenger instead of Mongrel|ApachePassenger]]

* [[Old Setup Instructions for MarkUs Stable (MarkUs 0.5, 0.6, 0.7 and 0.8 branches)|InstallProdOld]]

For a complete list of local wiki pages, see [[TitleIndex|http://github.com/MarkUsProject/Markus/wiki/_pages]].
