================================================================================
Questions about the MarkUs Schema (old as of September 14, 2009)
================================================================================

subversion of the submissions.
================================================================================

After a few researches and reflexion on the problem:

* it is possible to create an web interface for svn:

  * upload files into a temporary folder
  * commit the files uploaded --> create the submission, and the
    submission_files + launching a script to commit through svn.

Webdav uses this method to subversion files from a online tool

problems
================================================================================

This means we have one repository per group

1. Why does a Submission belong to an AssignmentFile?  (See
   app/models/submission.rb: 11)

   * AssignmentFile are files required by instructors. The link was used to
     verify that this requirement was fulfilled in the submissions. The
     direct link is however useless, as submissions are linked to assignment,
     through groupings, and assignment files, linked to assignments.

2. Why does SubmissionFile belong to user?

   *  Possible answer:  You want to know who uploaded which file, etc...

3. Why does Submission have a user_id property?  If its for a single user
   submission, why not just treat a single user as a group of 1?

   * Submissions has a user_id property to know who submitted what.
   * This link may disappear once we've figured out how to version the
     submissions ar the submissions files

4. Why is Submission_files not merged with Submissions?

   * submissions will be used to keep a version of files submitted, and to
     apply test on it.

5. Why is Result not merged with Submission?  What is the
   point/purpose/function of Result?

   * results has now been merged with grades.
   * results are linked to submissions, because they apply on one submission
   * results should not be versioned, so it is a one to one link

6. Should there be a grades_released boolean on Assignment?

   * No, but there should be a "select all results, and release them"

7. What is the relationship between Grade and Results?

   * Grade has now disapeared

8. Why is Grade not connected to Groupings instead of Groups?

   * Grade hase now disapeared

9. If Grade is a verb ("to grade", as opposed to "a grade"), can we come up
   with a better name for this model that is easier to understand for the next
   team?

   * Grade has now disapeared

10. What is the purpose of the "grade" and "timestamp" properties in the
    Grade model?

   * grade (probably) used to be the total results on the assignment for one
     person.
