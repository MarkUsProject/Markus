---
permalink: /instructors/assignments/grades/
title: Grades Summary
parent: Assignments
grand_parent: Instructors
nav_order: 13
---
# Grades
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

## Grades Tab

The grades tab can be used to view/visualize a variety of general statistics for a particular assignment. In addition, you may also view a summary of the grade breakdown for each submission. These are highlighted below.

### Summary Table

After visiting the Grades tab, you will first see the summary table. This table gives a summarized grade breakdown for each student/submission. Each row in the table corresponds to a particular submission group. For each row you can view the name of the submission group, its marking state, any tags the submission may have, a total mark for the submission, and finally a mark breakdown of the submission from associated criteria.

Instructors and graders with the **Manage submissions** permission can use the **Display assigned submissions only** checkbox to switch between all submissions and only the submissions assigned to them. The checkbox is cleared by default for instructors and selected by default for graders. Graders without this permission remain limited to their assigned submissions and do not see this control.

![Assignment Summary Table](/images/summary-table.png)

If you wish to download this table for offline use in a CSV format, select the "Download" button in the top right. Alternatively, if you ran tests on submissions and wish to download the results of those tests, you can click the "Download Test Results" button also found in the top right.

### Uploading Grades by CSV

The Grades tab can also be used to upload criterion marks from a CSV file. The easiest way to prepare the file is to first download the Grades CSV from the same tab, and then edit the criterion mark columns you wish to update.

To upload assignment grades:

1. Open the assignment and select the "Grades" tab.
2. Click "Download" to download the Grades CSV.
3. Edit the criterion mark columns in the CSV. Keep the exported "Group name" column in the file.
4. Click "Upload" in the Grades tab.
5. Choose the CSV file. If you want the upload to replace marks that have already been entered, check "Overwrite existing grades?".
6. Submit the upload and review the success and error messages shown by MarkUs.

When uploading:

- MarkUs matches rows by group name only. Student/user columns may be included in the file, but they are ignored.
- Only criterion mark columns are imported. The "Total Mark" and "Bonus/Deductions" columns are ignored.
- Criterion headers must match the exported criterion headers. Bonus criteria use the exported bonus header format, for example `Style (Bonus)`.
- By default, existing marks are not replaced. Existing marks are replaced only when "Overwrite existing grades?" is checked.
- Released results cannot be updated by upload. If you need to change released results, unrelease them before uploading.
- Rows with an invalid group name, unknown criterion header, invalid mark, negative mark, or mark above the criterion maximum will be reported as errors.

### Summary Statistics

Clicking on the "Summary Statistics" tab in the top left corner of the Grades page will take you to the summary statistics view. This view allows you to easily visualize and look at key statistics that summarizes overall student performance on the given assignment. This is an enlarged view of the summary statistics you can find on the dashboard.

#### Grades Distribution

In the top left section, you can see a chart that displays the distribution of grades for the given assignment.

![Assignment Grade Distribution Graph](/images/summary-stats-grade-distribution.png)

To the right of the grade distribution chart is a set of statistics that give a brief overview of student performance on the given assignment. Statistics that are currently shown are:

![Assignment Summary Overview](/images/summary-stats-overview.png)

- **Number of groups:** The number of groups created for this assignment. This is also the expected total number of submissions (assuming all groups have a submission).
- **Number of students in a group:** The number of students that are in a group out of all active students in the course.
- **Number of submissions collected:** The number of submissions that have been collected for marking out of the expected total number of submissions.
- **Number of submissions graded:** The number of submissions that have been collected and have recieved a mark out of the expected total number of submissions.
- **Average:** The average point grade of submissions for the given assignment (including submissions which recieved a zero) out of the maximum possible mark.
- **Median:** The median grade of submissions for the given assignment (including submissions which recieved a zero) out of the maximum possible mark.
- **Standard deviation:** The point grade standard deviation of submissions for the given assignment (including submissions which recieved a zero). In brackets next to this statistic is the standard deviation of submissions given as a percentage grade.
- **Number of fails:** How many graded submissions recieved a failing grade (i.e. recieved a grade under 50%) out of the expected total number of submissions.
- **Number of zeros:** How many graded submissions recieved a grade of zero out of the expected total number of submissions.
- **Remark requests completed:** How many remark requests have been completed out of the total number of remark requests recieved. This statistic will only show if you have enabled remark requests for the given assignment.

> 🗒️ **Note:** In brackets, next to each of the statistics that are shown as a fraction, is the same statistic fraction but displayed as a percentage instead.

#### Criteria Distribution

Below the grade distribution chart, you can further analyze the distribution of grades using the criteria distribution graph. This graph shows the distribution of marks given for each associated criterion.

![Criterion Grade Distribution Graph](/images/criteria-summary-stats-grade-distribution.png)

Each criterion corresponds to a colour shown in the labels just above the graph. By default, all grade data for criteria are hidden. In order to reveal the grade distribution for a specific criterion, simply click on the labels of all the criteria you wish to view and compare.

To help you get a quick overview of student performance for each criterion, next to the criteria distribution graph is a table that shows each criterion along with the average grade received for that criterion. Clicking on the drop down arrow next to each criterion will reveal additional summary statistics for that particular criterion.

![Criterion Grade Distribution Table](/images/criteria-summary-stats-table.png)

The additional criterion statistics currently shown are:

- **Average:** The average grade received for the given criterion.
- **Median:** The median grade received for the given criterion.
- **Standard deviation:** The point grade standard deviation for the given criterion. The percentage standard deviation for the given criterion is shown in brackets next to this statistic.
- **Number of zeros:** The number of submissions which recieved a grade of zero on the given criterion.

> 🗒️ **Note:** All statistics include submissions which have been marked as complete and have a grade for the given criterion. This includes submissions that received a mark of zero on the criterion. Submissions need not be released to students in order for them to be included in the statistics.

#### Grader Distribution

Finally, at the bottom of the view, below the criteria distribution chart, you can see another distribution of grades for an assignment. What differentiates this grade distribution chart from the normal chart at the top of the page however, is that this chart breaks down the normal grade distribution graph in order to also show the distribution of marks given by each grader.

![Assignment Grader Distribution Graph](/images/summary-stats-grader-distribution.png)

As with the criteria distribution, each grader corresponds to a colour shown in the labels just above the graph. Each label also shows how many submissions each grader has completed marking out of the number they were assigned.

To view a more discrete breakdown of each grader shown in the grader distribution graph, click on the "Graders" link in the bottom left corner of the grader distribution graph.

![Assignment Grader Distribution Link](/images/summary-stats-grader-distribution-breakdown-link.png)

This will take you to a page that shows several individual graphs showing the distribution of marks given by each grader.

![Assignment Grader Distribution Breakdown](/images/summary-stats-grader-distribution-breakdown.png)
