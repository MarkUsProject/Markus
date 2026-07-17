---
permalink: /technical-guides/learning-tools-interoperability/
title: Learning Tools Interoperability
parent: Technical Guides
nav_order: 2
---
# Learning Tools Interoperability (LTI)
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

>**Note**: LTI functionality is not enabled by default, and must be enabled by a system administrator.

MarkUs integrates with other Learning Management Systems (LMS) via the [LTI 1.3 standard](https://www.imsglobal.org/spec/lti/v1p3).
Currently, MarkUs supports the following LMS platforms:

- Canvas

## For LMS Administrators

### Installing MarkUs on an LMS

Each LMS implements their own LTI integration process.
Typically, only administrators can add LTI integrations.

### Canvas

To add MarkUs to a Canvas instance, see their page on
[configuring LTI keys](https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-LTI-key-for-an-account/ta-p/140).

MarkUs can be added via a JSON URL, as described in the 'Enter JSON URL' section of the documentation. MarkUs provides the configuration at  `/lti_deployments/get_canvas_config`

## For Instructors

## LTI settings

After connecting a MarkUs course with an LMS course (see below for platform specific instructions),
the associations can be viewed on the Course Settings page. On this page you can manually trigger a roster synchronization,
and also choose to delete an association between the LMS and MarkUs.

![LTI Course Settings](/images/lti-course-settings.png)

> **NOTE:**
> Destroying an LTI association will also destroy any LTI assignment settings on MarkUs.
> However, it will *not* destroy any data that has been sent from MarkUs to the LMS.
> If an association is reestablished, any assignment's LTI settings must be re-created,
> and will create *new* LMS gradebook items.

### Roster Synchronization

When triggering a roster synchronization, you can choose which types of users are synchronized.
Additionally, if 'Enable automatic syncing' is checked, MarkUs will attempt to synchronize the roster automatically
on a schedule determined by your system administrator.

![LTI Synchronization Options](/images/lti-roster-sync.png)

### Canvas

Once installed in your course, a 'Launch Markus' page will appear in your
course's navigation (disabled by default), and needs to be added to the navigation:

![Canvas MarkUs Navigation](/images/canvas-markus-nav.png)

If you believe MarkUs should be installed in your course, but it does not appear,
contact your Canvas administrators.

> **NOTE:**
> The additional navigation item will only be visible to instructors and
> administrators (not students).

#### Associating your Canvas Course with your MarkUs course

Once MarkUs is configured with Canvas, an association between your
Canvas course and your MarkUs course must be made.
Click 'Launch MarkUs' in your Canvas course. If you are not logged in to MarkUs,
you will be prompted to do so. Once you are logged in, you will be presented with
a list of MarkUs courses for which you are an instructor. Select the course that matches your Canvas
course and submit the form.

![MarkUs Link Canvas Course](/images/lti-link-course.png)

If your course does not appear in the list,
you may click 'Create New Course', to request a new
course based on the Canvas course information with you as an instructor.

*Warning*: your system administrator may restrict which Canvas courses can trigger the creation of a new course on MarkUs.

#### Creating a Grade Book entry for a MarkUs Assignment

Once a course association has been established, each assignment will
have an option to create an associated entry in the Canvas course. This will allow grades from a MarkUs assignment
to be sent to the associated LMS once grading is complete.
On the assignment's LTI Settings page, simply check the box for each
Canvas instance where a gradebook item should be created, and click the save button.

#### Sending grades from MarkUs to the LMS

If an assignment has an LMS grade book entry, the assignment
summary page will have a 'Sync Grades to LMS' button.

![LTI Grade Sync](/images/lti-grades-sync.png)

Clicking on this button will open a modal with a checkbox for each
associated LMS course. Check the box for each Canvas course the grades should be synced to.

>**Note**: Only grades in the *released* state will be synced.

#### Syncing Canvas course roster with MarkUs

MarkUs will automatically attempt to sync course rosters, including both students and graders, with Canvas when grades are sent to Canvas.
Any members of the Canvas course that are not present in the MarkUs course roster will be created.
A roster sync can also be triggered manually on the Course Settings page.
