================================================================================
MarkUs User Guide
================================================================================



This guide is attempts to describe all features of MarkUs. Note that some features may not be available in all versions. Some features might not be available in any released version (yet).

.. contents::

Creating Users
================================================================================

There are 3 types of users:

* Instructors/Admins
* Graders/TAs
* Students

To create users, you must log in as an admin. Navigate to the Users tab, and
from there you will be able to create new students, graders or admins. Simply
press the 'Add New' link above the top right corner of the table and fill in
the user's information.

It is also possible to create many users at once by uploading a CSV file with
their information. Each row of the CSV file should be in the format user_name,
last_name, first_name.

Creating an Assignment
================================================================================

After creating some students, its time to give them some work to do. To create
a new assignment, log in as an admin and select the assignments tab. All
current assignments will be listed there. Just press the 'Add Assignment'
button.

Fill in the form to create the appropriate assignment. Short Identifier, Due
Date and Repository Folder are the only 3 required fields. The rest are
optional.

Here is a description of all the assignment creation options:

Marking Scheme
--------------------------------------------------------------------------------

Rubric follows the traditional marking approach using rubrics. There are
multiple criteria for the assignment, and each criteria has a fixed number of
levels (usually from 0-4) which a student can attain.

Flexible scheme allows for multiple marking criteria to be created. The
graders then assign a percentage grade (0-100) for each criteria.

Required Files
--------------------------------------------------------------------------------

If there are any specific file names that students should use when submitting
their work, specify them here. MarkUs will let students know if they are
missing the required files for the assignment.

This helps avoid file naming errors.

Assignment Type
--------------------------------------------------------------------------------

Specify whether students are allowed to work in groups or not. You have the
option of keeping the same group arrangements from previous assignments. You
can also control things like max and min group sizes and allowing students to
make their own groups or not from here.

Submission Rules
--------------------------------------------------------------------------------

* No late submissions - The latest submission before the assignment deadline
  will be used for each student.

* Grace period rule - Each student may be assigned 'grace credits' via the
  Users tab. Multiple grace periods for the assignment may be added here. If a
  student submits something after the assignment deadline but before all the
  grace periods have expired, MarkUs will automatically deduct a grace credit
  for every grace period the student uses.

* Late penalty rule - It is possible to specify automatic mark deductions for
  late submissions here. Both the percentage deducted and when it is deducted
  can be specified.

Note: It is possible for an admin or a grader to bypass an assignment's
submission rule by manual collection, but more on this in the 'Collecting
Submissions' section

Remark Request Rules
--------------------------------------------------------------------------------

* Allow remark requests - Checking this box allows students to request remarks
  after original results have been released.

* Remark Due Date - Students will not be able to submit remark requests after
  this date.

* Remark Message - Text to provide instructions that students should follow for
  remark requests.

Adding Marking Criteria
--------------------------------------------------------------------------------

After creating an assignment, select the 'Marking Scheme' tab to manage how
the assignment will be graded. From this page, you can manage your marking
criteria.

Select 'Add Criterion' and enter a criterion name to create it. Once its
created, you can modify the weight of a criterion its name simply by selecting
it on the left hand menu.

If you are using rubric marking scheme for the assignment, you can specify the
different levels of the rubric. If the name and description of a grade level
is left blank, it will not be shown to the graders. For example, a standard
rubric criterion has 5 grade levels ranging from very poor to excellent. If
you remove the fifth level 'excellent', then the criterion will now only have
4 levels, from very poor to good.

If you are using a flexible marking scheme, then you simply fill in the
maximum mark field and add a description to the criteria.

Criterion orders can also be changed by either dragging and dropping them or
using the arrows beside the criteria names to rearrange them.

You can also upload and download marking schemes in either yml or csv format
by pressing the upload or download links on the page. The proper upload format
is detailed on the page.

Managing Groups and Graders
--------------------------------------------------------------------------------

Groups
********************************************************************************

An instructor can modify student groups for any assignment. Simply select
the groups tab when looking at any assignment. From here, you can create, 
delete and modify groups. The UI is fairly straight forward, a table with all
the students on the left and a table of all the groups on the right. 

You can also validate groups. A valid group is one that meets the assignment's
group size specifications. If a group has too many or not enough students, it 
will be invalid and will have a red cross beside its name. Instuctors have the
option to validate any group they want no matter how many members it contains.

Graders
********************************************************************************

This view allows you to decide which graders to assign to which groups. It is 
possible to randomly assign graders to groups via the arrow with the dice on it.

It is now also possible to assign graders to individual marking criteria. Choose
the 'Criteria' tab on the table and check the 'assign graders to criteria' box.
For example, one grader could be in charge of code style, the other of 
correctness and a third of any special features of the code, etc...
Once assigning graders to criteria is checked, a coverage count will appear 
for each group. This shows if the group has graders assigned that cover every
marking criterion. For example, if a group is missing a grader who is assigned 
to a style criterion, the coverage count will let you know. You can also press
the red cross beside the counter to bring up a box that shows in detail which
criteria aren't covered and who can cover them. 


Collecting Submissions
--------------------------------------------------------------------------------

After the students submit their work and the assignment deadline passes, it is 
time to start marking. In order to grade the work of a student, MarkUs collects
the appropriate version of their submissions from their repositories, however
it does not collect automatically. 

In order to collect student submissions, select the submissions tab while viewing
an assignment. A table will display information about every single student group
created for the assignment. To start collecting their submissions, simply click
the 'collect all submissions' at the start of the page.

This launches a separate process that will collect the appropriate revision submitted
by each group, which is essentially a big queue that processes each student
group iteratively. There is also a priority queue, which holds groups that
need to be processed ahead of schedule.

Colour Scheme of the Submission Table
********************************************************************************

A row in the submission table represents a student group. It can be either
green or white.

When the row is white, MarkUs does not have a submission for this group to be
marked. This happens when no submissions have been collected, or for some reason
the group is in queue to get its submission re-collected. Attempting to grade
a white group will put it in the priority queue of the collection process.

A green row means that this group is ready to be marked.

Which Submission Will be Collected?
********************************************************************************

* Grace period rule - MarkUs will collect the latest submission of the group
if that group can spare the grace credits. To illustrate: if there are two
grace days at a cost of one credit each, and the group only has one grace
credit, then MarkUs will collect the latest submission up to the end of the first
grace day, and deduct the necessary credits if the submission timestamp falls
after the assignment deadline but within the grace period.

* Late penalty rule - The latest submission that does not exceed the late
penalty periods will be collected and the necessary deductions will be applied.

* No late submissions - The latest submission to be submitted that does not 
exceed the assignment deadline will be collected.

An instructor or grader can bypass the application and deductions of the 
submission rule by manually collecting the group's submission. This can be 
done by clicking on the 'repository name' column of the appropriate row in the
submissions table and choosing the appropriate revision to be 

PDF Files
********************************************************************************

If MarkUs is configured to support in-browser display of PDF files, it will have
an impact on the submission collection process. In order to display the file in
the browser, MarkUs first converts it to jpg format via ImageMagick when the
submission containing the file gets collected. Conversion is a time consuming 
process, and can take about a minute for a 10 page document. Thus keep in mind
that it will take some time for all the submissions to be collected.

Grading
================================================================================

When you are ready to grade a submission, simply select the group name from
the submissions view. You will be redirected to a page containing all the
files of the submission. 

Grading is fairly straight forward. Once you have decided on a grade, simply
select the appropriate rubric grade level or enter a mark for the criterion if
you are using the flexible marking scheme.

If you are a grader and have been assigned to a few specific criteria, those
criteria will automatically be expanded and outlined, whilst the other
criteria you aren't assigned to will be minimized. Note: a grader may modify
any criteria even if they are not assigned to it. 

Adding Annotations
--------------------------------------------------------------------------------

In order to help you grade and give feedback to the students, MarkUs has an
annotation system. Creating one is very simple. If the file is an image/pdf,
then select the area to be annotated with your mouse and write the comment. If
the file is a text file, then select the lines you want to annotate and press
the 'New Annotation' button.

To review and edit all your annotations, select the 'Annot. Summary' tab. You
will get a list of all the annotations for all the files in this submission. 
