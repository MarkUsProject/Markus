---
permalink: /instructors/assignments/assigning-graders/
title: Assigning Graders
parent: Assignments
grand_parent: Instructors
nav_order: 12
---
# Assigning Graders
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

## Graders Tab

The Graders tab can be used to assign graders to specific student groups and marking criteria. For assignments, both course graders and course instructors are available for assignment. Assigning an instructor can be useful for distributing and tracking marking work, but does not restrict the access they already have as an instructor.

For marks spreadsheets, graders can be assigned to individual students, but instructors are not included as assignable graders.

To assign a grader, navigate to the "Graders" tab by clicking on Assignments -> Graders:

![Graders Marks Spreadsheets](/images/graders-tab.png)

### Table Info

When you arrive at the "Manage Graders" page you will see a table of assignable graders. For assignments, this table contains both graders and instructors:

![Graders Table](/images/graders-graders-table.png)

- **User Name:** The username of the grader.
- **Name:** The full name of the grader.
- **Groups:** The number of student groups currently assigned to that grader for the assignment.

You will also see a table of student groups:

![Students Table](/images/graders-student-table.png)

- **Section:** The lecture section associated with the group, when sections are configured.
- **Group Name:** The name of the student group. For individual assignments, this is the student's username.
- **Graders:** The usernames of the graders currently assigned to that group.
- **Coverage:** When graders are assigned to individual criteria, the number of criteria covered by the group's assigned graders.

### Assigning

There are three actions you may perform when assigning or unassigning graders:

**1. Assign grader(s):** To perform this action you must select a grader from the grader table and at least one group from the groups table by clicking on their checkboxes. Then, click the "Assign grader(s)" button:

![Assign Graders](/images/graders-assign.png)

Once this is done, the name of the grader will appear in the "Graders" column of the selected groups:

![Assigned Grader](/images/graders-assigned.png)

**2. Randomly assign grader(s):** This does the same thing as "Assign grader(s)" but randomly distributes the selected groups. If multiple graders are selected, the randomizer assigns the groups as evenly as possible by default (for example, with 3 graders and 10 groups, the graders receive 3, 3, and 4 groups respectively).

Upon clicking the button, a modal will prompt you to assign a weighting to each grader. Once submitted, the randomizer assigns groups as close to the specified ratio as possible (for example, 3 graders and 10 groups with weightings 1, 2, and 0.33 should result in graders receiving approximately 3, 6, and 1 groups).

![Randomizer Modal](/images/assignment-randomizer-modal.png)

**3. Unassign grader(s):** This action unassigns graders that have already been assigned to groups. Select the groups and graders, then click the "Unassign grader(s)" button:

![Unassign Graders](/images/graders-unassign.png)

#### Assign to Criteria

Graders can also be assigned to mark individual criteria from the "Criteria" tab (not available for marks spreadsheets).

![Criteria](/images/graders-criteria.png)

For course graders, this limits editing to their assigned criteria. They can still see all marks for the group unless "Only show assigned criteria to graders" is selected as well. Course instructors retain access to all criteria; assigning criteria to an instructor records the marking allocation and contributes to coverage tracking.
