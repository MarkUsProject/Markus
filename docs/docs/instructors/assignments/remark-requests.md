---
permalink: /instructors/assignments/remark-requests/
title: Remark Requests
parent: Assignments
grand_parent: Instructors
nav_order: 9
---
# Remark Requests

## Table of Contents

- [Viewing Requests](#viewing-requests)
- [Responding to a Remark Request](#responding-to-a-remark-request)

## Viewing Requests

If remark requests are enabled for an assignment, a student may [submit a request](../../students/index.md) after the results have been released. Instructors may view submitted requests on the [submissions table](marking-set-up.md#marking-state) and may respond to remark requests from the [grading view](marking-grading-view.md).

## Responding to a Remark Request

The remark request can be viewd from the "Remark Request" tab of on the Grading View page.

![Remark Request Tab](/images/grade-view-remark-request-comments.png)

The request submission date as well as any notes provided by the student when making the request will be shown here.

The instructor may choose to submit overall comments on the request as well (markdown and latex markup is supported).

### Remarking

If you wish to change the marks for this student you may [update the marks as normal](marking-grading-view.md#marks) on the "Marks" tab. You may also add new annotations as normal.

> 🗒️ **NOTE**: When adding new [deductive annotations](deductive-annotations.md) to a remark, the marks **will not** be updated automatically. Marks will need to be manually adjusted as needed.
>
> The "Revert to automatic deductions" action for a mark will take into account these new annotations as follows:
>
> - If no new deductive annotations for the mark have been added, the mark will be calculated based on the deductive annotations from the original result.
> - If at least one deductive annotation for the mark has been added, the mark will be calculated based on the deductive annotations for the remark, *ignoring* any deductive annotations from the original result.

Once the marks have been updated, click the "Set to Complete" and "Release Marks" buttons as normal to release the updated marks back to the student.

Both the previous and updated marks should be visible:

![Marks with Remark](/images/grade-view-marks-with-remark.png)
