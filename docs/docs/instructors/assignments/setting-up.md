---
permalink: /instructors/assignments/setting-up/
title: Setting Up
parent: Assignments
grand_parent: Instructors
nav_order: 1
---
# Setting Up an Assignment
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

## Initial Setup

To create a new assignment navigate to the "Assignments" tab at the top of the MarkUs website.

![Website Create Assignment](/images/assignment-tab.png)

Click on the "Create Assignment" button under Manage Course Work.

![Create Assignment](/images/create-assignment-button.png)

You will be taken to the initial set-up page for an assignment on MarkUs. From this page you will be able to create and edit a new assignment for your class.

### Properties

This section allows you to set the name and due date for the assignment as well as enable (or disable) a few features you would like your assignment to have. All properties except for the Short Identifier may be changed after creation.

![Properties](/images/assignment-creation-properties-field.png)

**1. Short Identifier**: This is the title that will be used in MarkUs menus and will be the default repository name. Because it is used as a directory name, ensure that it does not contain any spaces.
**2. Assignment description**: This is the longer, more descriptive name of the assignment used as its full title.
**3. Message**: This section allows you to include any additional information the students may need to know about the assignment.
**4. Due Date**: This section lets you set the due date for the assignment. You are able to configure the time (down to the minute) at which you would like the assignment to be due. The due date will be visible to students when they view the assignment. Note that the due date may be changed later on (ex/ to accommodate class-wide extensions). Changing the due date after submissions have been collected will not affect submitted assignments.

**5. Visibility:** Controls when students can see the assignment:

- **Hidden**: Students cannot see this assignment
- **Visible**: Students can always see this assignment
- **Visible on/until**: Assignment is only visible between specified start and end datetimes

**6. Section-Specific Settings:** Checking the "Enable section specific settings" box will allow you to set different due dates and visibility settings for different lecture sections. Each section can override the default due date and visibility settings.
> 🗒️ **NOTE:** Students not assigned to any section will only be allowed to form groups with other students not assigned to any section.

**7. Check boxes:** The rest of this section includes check boxes that may be selected or deselected depending on your preferences. Note that in order for students to submit online, the "Allow students to submit through the web interface" box must be checked. If you prefer students to submit through a version control system, then uncheck the "web interface" box and select "version control system".

If you wish to allow students to submit URLs check the "Allow students to submit URLs" box. This is especially useful if you plan on requiring students to submit videos or large files since preview support is available for content from YouTube and Google Drive/Docs.
> 🗒️ **NOTE:**
> MarkUs does not check the "last modified time" of the target of a submitted URL. It is possible for students to submit a URL before the deadline, but change the target's contents after the deadline (e.g., by modifying the contents of a Google Doc).

If you want to give students the ability to submit through the MarkUs API, you can check the "Allow students to submit through the MarkUs API" box. This is necessary if you plan on creating or using an external plugin that allows students to submit assignments such as the MarkUs Jupyter Extension.

If you want to prevent students from automatically being able to view released marks select the "Only allow students to view released marks via a unique URL" box. Once you release the marks for this assignment, you can generate a unique token for each student. The student will need to enter this token in order to view the results.
> 🗒️ **NOTE:**
> These tokens can be expired so this is a good way to make results available to students only by request and only for a specific period of time.

Please see the [Peer Review](peer-review.md) page for more information on Peer Review.

### Required Files

This section will allow you to specify the names of files that students will be required to submit:

![Website Required Files](/images/assignment-required-files.png)

- You may add a required file by clicking on the "Add a Required File" link and specifying a name.
- You may add as many required files as you need and may also delete specific files by clicking the "Delete" link next to the file you'd like to remove.
- If you want your required file to be of a specific type (ex/ a text file, an image, etc.), then that may be specified by adding the file's type extension at the end of the name.
- If you want students to only be able to submit files with the correct file names and extension types, then select the "Only allow students to submit the required files" checkbox. When this is checked, students will see a warning message and will be unable to submit files that do not match the required names and types.

### Group Properties

This section allows you to enable and configure settings for students to work in a group:

![Website Group Properties](/images/assignment-group-properties.png)

- If this is the first assignment (or the first assignment with group work) then the "Students can work in groups" box must be selected to allow groups to be formed on MarkUs. Once checked, it will open up a new box with further settings. These settings include a "Students may form their own group" box which will allow students to create and invite other students to their group.
- You may specify a minimum and maximum number of students per group.
- Group names are always auto-generated if students are forming their own groups.
- You can create groups manually or by uploading a file in the "Groups" tab once an assignment has been created (please see the "[Managing Group Members](../groups/index.md)" page for more information).

- If the "Persist groups from previous assignment" box is selected, then a previous assignment must be selected from the drop down list. This list is automatically populated from any previously created assignments for the course. Checking this option will allow you to use the same groups and group repositories from previous assignments. See the "[Managing Group Repositories](../groups/index.md)" page for more information.

- If you would like to see what students need to do to form their own groups once you have configured all the settings, please see the "[How Students Form Groups](../../students/index.md)" page.

### Late Submission Policy

By default, no submissions after the assignment deadline are collected for grading.
However, MarkUs supports a few different late submission policies, which you can read about in [Late Submission Policies](late-submission-policies.md).

### Re-mark Requests

This section lets you choose if you wish to allow re-mark requests. If you do, then a re-mark request due date may be specified by choosing a date from the drop down calendar. Specific instructions for the students may also be included in the "Remark Request Instructions" section.

![Website Remark Requests](/images/assignment-remark-requests.png)

### Saving Changes

Once all the required fields are completed (along with any other fields you choose to fill out), click the `Submit` button at the bottom of the change to create the assignment.

If an assignment is created in error or you wish to delete an assignment, this can be done by navigating to the "Properties" tab of the assignment you wish to delete and checking the "Hide assignment from students" box:

![Website Deleting Assignment](/images/assignments-hide-checkbox.png)

Although this does not delete the assignment from your dashboard, it does remove it from all of the student accounts. Students will neither be able to see nor access deleted assignments.

## What Students Will See

To get an idea of what an assignment looks like from the student's perspective check out [this page](../student-view.md)!

## Modifying an Assignment After Creation

Once an assignment has been created, you are still allowed to modify most of the fields from the "Create Assignment" page that you just filled out. This can be done by navigating to the "Assignments" (1) tab, clicking on the assignment you wish to modify, and then clicking on the "Settings" (2) and then "Properties" (3) tabs:

![Website Edit Assignment](/images/website-edit-assignment.png)

All the fields on this page are the same as the ones from the "Create Assignment" section.

## Uploading and Downloading an Existing Assignment

If you wish to save and/or transfer your settings for an existing assignment for future use, you can download a zip file of the assignment which you can later upload back to MarkUs. This is useful if you wish to reuse a specific assignment in a future offering of a course.

To download an assignment, go to an assignment's properties page and click on the "Download" link in the top right corner.

![Assignment Download Link](/images/assignment-download-link.png)

This will download an assignment zip file you can save and upload back later. For more information on this zip file and what settings are saved, please see the section on [importing and exporting assignment configurations](../importing-and-exporting-data.md#assignment-configuration).

In order to upload an assignment zip file, navigate to the "Assignments" tab at the top of the page and click on the "Upload Configuration Zip File" link in the top right corner.

![Assignment Upload Link](/images/assignment-upload-link.png)

This will show you a modal where you can select an assignment zip file to upload.

![Assignment Upload Modal](/images/assignment-upload-modal.png)

After you have selected a zip file to upload, MarkUs will then create a new assignment using the settings specified within the zip file.
