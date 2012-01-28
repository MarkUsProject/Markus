================================================================================
Submission Rules
================================================================================

Each Assignment must have a SubmissionRule attached to it.  A SubmissionRule
is a set of instructions or conventions that MarkUs will follow for dealing
with possible grace days for late assignments, penalties for late assignments,
etc.

A SubmissionRule only comes into effect for late submissions.

No Late Submissions Rule (currently called NullSubmissionRule - see <ticket:236>)
=================================================================================

* No Late Submissions are going to be automatically accepted/considered -
 anything submitted late will be ignored

* No penalties are automatically added, since no late submissions will be
  accepted/considered

* The collection date is the due date

Grace Period Submissions Rule
================================================================================

* Each Student has an assigned number of available grace period "credits"

* For Groups of students, the number of available grace period "credits" is
  the minimum of the "credits" available to each Student member.

* An Assignment has a certain number of grace periods, where the first period
  is X number of hours after the due date, the second is Y number of hours
  after the first period, etc.  The number of periods is arbitrary.

* Collection date is the due date plus the number of hours of all grace
  periods

* When Submissions are collected on the collection date, this Rule should
  examine the timestamp of the Submission, and classify it in the appropriate
  grace period.

* Submissions with timestamps before the due_date are returned untouched

* Submissions with timestamps within a grace period will only deduct grace
  credits if the calculated number of credits to be deducted is less than or
  equal to the number of credits available to the grouping.

* For any grace deductions that are calculated that are greater than the
  grace credits available to a Grouping, that Submission will not be
  graded.  In this case, the Submission rule should replace the Submission
  for that Grouping with a new Submission from the timestamp of the last
  point where they had credits. 

* For any grace deductions that are calculated that are less than or equal
  to the number of grace credits available to a Grouping, a
  GracePeriodDeduction is recorded for each member of that grouping.

Penalty Period Submissions Rule
================================================================================

* An Assignment has a certain number of penalty periods, where the first
  period is X number of hours after the due date, the second is Y number of
  hours after the first period, etc.  The number of periods is arbitrary.
  Each hour has a "deduction" amount, and possibly a deduction unit (marks vs.
  percent).

* Collection date is the due date plus the number of hours of all penalty
  periods

* When Submissions are collected on the collection date, this Rule should
  examine the timestamp of the Submission, and classify it in the appropriate
  penalty period.

* Submissions with timestamps before the due_date are returned untouched.

* Submissions with timestamps within a penalty period will have ExtraMarks
  automatically attached to the Submission Result that deduct the appropriate
  amount of marks (or percentage) from the final Result.  These ExtraMarks can
 be removed by the Grader if necessary.

