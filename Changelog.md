# Changelog

## [v1.9.4]
- Fixed bug where bonuses and deductions were not displayed properly (#4699)
- Fixed bug where image annotations did not stay fixed relative to the image (#4706)
- Fixed bug where image annotations did not load properly (#4706)

## [v1.9.3]
- Fixed inverse association bug with assignments (#4551)
- Fixed bug preventing graders from downloading submission files from multiple students (#4658)
- Fixed bug preventing downloading all submission files from git repo (#4658)

## [v1.9.2]
- Fixed bug preventing all git hooks from being run in production (#4594)
- Fixed bug preventing folders from being deleted in file managers (#4605)
- Added support for displaying .heic and .heif files in the file viewer (#4607)
- Fixed bug preventing students from running tests and viewing student-run test settings properly (#4616)
- Fixed a bug preventing graders viewing the submissions page if they had specific criteria assigned to them (#4617)

## [v1.9.1]
- Fixed bug where the output column was not shown in the test results table if the first row had no output (#4537)
- Fixed N+1 queries in Assignment repo list methods (#4543)
- Fixed submission download_repo_list file extension (#4543)
- Fixed bug preventing creation of assignments with submission rules (#4557)

## [v1.9.0]
- Added option to anonymize group membership when viewed by graders (#4331)
- Added option to only display assigned criteria to graders as opposed to showing unassigned criteria but making them
  ungradeable (#4331)
- Fixed bug where criteria were not expanded for grading (to both Admins and TAs) (#4380)
- Updated development docker image to connect to the development autotester docker image (#4389)
- Fixed bug where annotations were not removed when switching between PDF submission files (#4387)
- Fixed bug where annotations disappeared on window resize (#4387)
- Removed automatic saving of changes on the Autotesting Framework page and warn when redirecting instead (#4394)
- Added progress message when uploading changes on Automated Testing tab (#4395) 
- Fixed bug where the error message is appearing when the instructor is trying to collect the submission of the student 
  who hasn't submitted anything (#4373)
- Ignore the "Total" column when uploading a csv file to a grade entry form. This makes the upload and download format
  for the csv file consistent (#4425)
- Added git hook to limit the maximum file size committed and/or pushed to a git repository (#4421)
- Display newlines properly in flash messages (#4443)
- Api calls will now return the 'hidden' status of users when accessing user data (#4445)
- Make bulk submission file downloads a background job (#4463)
- Added option to download all test script files in the UI and through the API (#4494)
- Added syntax highlighting support for .tex files (#4505)
- Fixed annotation Markdown and MathJax rendering bug (#4506) 
- Fixed bug where a grouping could be created even when the assignment subdirectory failed to be created (#4516)
- Progress messages for background jobs now are hidden once the job is completed (#4519)
- Fixed bug where a javascript submission/test/starter code file can't be downloaded (#4520) 
- Add ability to upload and download autotest settings as a json file/string through the UI and API (#4498)

## [v1.8.4]
- Fixed bug where test output was not being properly hidden from students (#4379)
- Fixed bug where certain fonts were not rendered properly using pdfjs (#4382)

## [v1.8.3]
- Fixed bug where grace credits were not displayed to Graders viewing the submissions table (#4332)
- Fixed filtering and sorting of grace credit column in students table. (#4327)
- Added feature to set multiple submissions to in/complete from the submissions table (#4336)
- Update pdfjs version and integrate with webpacker. (#4362)
- Fixed bug where tags could not be uploaded from a csv file (#4368)
- Fixed bug where marks were not being scaled properly after an update to a criterion's max_mark (#4369)
- Fixed bug where grade entry students were not being created if new students were created by csv upload (#4371)
- Fixed bug where the student interface page wasn't rendered if creating a single student grouping at the same time (#4372)

## [v1.8.2]
- Fixed bug where all non-empty rows in a downloaded marks spreadsheet csv file were aligned to the left. (#4290)
- Updated the Changelog format. (#4292)
- Fix displayed number of graded assignments being larger than total allocated for TAs. (#4297)

## [v1.0.0 - v1.8.1]
### Notes
- Due to a lapse in using the release system and this changelog, we do not have a detailed description of changes
- Future releases will continue to update this changelog
- For all changes since 1.0.0 release see: https://github.com/MarkUsProject/Markus/pulls?q=is%3Apr+created%3A2014-02-15..2019-12-11+is%3Aclosed

## [v1.0.0]
- Using Rails to 3.0.x
- Add Support for Ruby 1.9.x
- Issue #1002: new REST API
- Fixed UI bugs
- Improved filename sanitization.
- Changed PDF conversion to Ghostscript for faster conversion
- Issue #1135: start to migrate from Prototype to jQuery
- Issue #1111: grader can dowload all files of a submission
- Issue #1073: possibility to import and export assignments
- Several improvements on sections
- Syntax Highlighter is now working with non utf-8 files
- Tests are not using fixtures anymore
### Notes
- For a list of all fixed issues see: https://github.com/MarkUsProject/Markus/issues?milestone=8

## [v0.10.0]
- Use of Bundler to manage Gems dependencies.
- Fixed UI bugs (marking state, released checkbox).
- Fixed bug with javascript cache.
- Fixed bug when uploading the same file twice.
- Improved filename sanitization.
- Added Review Board API scripts (developers only).
- Added Remark Request feature.
- Issue #355: Marking state icon on Submissions page is shifted.
- Issue #341: File name sanitation does not sanitize enough problematic
  characters.
- Issue #321: Detailed CSV download for Flexible Grading Scheme is broken.
- Issue #306: Added Role Switching.
- Issue #302: Submit Remark Request Button should not be enabled/disabled, but
  should stay always on.
- Issue #294: rake load:results not creating assignment_stat/ta_stat
  associations.
- Issue #233: MySQL database issue with grade_distribution_percentage.
- Issue #200: Students have no UI for accessing their test results.
- Issue #199: Select all submissions for release is broken when student spread
  across multiple pages.
- Issue #189: MarkusLogger needs to be adapted so that log files are unique to
  each mongrel.
- Issue #156: Adding an extra mark doesn't show up until navigating away from
  the page.
- Issue #151: REST api request to add users.
- Issue #122: Annotations with hex escape patterns stripped.
- Issue #107: Non-active students don't show up with the default "All" filter
  during initialization.
- Issue #6: Results should not be able to be marked "complete" if one or more
  of the criteria aren't filled in.
- Issue #3: Diplaying server's time on student view.

## [v0.9.5]
- Fixed bug which prohibited removal of required assignment
  files.

## [v0.9.4]
- Fixed releasing and unreleasing marks for students using
  select-all-across-pages feature in the submissions table.

## [v0.9.3]
- Added UI for students to view their test results.

## [v0.9.2]
- Issue #180: Infinite redirect loop caused by duplicate group records in the
  database in turn possibly caused by races in a multi-mongrels-setup.
  (commits: 6552f28bf7, 19933b7f65, e39c542a4d, c226371823, ac0e348bb6,
  3cee403b9d)
- Issue #158: Default for Students page shows all Students, and bulk actions
  renamed. (commit: 1e13630914)
- Issue #143: Fixing penalty calculation for PenaltyPeriodSubmissionRule.
  (commit: 537d6c3068)
- Issue #141: Fix replace file JavaScript check (commits: 7f395605a8,
  e8150454b3)
- Issue #129: Uploaded criteria ordering preserved for flexible and rubric
  criteria (commit: b76a9a896f)
- Issues #34, #133: Don't use i18n for MarkusLogger and
  ensure_config_helper.rb (commits: a00a41e1a6, f652c919ed)
- Issue #693: Fixing confirm dialog for cloning groups (commit: 87e4d826f0)
- Issue #691: Adding Grace Credits using the bulk actions gets stuck
  in "processing" (commit: e0f78dd873)
- Fixed INSTALL file due to switch to Github (commits: cfd72b09bb, c0bc922434)
- I18n fixes (commits: bc791a4f21, 232384e05a, 8e2fcb6d61, 95c27db874)

## [v0.9.1]
- Submission collection problem due to erroneous eager loading
  expression (commit: a1d380b60e).

## [v0.9.0]
- Multiple bug fixes
- REMOTE_USER authentication support
- Redesigned manage groups and graders pages
- Added in-browser pdf display and annotation
- New batch submission collection
- Improved loading speed of submissions table
- Added ability to assign graders to individual criteria

## [v0.8.0]
- Using Rails 2.3.8
- MarkUs renders a 404 page error for mismatching routes
- Bug fixes on submission dates and grace period credits
- Python and Ruby Scripts using MarkUs API (see lib/tools)
- Displaying and annotating images
 A lot of accessibility features have been implemented :
	* Missing labels & Better focus on forms
	* Adding annotations in downloaded code from students repository
	* Re-arrange criteria using keyboard
- MarkUs is now completely internationalized
- Added new translation : french

## [v0.7.1]
- Bugfix for svn permissions with web submissions

## [v0.7.0]
- The notes system has been polished, and users can now add notes to groups, students, and submissions.
- Added the flexible criterion marking scheme type
- Added the marks spreadsheet feature
- The table of student submissions can now be bookmarked, and the back-button works correctly
- Minor bugfixes and usability fixes.

## [v0.6.3]
- Added rake task to automatically regenerate svn_authz in the event of corruption
- MarkUs now ensures student read/write permissions on repositories after cloning groups

## [v0.6.2]
- For now, students who work alone do not have their repositories named after them
- "Allow Web Submits?" in Assignment Properties page defaults to REPOSITORY_EXTERNAL_SUBMITS_ONLY setting now
- Annotation Category dropdowns no longer close prematurely on mouseover-ing a tooltip
- Added "Reset Mark" capability to grader view

## [v0.6.1]
- Fixed trace on detailed CSV download for assignments (g9jerboa)
- Random TA assignment now applies only to selected groups (rburke)
- Next/Previous Submission links in grader view no longer skip submissions marked "completed" (c6conley)
- The student edit form now accepts input properly
- New UI in students editor and grader view to manage grace credit penalties
- Functional tests now all pass (c6conley)

## [v0.6.0]
- Submissions table is now paginated (c6conley)
- It is now possible to push test results into MarkUs using the new REST API
  (g9jerboa)
- TAs and Instructors can exchange notes via MarkUs now (tlclark, fgarces)
- Student is able to delete groups when there are no submitted files and the
  studend is the inviter (g9jerboa)
- Subversion repositories are named after the Student's username, when students
  work alone for an assignment (g9jerboa)
- Rubric criteria boot in expanded form (c6conley)
- Warning is given, when AJAX calls are working and grader navigates away from
  Grader View (c6conley)
- MarkUs logs basic user actions (g9jerboa)


## [<= v0.5.10]
- MarkUs 0.5.10 corresponds to revision 1118 in release_0.5 branch (g9jerboa)
- Pump MARKUS_VERSION patch level to 10 (version is now 0.5.10) (g9jerboa)
- Added changelog file (g9jerboa)
- Changed has_submission? in grouping.rb to get rid of "dirty" records
  (g9jerboa)
- Removed application of submission rule when manually collect submissions
  (g9jerboa)
- Fixed Grader View bug when encountering binary files (g9jerboa)
- Fixed Submission's NoMethodErrors (fgarces)
- Closed CSRF bug of login screen (c6conley)
- Fix bug regarding Python docstrings in syntax highlighter (g9jerboa)
- Fixing bug that didn't highlight C code properly for students (c6conley)
- change $REPOSITORY_SVN_AUTHZ_FILE to REPOSITORY_PERMISSION_FILE in rake
  task (g9jerboa)
- Use bulk permissions when creating a new Group (c6conley)
- Added bulk permission controls to Repository library (c6conley)
- Fixed GracePeriodSubmissionRule when students have 0 grace credits
  (c6conley)
- Fixed typo in I18n variable (c6conley)
- Closed #419 - stack trace when downloading Subversion Export File (c6conley)
- Warnings are now given when assignments have due dates in the past
  (c6conley)
- Changed/updated next/prev link behaviour (c6conley)
- Fixed annotation_category bug, and average calculation bug (c6conley)
- Closing #402 (c6conley)
- Add version and patch level information to MarkUs (g9jerboa)
