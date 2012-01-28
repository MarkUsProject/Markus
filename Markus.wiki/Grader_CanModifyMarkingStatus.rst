================================================================================
Story Description
================================================================================

Initially a submission has status "unmarked". Once a Grader starts marking a
submission (assigns marks to some rubric), this status should change
automatically by the system to "partially marked". When the Grader thinks
she/he has finished marking a submission, the Grader should set the
"marking-status" manually to "marked". This way the instructor knows when all
submissions are marked.

Tests
--------------------------------------------------------------------------------

* Test if "marking-status" is "unmarked" up until a Grader starts marking a
submission * Test if "marking-status" changes automatically to "partially
marked" once some rubric of a submission is marked
