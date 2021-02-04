# Changelog
## [unreleased]
- Change 'Next' and 'Previous' submission button to use partial reloads (#5082)
- Add time zone validations (#5060)
- Add time zone to settings (#4938)
- Move configuration options to settings yaml files (#5061)
- Removed server_time information in submissions_controller.rb and server_time? from submission_policy.rb (#5071)
- Add rake tasks to un/archive all stateful files from a MarkUs instance (#5069)
- Fix bug where zip files with too many entries could not be uploaded (#5080)
- Add button to assignment's annotations tab to allow instructor to download one time annotations (#5088)
- Removed AssignmentStats table (#5089)
- Fix easyModal overlay bug (#5117)

## [v1.11.2]
- Fix bug where newlines were being added to files in zip archives (#5030)
- Fix bug where graders could be assigned to groups with empty submissions (#5031)
- Use Fullscreen API for grading in "fullscreen mode" (#5036)
- Render .ipynb submission files as html (#5032)
- Add option to view a binary file as plain text while grading (#5033)
- Fix bug where a remarked submission wasn't being shown in the course summary (#5063)
- Fix bug where the server user's api key was being regenerated after every test run creation (#5065)
- Fix bug where additional test tokens were added after every save (#5064)
- Fix bug where latex files were rendered with character escape sequences displayed (#5073)
- Fix bug where grader permission for creating annotations were not properly set (#5078)

## [v1.11.1]
- Fix bug where duplicate marks can get created because of concurrent requests (#5018)
- Only display latest results for each test group to students viewing results from an released assignment (#5013)
- Remove localization path parameter (#4985)

## [v1.11.0]
- Converts annotation modals from ERB into React (#4997)
- Refactor localization setting to settings page (#4996)
- Add admins to display name (#4994)
- Adds MathJax and Markdown support for remark requests (#4992)
- Use display name on top right corner (#4979)
- Add display name to settings (#4937)
- Create the required directory when uploading zip file with unzip is true (#4941)
- Remove preview of compressed archives in repo browser (#4920)
- Add singular annotation update feature when updating non-deductive categorized annotations (#4874)
- Replace Time.now and Time.zone.now with Time.current (#4896)
- Fix lingering annotation text displays when hovering (#4875)
- Add annotation completion to annotation modal (#4851)
- Introduce the ability to designate criteria as 'bonus' marks (#4804)
- Enable variable permissions for graders (#4601)
- UI for enable/disable variable permissions for graders (#4756)
- Image rotation tools added in marking UI (#4789)
- Image zooming tools added in marking UI (#4866)
- Fixed a bug preventing total marks from updating properly if one of the grades is nil (#4887)
- Group null/undefined values when sorting on dates using react-table (#4921)
- Add user settings page (#4922)
- Render .heic and .heif files properly in the file preview and feedback file views (#4926)
- Allow students to submit timed assessments after the collection date has passed even if they haven't started yet (#4935)
- No longer add starter files to group repositories when groupings are created (#4934)
- When starter files are updated, try to give students the updated version of the starter files they already have been assigned (#4934)
- Display an alert when students upload files without having downloaded the most up to date starter files first (#4934)
- Rename the parameter in get_file_info from id to assignment_id (#4936)
- Fix bug where maximum file size for an uploaded file was not enforced properly (#4939)
- Add counts of all/active/inactive students to students table (#4942)
- Allow feedback files to be updated by uploading a binary file object through the API (#4964)
- Fix a bug where some error messages reported by the API caused a json formatting error (#4964)
- Updated all authorization to use ActionPolicy (#4865)
- Fix bug where note creation form could be submitted before the form had finished updating (#4971)
- Move API key handling to user Settings page (#4967)
- Fix bug that prevented creation of scanned exams (#4968)
- Fix bug where subdirectories were not being created with the right path in the autotest file manager (#4969)
- Fix bug where penalty periods could have interval/hour values of zero (#4973)
- Add color theme settings (#4924)

## [v1.10.4]
- Fix bug where students could see average and median marks when the results had not been released yet (#4976)
- Add email and id_number to user information returned by get requests to api user routes (#4974)

## [v1.10.3]
- Allow for more concurrent access to git repositories (#4895)
- Fixed calculation bugs for grade summary (#4899)
- Fixed a bug where due dates in a flash message were incorrect for timed assessments (#4915)
- Allowed the difference between the start and end times of a timed assessment to be less than the duration (#4915)
- Fixed bug where negative total marks may be displayed when a negative extra mark exists (#4925)

## [v1.10.2]
- Ensure that assignment subdirectories in repositories are maintained (#4893)
- Limit number of tests sent to the autotest server at one time (#4901)
- Restore the flash messages displayed when students submit files (#4903)
- Enable assignment only_required_files setting to work with subdirectories (#4903)
- Fix bug where checkbox marks are updated twice (#4908)
- Fixed the Assign Reviewers table loading issue (#4894)
- Fixed a bug where the progress bar in submissions and results page counts the not collected submissions (#4854)

## [v1.10.1]
- Fix out of dates link to the wiki (#4843)
- Fixed a bug where the grade summary view was not being properly displayed if no criteria existed (#4855)
- Fixed an error preventing graders from viewing grade entry forms (#4857)
- Fixed an error which used unreleased results to calculate assignment statistics (#4862)

## [v1.10.0]
- Issue #3670: Added API for adding and removing extra marks (#4499)
- Restrict confirmation dialog for annotation editing to annotations that belong to annotation categories (#4540)
- Fixed sorting in annotation table in results view (#4542)
- Enabled customization of rubric criterion level number and marks (#4535)
- Introduces automated email sending for submissions releases (#4432)
- Introduces automated email sending for spreadsheet releases (#4460)
- Introduces automated email sending for grouping invitations (#4470)
- Introduces student email settings (#4578)
- Assignment grader distribution graphs only show marks for assigned criteria when graders are assigned specific
  criteria (#4656) 
- Fixed bug preventing graders from creating new notes in results view (#4668)
- Fixed bug preventing new tags from being created from results view (#4669)
- Remove deprecated "detailed CSV" download link from submissions/browse (#4675)
- Introduces Deductive Annotations (#4693)
- Introduces annotation usage details panel to Annotations tab in admin settings (#4695)
- Fixed bug where bonuses and deductions were not displayed properly (#4699)
- Fixed bug where image annotations did not stay fixed relative to the image (#4706)
- Fixed bug where image annotations did not load properly (#4706)
- Fixed bug where downloading files in nested directories renamed the downloaded file (#4730)
- Introduces an option to unzip an uploaded zip file in place (#4731)
- Fixed bug where marking scheme weights were not displayed (#4735)
- Introduces timed assignments (#4665)
- Introduces uncategorized annotations grouping in Annotations settings tab (#4733)
- Introduces new grades summary chart, and makes student view of grades consistent with admin (#4740)
- Set SameSite=Lax on cookies (#4742)
- Introduces individual marks chart view for assessments (#4747)
- Fix annotation modal overflow issue (#4748)
- Introduce file viewer for student submission file manager and admin repo manager (#4754)
- Make skipping empty submissions the default behaviour when assigning graders (#4761)
- Introduce typing delay for entering flexible criterion mark (#4763)
- Fix UI overflow bug for large images in results file viewer (#4764)
- Add disabled delete button to submissions file manager when files unselected (#4765)
- Support syntax highlighting for html and css files (#4781)
- Add minutes field to non timed assessment extension modal (#4791)
- Add ability to check out git repositories over ssh using a public key uploaded in the new Key Pairs tab (#4598)
- Unify criterion tables using single table inheritance (refactoring change) (#4749)
- Add support for uploading multiple versions of starter files (#4751)
- Remove partially created annotation category data for failed upload (#4795)

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
- Fixed inverse association bug with assignments (#4551)
- Updated interface with the autotester so that files do not need to be copied when test are setup/enqueued (#4546)

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
- Fixed bug where a javascript submission/test/starter file can't be downloaded (#4520) 
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
