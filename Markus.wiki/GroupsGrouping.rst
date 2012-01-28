================================================================================
Group / Grouping Behaviour
================================================================================

.. contents::

What is the difference between a Group and a Grouping?
================================================================================

Groupings
--------------------------------------------------------------------------------

*A Grouping is a collection of students working on a single Assignment.*

A Grouping belongs to a Group, and an Assignment.  So, an Assignment has many
Groupings, and a Group has many Groupings.

Group
--------------------------------------------------------------------------------

In our schema, a group is really just a common name for a collection of
Groupings.  This is useful in courses that have student teams that persist
across all Assignments, since it becomes easier to "clone" groups forward to
the next Assignment.  It also decouples the official Group from the collection
of students that it represents.

For example,  say I am on Team A for an entire course.  My friends, Andrew,
Betty, and Chester, are also part of Team A.  We're supposed to be on the same
teams for the entire semester.

However, halfway through the course, it's clear that our team is working out.
Chester has dropped out, and Betty doesn't get along with Andrew.

Since Chester has dropped out, when the Groupings are cloned forward from
Groups, he is not included in those Groupings.  However, his existence in the
previous Groupings (before his drop out) are still recorded in the database.

By team vote, Andrew has decided to switch to Team L.  The instructor for the
course clones the last Assignment forward, and then makes the changes to the
Groupings.

How Groups are Created
================================================================================

When a Grouping is created, it has to be assigned to a Group.  If the Grouping
attempts to point at a Group that doesn't exist, that Group is created.  It's
essentially a "find_or_create_by" kind of action.

How Groupings are Created
================================================================================

Depending on the Assignment settings, Groupings can be either formed by
Students themselves, or formed by the course instructor.

No matter what, the course instructor has full control over all Groupings, and
can add/remove Students from any Grouping that they see fit.

Groupings Created by Students
--------------------------------------------------------------------------------

When an Assignment is created, it has the option of allowing Students to form
their own Groupings/Groups.

Optional Groupings (Group size minimum == 1)
********************************************************************************

An Assignment called A1 is created by an Instructor.  Student A logs in, and
chooses to work on A1.  Student A is then asked whether or not he wants to
work in a Group for this Assignment, or work alone.

Working Alone
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If Student A chooses to work alone, a Grouping is created for A1, attached to
Student A's home Group (which is named by Student A's user_name).  After
choosing to work alone, Student A cannot invite anyone to work with him.

Since the Group size minimum on this Assignment == 1, Student A's Grouping is
immediately valid.

Working with Others
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If, however, Student A chooses to work with other students (Students B and C),
he can invite them to his Grouping (Student A now has the 'inviter' status to
his Group, and Students B and C have 'pending' status).  Student A can then
begin submitting files for A1 immediately.

When Student B logs in, she will see that she has been invited to Student A's
Group.  She will be asked whether or not to join, or to refuse the offer.  If
she joins, then her StudentMembership in Student A's Grouping is changed to
'accepted'.

When Student C logs in, she will see that she has also been invited to Student
A's Group.  Like B, she will be asked whether or not to join.  If Student C
refuses, her StudentMembership in Student A's Grouping is changed to
'rejected' (but the StudentMembership still exists!).  

Student A should be able to see the accepted, pending, and rejected
StudentMembers of his Group.  

Student B should only be able to see the accepted StudentMembers, and not the
pending, or rejected ones.

Student C now has the option of creating her own Group.  She may also have
been invited to someone else's Group, where (again) she can choose whether or
not to join.

Mandatory Groupings (Group size minimum > 1)
********************************************************************************

An Assignment called A1 is created by an Instructor with a Group size minimum
of 3.  Student A logs in, and chooses to work on A1.  Student A is then asked
to invite Students to his Group.  He does not have the option of working
alone.

Student A invites two other students - Students B and C.  Student A now has
the 'inviter' status to his Group, and Students B and C have 'pending' status.
Student A can then begin submitting files for A1 immediately - his Grouping is
"valid" because his Groupings membership count is greater than the group size
minimum, even though B and C have not necessarily accepted his invitation.

When Student B logs in, she will see that she has been invited to Student A's
Group.  She will be asked whether or not to join, or to refuse the offer.  If
she joins, then her StudentMembership in Student A's Grouping is changed to
'accepted'.  She can then read/write to the Group repository for this
assignment.

When Student C logs in, she will see that she has also been invited to Student
A's Group.  Like B, she will be asked whether or not to join.  If Student C
refuses, her StudentMembership in Student A's Grouping is changed to
'rejected' (but the StudentMembership still exists!).  

Student A should be able to see the accepted, pending, and rejected
StudentMembers of his Group.  

Student B should only be able to see the accepted StudentMembers, and not the
pending, or rejected ones.

Student C now has the option of creating her own Group.  She may also have
been invited to someone else's Group, where (again) she can choose whether or
not to join.

Student A and B are now in a bit of a bind.  Their Grouping is no longer
valid.  They have the ability to read files from their repository, but their
write permissions will no longer work.

As the Grouping inviter, Student A now has a choice.  He can either invite
another Student to his Grouping (which would make it valid again), or he can
choose to break up the Grouping.  If he breaks up the Grouping, the Grouping
is destroyed, and all original members of that Grouping are back to square one
- having to either be invited to a Grouping, or create a Grouping.

Of course, the instructor always has the option of taking a Grouping that is
"invalid" and making it "valid", regardless of the Grouping size.
