================================================================================
Simple Grade Entry
================================================================================

What is simple grade entry?
================================================================================

Simple grade entry allows instructors to create grade entry forms to keep
track of students' grades for tests, labs, exams, or other activities.

Why do we want this feature?
================================================================================

Consider the following scenario:

Sally, the instructor for CSC108, is already using MarkUs to keep track of
grades for assignments. However, she has to use a different program to enter
students' grades for tests, labs, and exams. Sally would really like to be
able to use MarkUs to keep track of grades for all items of course work,
including items that do not need to be annotated, like tests. The simple grade
entry feature allows Sally to do this.

How does simple grade entry work?
================================================================================

Consider the following user story:

Sally would like to use MarkUs to enter students' grades for their CSC108
midterm. The midterm consists of three questions. Sally pulls up the grade
entry creation form page. She specifies some details about the content of the
midterm and the date it took place. She then specifies the question names and
the total number of marks for each question. Once the form is created, Sally
can navigate to the Grades page. This page contains a table populated with all
the students' names, question names, and question totals and all Sally has to
do now is enter the marks.

User interface for instructors:
================================================================================

Grade entry form creation
--------------------------------------------------------------------------------


Creating a grade entry form is simple:

* Navigate to the "Assignments" page and click on "Create new grade entry form"
* Next, fill in some basic properties:

    * Short Identifier (T1, L1, etc.) - Required. Must be a unique name
    * Name (Term Test 1, Final Exam, Lab 1, etc.) - Optional
    * Message - Optional. A description of the test, lab, etc.
    * Date - Required. The date the test, exam, etc. took place
    * For each question, specify the question name and total number of marks for
      that question (eg. "Q1", "10")

* Click on Submit

If any errors occurred during creation, they will appear at the top of the
creation form. Otherwise, a success message is displayed.

Editing a grade entry form
--------------------------------------------------------------------------------

Grade entry forms can also be modified after creation:

* Navigate to the grade entry form
* Modify any of the properties (For example, question names and totals can be
  changed, questions can be added or removed, the description of the test can
  be changed, etc.)
* Click on Submit

If any errors occurred while updating the grade entry form, they will appear
at the top of the form. Otherwise, a success message is displayed.

Entering the grades
--------------------------------------------------------------------------------
Once a grade entry form has been created, students' grades can be entered into
a table that is populated with student user names, last names, and first names
and question names and totals.

* Navigate to the "Grades" page for a particular grade entry form. If any
  grades for this form have already been entered, they will be displayed on
  this page. Grades can also be entered and/or modified. The grades for
  particular subsets of students or for all the students can be
  released/unreleased. The grades table can be uploaded or download as a CSV
  file.

User interface for students:
================================================================================

Viewing marks
--------------------------------------------------------------------------------

A student's grade entry forms appear on his main page underneath his list of
assignments. Students can see both their total mark and the class average for
each grade entry form. Students can also click on a particular grade entry
form to see the question-by-question breakdown of the marks.

Implementation details
================================================================================

Database / Server Side
--------------------------------------------------------------------------------

The database schema diagram can be seen here: [Grade Entry DB Schema |
http://blog.markusproject.org/wp-content/uploads/2009/10/GradeEntrySchema.pdf]]

There are four tables required for simple grade entry:

GradeEntryForm
********************************************************************************

* <code>short_identifier: (string)</code> A unique name used to identify this grade entry form
* <code>name: (string)</code> A longer name for this grade entry form
* <code>message: (text)</code> A description for this grade entry form
* <code>date: (date)</code> The date the test/exam/lab took place

GradeEntryItem
********************************************************************************

* <code>name: (string)</code> The question name
* <code>out_of: (float)</code> The total number of marks for this question
* <code>grade_entry_form_id: (integer)</code> The GradeEntryForm this question belongs to

GradeEntryStudent
********************************************************************************

* <code>user_id: (integer)</code> The User this GradeEntryStudent represents
* <code>grade_entry_form_id: (integer)</code> The GradeEntryForm that this student corresponds to
* <code>released_to: (boolean)</code> Indicates whether or not the marks have been released to this student

#### Grade
* <code>grade_entry_item_id: (integer)</code> The column/question this Grade belongs to
* <code>grade_entry_student_id: (integer)</code> The row/student this Grade belongs to
* <code>grade: (float)</code> The mark the student corresponding to grade_entry_student_id got on the question corresponding to grade_entry_item_id

Here's an overview of each of these tables:

GradeEntryForm is meant to represent something like an exam, for example.

GradeEntryItem is meant to represent a column name in a grade entry table. For example, an exam has multiple questions and each question is out of a certain number of marks. For each question on the exam, there would be a GradeEntryItem to represent it. Thus, many GradeEntryItems would be associated with one GradeEntryForm.

Grade is meant to represent a table cell in a grade entry table. A Grade is associated with a particular student and a particular question on the exam. Thus, many Grades would be associated with one GradeEntryItem.

GradeEntryStudent is meant to represent a row in a grade entry table. For example, a grade entry table has one row for each student. Each row consists of the grades a student got on each question of the exam. Thus, many Grades would be associated with one GradeEntryStudent. When we release marks to a student, we’ll want to release the marks for all the questions on the exam, not on a per question basis. GradeEntryStudent has a released_to_student field which indicates whether or not the marks for the questions have been released. Many GradeEntryStudents would be associated with one GradeEntryForm.

Overview of the controller code and code for the views:
--------------------------------------------------------------------------------

grade_entry_forms_controller.rb
********************************************************************************

Contains methods for creating and editing a grade entry form. Will also
contain the code for managing the entered grades.

grade_entry_forms_helper.rb
********************************************************************************

Contains a method that allows the user to create a new column for the grade
entry form. The JavaScript in this method is necessary because it is possible
for the GradeEntryForm to not exist yet when the form fields come up (i.e.
when an instructor is creating a new grade entry form).

Code for the views:
********************************************************************************

* <b>app/views/grade_entry_forms/_form.html.erb</b> - This partial contains the code for the displaying the grade entry form properties
* <b>app/views/grade_entry_forms/new.html.erb</b> - Makes use of the "form" partial for the "Create a New Grade Entry Form" page
* <b>app/views/grade_entry_forms/edit.html.erb</b> - Makes use of the "form" partial for the "Edit Grade Entry Form" page
* <b>app/views/grade_entry_forms/_grade_entry_item.html.erb</b> - This partial allows the user to specify a new question name and the total number of marks for that question
* <b>app/views/grade_entry_forms/_list_manage.html.erb</b> - Used to display the grade entry forms on the Assignments main page since we decided to treat grade entry forms as "Assignments". This partial must take the "action" as an argument since this behaviour will be different for TAs and instructors.
* <b>app/views/grade_entry_forms/grades.html.erb</b> - Used for the "Manage Grades" page
* <b>app/views/grade_entry_forms/_grades_table.html.erb</b> - Contains the code for displaying the table. The table contains one row for each student and one column for each question. Each column name contains the question name and the total number of marks for that question. The last column contains each student's total mark.

Tests
--------------------------------------------------------------------------------
This semester, we switched many of our tests over to Machinist. The blueprints
for grade entry forms can be found in:
<code>test/blueprints/blueprints.rb</code>

Unit Tests
********************************************************************************

* <b>test/unit/grade_entry_form_test.rb</b> - Tests for the GradeEntryForm model
* <b>test/unit/grade_entry_item_test.rb</b> - Tests for the GradeEntryItem model
* <b>test/unit/grade_entry_student_test.rb</b> - Tests for the GradeEntryStudent model
* <b>test/unit/grade_test.rb</b> - Tests for the Grade model
* <b>test/unit/grade_entry_form_test.rb</b> - Tests for the Grade model (to be added together with the Table view since they are related)

Functional Tests
********************************************************************************

* <b>test/functional/grade_entry_forms__controller_test.rb</b> - Tests for the GradeEntryForms controller




