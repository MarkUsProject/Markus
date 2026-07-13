---
permalink: /instructors/assignments/peer-review/
title: Peer Review
parent: Assignments
grand_parent: Instructors
nav_order: 11
---
# Peer Review Assignments

MarkUs supports *peer review*-based assignments that allow students to provide feedback on the work of other students.
In MarkUs, peer reviews are conducted in two phases.
In the first phase, students submit their work to an assignment on MarkUs; in the second, students get assigned submissions to review, and then give feedback for these submissions using the standard grading interface.
This page describes the overall workflow for an instructor to set up and administer a peer review assignment.

## Setting up the peer review assignment

1. To begin, first to create an assignment where students will submit their work. We'll refer to this assignment as the *source assignment*.
    You can use all of the standard [assignment settings](setting-up.md), including having students submit in groups.
2. Next, use the "Create Peer Review Assignment" button to create a new peer review assignment.
    In this assignment, students will not submit any files for grading, but instead provide feedback for student work submitted to the assignment from Step 1.
3. In the "Source assignment" dropdown, select the assignment you created in Step 1.

    The settings for the peer review assignment can be different from the assignment from Step 1, and in particular you may choose to have different groups for the peer review assignment (or, for example, if students submitted work in groups, you can still have them complete peer reviews individually).

> 🗒️ **NOTE**: The reason you need to create two separate assignments is that MarkUs supports full "standard" grading for the work students submit for peer review.
> That is, in the assignment in Step 1, you can set up standard grading criteria, annotations, and automated tests just as you would for any other assignment.
> Then, you can have your students perform peer reviews of each other's work in a separate location in MarkUs, without interfering with this grading.

## Configuring your peer review assignment and assigning reviewers

After the peer review assignment has been set up, you may complete the following tasks to get it ready for your students to begin their reviews.

1. Optional setup for the peer review assignment:

    - Under the *Annotations* tab, you can set up pre-written annotations for your students to use when giving feedback.
    - Under the *Criteria* tab, you can set up scoring criteria for your students to fill in. You may choose to skip this step if you only want your students to provide written feedback, without any scoring.

        **Important**: when creating criteria for students to you, under each criterion's *Visibility* settings you should select "Make visible to peer reviewers" and deselect "Make visible to graders and instructors".

2. Wait until *after* the due date has passed for students to submit their work, and then collect their submissions in the *source assignment* (the first assignment you created in the above section).
3. Now in the peer review assignment, go to the "Assign Reviewers" tab.
    In this page, you can assign groups as *reviewers* for submissions that were collected.
    The interface for this page is similar to the page for [assigning graders](assigning-graders.md), except the additional option to select how many reviews each reviewer should be assigned.

    The typical workflow is to select *all* reviewer groups from the table on the left, then *all* groups to be reviewed from the table from the right, and then enter a number of reviews for each group to complete (e.g., 3), and then press "Randomly Assign Reviewers".

    > 🗒️ **NOTE**: when assigning reviewers, MarkUs will automatically ensure that no student is assigned to review their own submitted work.
    > You don't need to worry about preventing this yourself!
4. After all reviewers have been assigned, click on the "Peer Reviews" tab to view a table of all peer reviews.
    This is analogous to the assignment "Submissions" table for regular assignments, and you can use this table to track the progress of each peer review.

## Managing peer reviews and releasing feedback to students

Once you have assigned peer reviewers, your students can get started!

1. To let your students begin, make sure the peer review assignment is visible (on the *Settings* page).
    The *due date* of the peer review assignment is the date by which all peer reviews must be completed.
2. Make sure to tell students to mark their reviews as "Complete" as they work through them. You can track review progress on the assignment *Peer Reviews* tab.
3. After the due date has passed, you can then *release* the reviews to the students.
    To do so:

    1. Navigate to the *Peer Reviews* tab.
    2. In the table displaying the peer reviews, select the peer reviews you wish to release.
    3. Click on the "Release Marks" button. (You can undo this action by using the "Unrelease Marks" button later.)

## Upcoming features

In the future, MarkUs plans to support TA and instructor evaluation of the peer reviews for each reviewer (e.g., the quality of the feedback given, whether the reviewers followed specified instructions).
