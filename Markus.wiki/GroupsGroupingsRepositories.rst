================================================================================
Groups/ Groupings Repositories
================================================================================

There are two models that we are trying to accommodate.

Model 1:  Assignments are independent of one another - so one assignment does
not build on top of any other.

Model 2:  Assignments progress, so that A1 is a snapshot of work, A2 is a
snapshot of work built on top of what was done in A1, etc.  Question:  How do
we know what to mark?  Should we filter by which files changed between
revisions?  Should the instructor specify what files will be marked with
AssignmentFiles?

Courses can use either Model 1, Model 2, or a combination of both for
Assignments.

There exists 1 repository per Group.  OLM will keep track of the repository
locations in the Groupings model.  Why?  This will make it so that we can
satisfy Model 2 - if a Grouping is cloned forward for a new Assignment, that
Grouping can keep working with the same repository.

Group names are auto-generated if Groupings are created by Students.

Only instructors can set the names of Groups.

If names of Groups change, the repository names do not change.

Say there are two Assignments.  A1 is due on March 15th.  A2 is created and
available to the students on March 10th.  Student S1 and S2 are part of a
Grouping G1 for A1 and G2 for A2.  When S2's Membership is removed from G2,
they are removed from G1 as well **only if** the Assignment due date for A1
has not yet passed.  This removal is only triggered by the Instructor, and
happens only if S2 is not supposed to work in G1 any more for A1.  If the
Instructor removes S2, OLM should warn the Instructor that S2 will no longer
be able to commit for A1 anymore.

In the event that S2 is being removed from G2 after A1's due date has passed,
S2's Membership will only be removed from G2, not from G1.

When Assignments are overlapping, G1 should equal to G2 during the time of
overlap.  

Repositories are created when Groups are formed, and Groups are created when
Groupings are formed. ..??

Groupings are formed once the list of Students for a course has been entered,
and an Assignment has been created.  

Case:  I've set this Assignment to not allow Groups/Groupings (or, rather,
each Student is working alone with a single Grouping/Group).  At the point
when the Students list exist, and this Assignment is created, Groupings/Groups
will be formed, and repositories will be created automatically.


