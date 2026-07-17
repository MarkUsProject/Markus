---
permalink: /instructors/assignments/marking-set-up/
title: "Marking: Set Up"
parent: Assignments
grand_parent: Instructors
nav_order: 3
---
# Marking an Assignment (Set-Up)
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

## Setting up a Grader Account

Anyone other than a course instructor who needs to grade student work must have a "Grader" account. For example, if a course has 4 TAs who will all grade work, you must set up 4 separate Grader accounts—one for each TA.

Course instructors do not require separate Grader accounts. They can be assigned directly to groups or marking criteria from an assignment's [Graders tab](assigning-graders.md), which can be useful for distributing and tracking marking work.

For information on setting up a "Grader" account please see "[Grader Accounts](../users.md#grader-accounts)".

## Submissions Table

The first step in marking an assignment is to collect the assignment. To do this, navigate to the "Assignments" tab of MarkUs, click on the assignment you wish to mark and then on the "Submissions" tab:

![Submissions Tab](/images/submissions-tab.png)

Here you will see a table of all the groups that have been formed (see [How Students Form Groups](../../students/index.md) and [Managing Group Repositories](../groups/index.md)):

| ![Submissions Table Part 1](/images/submissions-table.png) |
|--------------:|
| *First three columns shown* |

If students are not allowed to work in groups, then under the "Group" column you will simply see a student's username (as opposed to the group number and a list of usernames). The rest of the table contains information about each group and their submission for that assignment.

- The **"Repository"** column contains a link to the group's repository (where you can see all the files uploaded to the repo)
- The **"Submission Date"** column provides the date and time that the collected submission was submitted. This column will be blank if the submission has not been collected yet or if a student did not submit any work for this assessment.
- The **"Grace Credits Used"** column lists the number of grace credits a group spent on this assignment (field will be blank if no tokens were required)
- The **"Marking State"** lists the current state of marking of the group's submission (see [Marking State](#marking-state))
- The **"Total Mark"** column lists the group's mark once a grader has started entering marks for the assignment (default is 0).
- The **"Tags"** column lists any tags created for the submission.

Graders with the **Manage submissions** permission can view all submissions for an assignment from this table. These graders can use the **"Display assigned submissions only"** checkbox to switch between all submissions and only the submissions assigned to them. Graders without this permission remain limited to their assigned submissions and do not see this control. Instructors continue to view all submissions.

## Collecting an Assignment

Before you may being grading an assignment, you must first collect the submitted files from each group. To do this, make sure you are on the "Submissions" page of the assignment you wish to grade and select the checkbox(es) of the groups from which you wish to collect. You may also select the box at the top of the column to select all groups. Once satisfied, click on the "Collect Submissions" button to begin collection.

![Collecting Assignments](/images/submissions-table-collect.png)

> 🗒️ **NOTE:** By default, MarkUs only allows you to collect submissions AFTER the entire grace credit period has passed.

This will open a modal window with collection options:

![Submissions Modal](/images/submissions-modal.png)

The default option when the collect command is executed will select the file version for each submission that meets the due date and/or late penalty set for this assignment. It will not recollect submissions that have previously been collected. It then creates the views for annotating and grading each submission.

However, the modal offers a few additional options for collection:

![Submissions Modal With Options](/images/submissions-modal-with-options.png)

1. **Collect most recent files submitted, regardless of assignment due date or late period.** - if this box is checked, MarkUs will collect the most recent version of files the student has submitted, regardless of the due date and grace periods. This can be used to collect submissions both before and after the due date/grace credit periods.
   > 🗒️ **NOTE:** Submission collection can be done during the late period, however students can still submit after the marking and prior to the late period is over. If you want to mark the most recent submission prior to the late period being over, you would need to manually go through the submissions to see if students submitted again, as there are no filters to identify them.
2. **Recollect previously collected submissions** - if this box is checked, MarkUs will recollect submissions that have previously been collected.
   1. When this box is checked, MarkUs provides the option to **retain grading data** (marks, annotations, feedback files, and test results) on any collected submissions that have it. **WARNING:** This option is true by default and disabling it will result in the permanent loss of all grading data on recollected submissions.
      - For any extra marks or deductions on a graded submission, point-based extra marks will be retained, but percentage-based penalties will not. The decision to apply percentage-based penalties is solely at the instructor's discretion during collection. This means that two identical submissions may receive different percentage penalties at collection time, depending on the assignment's submission rule.
3. **Apply Late Penalty** - this option will only appear when collecting the most recent submissions. When collecting by due date, the late penalties are always applied. If it is unchecked, MarkUs will not apply penalties or deduct grace credits for submissions created after the due date.

Once the files for an assignment have been collected, the marking state of the submission will change from "Not Collected" to "In Progress".

> 🗒️ **NOTE:** Scanned exams are always collected based on the most recently submitted files, so only the recollect option is available.

### Collecting Specific Revisions

An instructor can bypass the collection process to manually select which version of a group's files to collect and grade (this is helpful when an individual extension is given to a student, for example). To do so, first click on the "Repository Name" link for the appropriate group. Then navigate to the version of the submitted files you wish to grade, and click on the "Manually Collect and Grade Revision" button. The option to retain grading data will also appear on this page if the submission has been previously collected.

## Marking State

There are six different marking states for a submission:

 1. **Not Collected** - The group has been formed and may have submit work already but nothing has been collected by any TA or instructor. All groups should have this status until the deadline to submit (with grace token extension) has passed.
 2. **In Progress** - Either a TA or an instructor has collected the submission and is currently working on grading the assignment.
 3. **Complete** - The grading of the assignment has been completed but the mark has not yet been released to the group.
 4. **Released** - The mark has been released to the group along with any annotations that have been made.
 5. **Before Due Date** - The due date has not passed for this group.
 6. **Remark Requested** - This group has requested a remark request.

## Grading View

Once you have collected an assignment, you may begin grading. Please see the [Grading View](marking-grading-view.md) page for instructions.

> 🗒️ **NOTE:** Before you will be able to perform any numerical marking (i.e. assigning groups a numerical grade) you must set up at least one [criterion](marking-criteria.md) for your assignment.
