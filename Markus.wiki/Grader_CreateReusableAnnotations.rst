================================================================================
Story Description
================================================================================

In order to make life of an Grader easier, annotations can be reused. I.e.
while creating a comment it can be marked for reuse. When a comment is marked
"reusable" it will be stored in a common "annotations-pool". When creating a
new comment the Grader can either select a fitting comment from the "pool" or
create a new one. Reusable comments should **not** be deletable in any case.

Tests
--------------------------------------------------------------------------------

* Try to delete a reusable comment which a peer Grader or the instructor created
* Test if non-reusable comments don't show up in the reusable comments list

Questions
--------------------------------------------------------------------------------
* What if a Grader tries to get familiar with the system and creates a
reusable comment, without knowing that they will not be possible to delete?
Maybe make a reusable comment only deletable when no references to this
annotation exists or if the Grader is the "creator" of an annotaion?
