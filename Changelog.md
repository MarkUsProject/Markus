# Changelog

## [unreleased]

### 🛡️ Security

### 🚨 Breaking changes

### ✨ New features and improvements
- Enable test results downloads through the API (#7754)
- Provide suggestions for partial student matching scans (#7760)
- Allow inactive students to join groups (#7757)
- Update autotest settings form UI (#7777)
- Store start and end date for courses (#7783)
- Split courses into Current and Past sections for all users (#7801)
- Update batch test runs table UI (#7790)
- Implement assignment caching (#7787)

### 🐛 Bug fixes
- Prevent "No rows found" message from displaying in tables when data is loading (#7790)
- Prevent ZIP files from being previewed in the assignment file viewer (#7802)

### 🔧 Internal changes
- Updated autotest seed files to ensure settings follow tester JSON schema (#7775)
- Refactored grade entry form helper logic into `GradeEntryFormsController` and removed the newly-unused helper file. (#7789)
- Added tests for `GradeEntryFormsController` to fully cover `update_grade_entry_form_params` (#7789)
- Updated the grade breakdown summary table to use `@tanstack/react-table` v8 (#7800)
- Changed model validation errors to use built-in error key resolution instead of inline `I18n.t` calls (#7806)

## [v2.9.2]

### 🐛 Bug fixes
- Fixed display of inline images in notebook HTML rendering (#7816)

## [v2.9.1]

### 🛡️ Security
- Removed insecure html_content route
- Verify zip entry names in assignment configuration zip upload

### ✨ New features and improvements
- Prevent adding duplicate grader group mappings on CSV upload (#7786)
- Update batch test runs table UI (#7790)

### 🐛 Bug fixes
- Fixed assignment YML export to correctly nest assignment property attributes under `assignment_properties_attributes` (#7792)
- Hide deactivated/missing students and restore re-enrolled students during roster sync (#7799)
- Fixed the editing form of marking schemes to include newly added assessments (#7788)

## [v2.9.0]

### ✨ New features and improvements
- Added touch event support for PDF and image annotations in grading view (#7736)
- Added datetime-based visibility scheduling for assessments with `visible_on` and `visible_until` columns (#7697)
- Added frontend UI for assignment visibility scheduling with three visibility options and section-specific overrides (#7717)
- Added new loading spinner icon for tables (#7602)
- Added functionality to apply bonuses and penalties as a percentage of the student's earned marks to ExtraMark model (#7702)
- Switched to consistent Font Awesome chevrons for expander icons (#7713)
- Install Ruby-LSP to allow development inside different IDEs such as VSCode (#7718)
- Ensure only instructors and admins can link course, as LMS launch MarkUs button made available for all users (#7714)
- Include student number in roster sync from Canvas (#7731)
- Add API endpoint `add_test_run` that allows independent user submissions of test executions to MarkUs (#7730)
- Display timeout status for autotest runs in the Test Results table. (#7734)
- Assign extra marks in test definition. (Currently limited to pytest files) (#7728)
- Enable zip downloads of test results (#7733)
- Create rake task to remove orphaned end users (#7741)
- Enable scanned assignments the ability to add inactive students (#7737)

### 🐛 Bug fixes
- Fix name column search in graders table (#7693)
- Check against mtime instead of atime for clean up of git repo directories in tmp folder (#7706)
- Update Model: Fix level validation checks through use of a custom validator (#7696)
- Fixed test group results table to display `extra_info` field from all test groups (#7710)
- Fixed syncing grades with Canvas to not include inactive students (#7759)

### 🔧 Internal changes
- Updated Github Actions CI to use cache-apt-pkgs to speed up workflow runs (#7645)
- Converted "Create Group" functionality to React modal (#7663)
- Added tests to improve coverage for `AnnotationCategory`'s `self.to_json` method
- Added tests to the Criteria Controller class to achieve full test coverage
- Refactored Criterion subclasses to remove redundant code
- Converted "Rename Group" functionality to React modal (#7673)
- Fixed Rack deprecation warnings by updating HTTP status code symbols (#7675)
- Refactored "Reuse Groups" functionality to use React modal and relocated button to action box row (#7688)
- Updated pre-commit `rubocop-rails` version to 2.33.4 (#7691)
- Refactored MarksPanel child components and converted the components into hook-based function components
- Refactored jQuery active marks panel component tracking logic into React
- Updated the course summary table to use `@tanstack/react-table` v8 (#7732)
- Refactored `test_run_table.jsx` by extracting nested components into separate files (#7739)

## [v2.8.2]

### ✨ New features and improvements
- Update message and page displaying cannot create new course via external LTI tool (#7669)
- Provide file viewer the option to render Microsoft files (#7676)
- Display late submission selection and add accompanying filter (#7689)

### 🐛 Bug fixes
- Fixed N+1 query problem in StudentsController by eager loading user association (#7678)
- Resque Host Authorization, removing env condition as this is for all environments (#7671)
- Fixed ordering of assignments in the Assignment dropdown menu and Assignment index page (#7642)
- Updated Section model associations with appropriate dependent options to handle cascade deletion while preventing deletion when students exist (#7681)
- Prevent grade change in the grades table for a Marks Spreadsheet, when scrolling up or down with mouse or keys (#7680)
- Fixed ordering of sections in the Timed Assessment assignments section-specific settings table (#7690)
- Reattach, accidentally removed due date extension modifier (#7703)

## [v2.8.1]

### 🐛 Bug fixes
- Fixed group member filtering in assignment summary table (#7644)
- Fixed spacing issue for the remote authentication login button (#7646)
- Fixed API bug when creating binary submission files (#7647)
- Fixed preview of URL submissions (#7661)
- Fixed autogeneration of URL alias in URL submission form (#7661)

### 🔧 Internal changes
- Updated the assignment summary table to use `@tanstack/react-table` v8 (#7630)
- Updated Github Actions CI to use cache-apt-pkgs to speed up workflow runs (#7645)

## [v2.8.0]

### 🚨 Breaking changes

### ✨ New features and improvements
- Improved layout and labeling in the assignment settings form for both standard and timed assessments. (#7531)
- Design improvement of tables when the data is empty. (#7557)
- Improved Assignment view for students (#7533)
- Added average annotations section in Assignment Summary (#7559)
- Maintain font size in grading view (#7525)
- Replaced assignment summary statistics in the "Status" column on the instructor Assignments page with a link to the grades page. (#7560)
- Renamed the "Summary" sub-tab label to "Grades" in the Assignment interface. (#7560)
- Replaced "Edit" and "Delete" action text links with Font Awesome icons across all tables. (#7595)
- Create User class method to retrieve orphaned users (#7633)

### 🐛 Bug fixes
- Added host authorization setting for Resque (#7562)

### 🔧 Internal changes

- Updated `test_ci.yml`, making GitHub Actions run rspec and jest tests in parallel. (#7634)
- Remove `activerecord-session_store` gem (#7517)
- Upgrade to Rails 8 (#7504)
- Add tests for `#new` and `#create` actions in `CriteriaController` (#7521)
- Add tests for `#edit` and `#update` when user is trying to change criteria in `CriteriaController` (#7527)
- Remove the placeholder "..." text under the "Proposed changes" section in `PULL_REQUEST_TEMPLATE.md`. (#7524)
- Update the checklist in `PULL_REQUEST_TEMPLATE.md` to make the text "list of contributors" a link to the file in the repository. (#7524)
- Enabled `erb_lint` linter for erb files (#7561)
- Refactored the loading method of `javascripts/Results/context_menu.js`. (#7563)
- Added test metadata examples to seed data for R autotesting (#7564)
- Refactored the method of loading `javascripts/Results/keybinding.js` in `submission_selector.jsx` (#7566)
- Moved QR scanning to external python package markus_exam_matcher (#7567)
- Updated the instructor table to use `@tanstack/react-table` v8 (#7589)
- Refactor `DropDownMenu` class to a new React component (#7592)
- Updated the tag table and "one time only annotations" table to use `@tanstack/react-table` v8 (#7596)
- Updated Python autotest script file to include example of using `pytest.mark` to customize test marks (#7597)
- Refactor `Grader` table in `Users` to use `@tanstack/react-table` v8 (#7598)
- Updated `dependabot.yml` to add React dependency group and increase, remove old webpack ignored versions, and remove open PR limits (#7627)
- Improved performance of PDF splitting for scanned assessments (#7632)

## [v2.7.1]

### 🐛 Bug fixes

- Fix bugs when assigning sections to starter file groups across multiple assignments (#7523)

## [v2.7.0]

### 🚨 Breaking changes

### ✨ New features and improvements

- Fix front-end content shift when an input element is focused (#7384)
- Tooltip text for Package requirements file for Python autotester settings (#7383)
- Pass back tags and overall comments from Autotester to MarkUs (#7387)
- Render download test result button on assignment summary page only if the assignment has automated testing (#7417)
- Group test results by Test Groups id (#7422)
- Display HTML previews of RMarkdown files (#7394)
- Allow instructors to assign scans to inactive students (#7482)
- Added members parameter to add_group_api to support explicit member assignment during group creation (#7481)
- Modified add_group_api to use username as group name for individual assignments (#7481)
- Improved styling of markdown previews in `MarkdownPreview` component and annotation displays (#7487)
- Allow creating image annotations from a test run's outputs (#7486)
- Added an API that collects a single submission (#7494)
- Enable removal of a student from a course (#7480)
- Changed the PDF scanning job separate the student matching process into its own job. (#7499)

### 🐛 Bug fixes

- Ensures row selection for peer reviewer unassigning has the same validation checks as individual selections (#7274)
- Ensures mark levels on a rubric criterion are properly scaled when its max mark is updated (#7311)
- Refactor contributors list in About section to read from markus-contributors.txt (#7374)
- Optimized the querying of submissions when assigning graders (#7381)
- Update remote_autotest_settings_id validation to be unique to an autotester (#7393)
- Fix tag creation failing in tags table (#7426)
- Ensure tag names are unique within an assignment (#7430)
- Update flash style to "notice" for "setting up test env" message (#7445)
- Fixed bug in `ImageViewer` where image width was set to 0 on initial load (#7485)
- Fixed bug in `ImageViewer` where annotations did not disappear when moving the mouse out of the image (#7485)
- Ensured annotations appear in results view when in fullscreen mode (#7487)
- Fixed bug in `ImageViewer` where annotations did not always appear on initial image load (#7487)

### 🔧 Internal changes

- Reorganize Javascript files to separate Sprockets and Webpack compilation (#7345)
- Replace moment.js dependency with much smaller dayjs (#7346)
- Refactor `FileViewer`, `TextViewer`, `BinaryViewer` and `ImageViewer` components (#7270)
- Pin `mistune` Python dependency to preserve compatibility with `nbconvert` (#7371)
- Cache playwright's chromium installation on GitHub Actions (#7372)
- Fix broken link to the Vagrant installation guide in `README.md` (#7349)
- Fix `extra_hosts` configuration in `compose.yaml` (#7375)
- Add unit tests for `marks_graders_controller` (#7382)
- Convert front-end tests from enzyme to react testing library; add `@testing-library/user-event` (#7379)
- Refactor the `Result` component and its children to use React context API (#7380)
- Implement `contain_message` and `have_message` custom Rspec matchers to check for flash message content (#7386)
- Update Python version to 3.13 in seed autotest schemas (#7388)
- Rename jupyter notebook content functions and files to generalize to html content (#7391)
- Update to React v18 (#7392)
- Refactor querying on dashboard graph to query per-assignment rather than per-TA (#7420)
- Remove unused Javascript files (#7442)
- Refactor scanned test generation and test splitting from polling to websockets (#7428)
- Move Docker dependency updates into separate service (#7451)
- Fixed flaky test due to daylight savings time issue (#7452)
- Updated Python autotest seed file to illustrate pytest metadata custom markers (#7457)
- Updated to react-flatpickr v4.0.0 (#7478)
- Remove `mistune` Python explicit dependency (#7483)
- Applied pre-commit (specifically Rubocop) changes to use it_behaves_like over include_examples (#7492)
- Added explicit permissions to GitHub Actions workflow configuration (#7495)

## [v2.6.1]

### ✨ New features and improvements

- Give instructors the ability to delete a TA from the Users Graders Tab (#7304)
- Added zoom and rotate functionality to PDF viewer (#7306)

### 🐛 Bug fixes

- Ensure we handle JSON parsing exceptions when converting Jupyter Notebooks (#7308)
- Fixed bug in grading context menu for editing/deleting annotations (#7314)
- Fixed bug in grading annotations table when deleting annotations (#7314)
- Ensure correct LTI version of lti_user_id is used on launch (#7335)

## [v2.6.0]

### ✨ New features and improvements

- Prevent instructors from unassigning peer reviewers who have existing peer review data (#7263)
- Add visual indicator on a per-assignment basis for used grace credits (#7226)
- Change default disabled text area colour to ligher grey on light mode (#7269)
- Implement a limit on the file size rendered by the submission viewer (#7273)
- Add an option to retain old grading data when recollecting graded submissions (#7256)

### 🐛 Bug fixes

- Fix incorrect calculation of token penalties when submissions are on time (#7216)
- Ensured submissions that have been released cannot be recollected from the repo browser (#7254)
- Fix bug where renaming a group to an existing group in a different assignment resulted in incorrect repository mapping (#7224)
- Disable editable fields in assignment criterion when criterion is released (#7264)
- Fixed Download One Time Annotation 'Not Found' error (#7302)

### 🔧 Internal changes

- Fix test coverage for ExamTemplate.create_with_file method (#7213)
- Upgrade Docker environment to use Ruby v3.3 (#7185)
- Upgrade to Rails v7.2 (#7185)
- Move Exception message in student model to a localization file (#7218)
- Add test cases for the student model to cover Group or Grouping save method failure (#7218)
- Create tests for overtime messages of the submission rule classes (#7216)
- Fix flaky `check_repo_permissions` test (#7223)
- Move model validation error messages to respective localization files (#7229)
- Replace time-warp gem with newer, maintained timecop gem (#7234)
- Update pre-commit-hooks to v5.0 and add checks `check-illegal-windows-names`, `check-json`, and `check-merge-conflict` (#7259)
- Merge result.js and result_main.css build files into application.js/application.css (#7260)
- Simplify pdf.js configuration (#7260)
- Improve descriptions of the Group and Grouping models (#7262)
- Disable Rubocop Style/SafeNavigationChainLength check (#7301)
- Ignore faker translations in i18n-js compilation (#7305)

## [v2.5.3]

### 🐛 Bug fixes

- Fix Marks Spreadsheet csv bug of showing incorrect marks (#7257)
- Fix incorrect inclusion of course parameter in LtiSyncJob (#7258)
- Fix Google Colab Jupyter Notebooks rendering by excluding widgets (#7271)

## [v2.5.2]

### ✨ New features and improvements

- Improve textviewer rendering speed (#7211)
- Add periodic roster syncing via LTI (#7178)
- Allow instructors to assign graders by section (#7179)

### 🐛 Bug fixes

- Fix JSON/CSV summary of test results to always be inline with latest test run (#7214)
- Allow annotations to be added to results with released peer reviews (#7222)

### 🔧 Internal changes

- Manually specify chromedriver port number in Github actions (#7209)

## [v2.5.1]

### 🐛 Bug fixes

- Fix bug in syntax highlighting caused by incorrect function call (#7187)

## [v2.5.0]

### ✨ New features and improvements

- Allow deletion of assignments with no groups (#6880)
- Add new routes for `update`, `show`, and `index` actions of the Sections API Controller (#6955)
- Enable the deletion of Grade Entry Forms that have no grades (#6915)
- Allow instructors to configure an end date until which students can run automated tests (#6992)
- Gave TAs read-only access to starter file information under assignment settings (#6996)
- Allow inactive groups in the submissions table to be toggled for display (#7000)
- Display error message for student-run tests when no test groups are runnable (#7003)
- Added a confirmation check while renaming a file with a different extension (#7024)
- Allow inactive groups in the summary table to be toggled for display (#7029)
- Display error message for instructor-run tests when no test groups are runnable by instructors (#7038)
- Ensure user params are passed as keyword arguments to database queries (#7040)
- Added a progress bar for when a student uploads a file for submission (#7078)
- Added validations to the `TextAnnotation` model to ensure `line_start` and `line_end` are >= 1, and `column_start` and `column_end` are >= 0. (#7081)
- Calculate and display the exact future time for the next token generation to help students plan their test runs more effectively. (#7127)
- Set the default date for "Tokens available on" to the current time (#7173).
- Add setting to enable filtering of new course creation from LTI launch (#7151)

### 🐛 Bug fixes

- Ensure annotation previews are rendered on annotations page and in annotation category dropdown menus when grading (#7073)
- Ensure annotation rendering is updated in real-time for Jupyter notebooks (#7084)
- Fix MathJax rendering in annotations for Jupyter notebooks (#7084)
- Fix MathJax rendering of released overall comments (#7084)
- Fix rename confirmation check triggering even upon no rename input (#7124)
- Ensured that the assignment deadline is used as a placeholder if token_end_date is not present. (#7128)
- Fixed grader view rendering when a pre-defined annotation's content is blank (#7147)
- Fixed AJAX requests in grader view, which were missing CSRF token headers (#7174)
- Use jQuery `.find` method in `ModalMarkus` to guard against potential XSS attack (#7176)
- Sanitize LTI deployment course names when creating new courses (#7151)

### 🔧 Internal changes

- Fixed login_spec.rb flaky test on GitHub Actions run (#6966)
- Minor improvements in assignment association options (#6989)
- Update changelog and pull request template formats (#7041)
- Upgrade to MathJax version 3, with packaging from npm (#7073)
- Upgrade CI chromedriver to 125.0.6422.60 (#7082)
- Fix flaky `Assignment#summary_json` test (#7111)
- Upgrade pdfjs-dist to v4.3.136 (#7113)
- Fixed formatting of documentation repository on the PR template (#7120)
- Switch from rails-sassc to cssbundling-rails for CSS asset management (#7121)
- Fixed flaky test #creates groups for individual students in groups_controller_spec (#7145)
- Switch from SyntaxHighlighter to Prism for syntax highlighting (#7122)
- Move jquery-ui and ui-contextmenu dependencies to package.json and upgrade jquery-ui to v1.13.3 (#7149)
- Do not enforce secure cookies in development for LTI deployments (#7151)
- Remove CI chromedriver version and Chrome dependency (#7170)
- Update Jupyter notebook Javascript dependencies (require.js to v2.3.7, plotly.js to v2.34.0) (#7175)
- Do not require i18n-tasks in Gemfile (#7180)

## [v2.4.12]

### ✨ New features and improvements

- Added a backend to check MIME type and file extension of uploaded files (#7083)

### 🐛 Bug fixes

- Fix bug in grade display for marks summary (#7125)
- Remove peer reviews from grade summary table (#7126)

## [v2.4.11]

### 🚨 Breaking changes

- Disallow peer reviewers from printing results (#7114)

## [v2.4.10]

### ✨ New features and improvements

- Allow restricting IP addresses for remote logins (#7072)

## [v2.4.9]
- Peer review table bug fix to display total marks (#7034)
- Fix bug preventing deletion of autotest files (#7033)

## [v2.4.8]
- Validate user-provided paths (#7025)

## [v2.4.7]
- Support Jupyter notebooks for results printing (#6993)
- Enable bulk download of print PDFs for an assignments (#6998)
- Fixed long annotations being cut off in the annotation table (#7001)

## [v2.4.6]
- Disallow students from uploading .git file and .git folder in their repository (#6963)

## [v2.4.5]
- Add workaround for CSP in Safari < 16 (#6947)
- Improve add button labels on autotest settings page (#6948)
- Fix bug where grader distribution graph displays graders multiple times (#6950)
- Fixed bug where TA Summary table failed to display members (#6949)
- Make display of group member information consistent across submissions and summary table (#6917)

## [v2.4.4]
- Fix websocket connection when logged in with remote auth (#6912)
- Fix bug where graders table failed to load when a group had no members (#6916)

## [v2.4.3]
- Fix autotest settings criterion JSON schema validation (#6907)
- Ensure autotested criteria do not have marks set if tests time out (#6907)
- Fix import bug that prevents the peer review table from loading (#6908)

## [v2.4.2]
- Fix feedback file API not returning feedback file IDs correctly (#6875)
- Allow inactive groups in the graders table to be toggled for display (#6778)
- Enable plotly rendering for jupyter notebooks (#6871)
- Bug Fix: Prevent assigning inactive graders to a group (#6801)
- Added new API routes for the `create` and `destroy` actions of SectionsController (#6873)
- Display error message in real-time when running automated tests, rather than waiting for page refresh (#6878)

## [v2.4.1]
- Internal changes only

## [v2.4.0]
- Display error message on file upload failure (#6703)
- Remark request grading: differentiate between old and new annotations using colour and remark flag (#6704)
- Display detailed messages about grace period deductions for an assignment on student interface (#6706)
- Moved create and edit tag modals to React (#6742)
- Added constraint for `Tag` name field: not empty and max 30 characters (#6742)
- Modified and moved helper methods from `CriteriaHelper` into static methods in the `Criterion` class (#6746)
- Convert helper methods of the module `app/helpers/annotations_categories_helper` into class methods of the
  `AnnotationCategory` model. The refactored helper methods were `annotation_categories_to_yml` and
  `upload_annotations_from_yaml` (#6747)
- Added tooltips to criteria type and visibility icons (#6753)
- Replace the function `tas` of the `Assignment` model with a `tas` "has_many" association for that model (#6764)
- Ensure starter files are passed to autotester in sorted order (#6771)
- Resolved issue 6677 by taking timed assessment's duration into account when determining when grading can begin (#6845)
- Fix loading results page when group is created after the due date (#6863)
- Autocomplete with active students only for matching process in 'assign scans' (#6844)
- Fix member filtering in Groups table (#6842)

## [v2.3.4]
- Ensure the "Random Incomplete Submission" button takes into account criteria assignment for TAs (#6800)
- Ensure bonus marks are not included in assignment "out of" in submissions table (#6836)
- Ensure assignment "out of" in submissions table is rounded to two decimal places (#6836)
- Added POST API for Group Creation (#6834)

## [v2.3.3]
- Fix bug where uploading scanned exam pages with overwriting option selected did not update submission files (#6768)
- Fix bug: "Download Submissions" download link was not being rendered from partial view (#6779)

## [v2.3.2]
- Allow MathJAX to process environments (e.g., align) (#6762)

## [v2.3.1]
- Add filter for empty/non-empty submissions in submissions table (#6711)
- Fix bug where autotest settings would not appear if there were no assignment criteria (#6718)
- Added API routes for Extensions API (#6743)
- Fix premature page reloading when autotest settings are saved (#6744)

## [v2.3.0]
- Do not destroy pending group memberships if the group is given an extension (#6582)
- Add OCR for parsing scanned exam uploads (#6433)
- Move submission-specific results/ routes to be under submissions/ (#6434)
- Add option to allow Cross-Origin Resource Sharing (CORS) from JupyterHub (#6442)
- Fix error message when a file is submitted through the API that doesn't match the required file list (#6479)
- Improve syntax highlighting for C (#6513)
- Allow negative grades for bonus columns in marks spreadsheets (#6521)
- Clarify assignment submission rule configuration labels (#6529)
- Enable client-side validation of autotest settings page (#6568)
- Use web sockets instead of polling to update submissions table after collecting submissions (#6583)
- Order students by username when downloading the CSV grades breakdown for an assignment from Summary tab  (#6589)
- Use web sockets to update TestRunTable for non-batch run tests when a test run is in progress or completed (#6591)
- Add button to allow students to cancel automated test runs (#6596)
- Use web sockets instead of polling to update submission collection status (#6597)
- Removed trailing spaces at end of every line when viewing a file (#6598)
- Modify MarkUs API to allow the CoursesController#index route to accept requests from all types of roles (#6619)
- Modify MarkUs API to allow the AssignmentsController#index route to accept requests from all types of roles (#6619)
- A user can't run tests with the same names / Single test error does not spoil the whole test batch (#6620)
- Refactored GET requests to use fetch API instead of jQuery (#6622)
- Change icon set to Font Awesome (Free) (#6627)
- Add feature to generate a PDF report of a result (PDF submission files only) (#6635)
- Add zoom feature to scanned exam template crop selection (#6640)
- Ensure Jupyter notebook HTML rendering does not require external CDNs (#6656)
- Prevent Jupyter notebook from reloading when an annotation is added (#6656)
- Added a button allowing graders to view a random incomplete submission (#6641)
- Added a filter modal allowing graders to specify filters and order when navigating submissions (#6642)
- Add icons to submission and result grading action buttons (#6666)
- Remove group name maximum length constraint (#6668)
- Fix bug where in some cases flash messages were not being rendered correctly (#6670)
- Enable duplicate pages when uploading scanned exams to overwrite existing pages or be ignored (#6674)
- Extended the filter modal to allow graders to order results by total mark and filter them by criteria (#6669)
- Validate copy and page number when fixing errors with scanned exams (#6695)
- Display due date and submission time in result "Submission Info" tab (#6698)
- Added "Help" link to the MarkUs page header dropdown (#6702)
- Prevent TAs that aren't assigned to grade a given criterion from assigning a grade to that criterion (#6699)
- Replace byebug gem with debug gem (#6705)
- Added persistence to the filter modal (#6697)

## [v2.2.4]
- Add feature to generate a PDF report of a result (PDF submission files only) (#6635)


## [v2.2.3]
- Fix bug where in some circumstances the wrong result would be displayed to students (#6465)

## [v2.2.2]
- Apply course maximum file size to feedback files (#6430)

## [v2.2.1]
- Fix bug where error was raised when viewing jupyter notebooks if python is not available (#6418)
- Fix bug where peer reviewers could not view results they are assigned to review (#6439)
- Make fewer connections when connecting to redis (#6443)

## [v2.2.0]
- Moved markdown text preview to new tab in the generic autosaving text form component (#6154)
- Simplify configuration options for storing files on disk (#6157)
- Replace yarn with npm as a package manager (#6159)
- Drop support for subversion repositories (#6160)
- Fix undefined prop type warnings when loading assessment charts (#6172)
- Allow graders and instructors to be set to hidden status (#6173)
- Prevent hidden roles from interacting with a course (#6173)
- Do not dynamically change the database schema which causes migration and installation issues (#6189)
- Make git hooks more portable by converting them to shell scripts (#6196)
- Don't start webpack docker service in development before the packages are fully installed (#6212)
- Added ability to download feedback files (#6215)
- Allow admins to set the autotester url for each course in the courses view (#6213)
- Allow admins to test and reset the connection to the autotester in the courses view and through the API (#6213)
- Fix bug where exam template was downloaded instead of copies with unique qr codes (#6219)
- Allow admin users to manage the maximum file size setting through the UI (#6195)
- Disable python features if python dependencies are not installed (#6232)
- Install system dependencies from a debian package (#6246)
- Fix bug where assignments could not be uploaded with unexpected properties in file upload content (#6224)
- Fix bug where tests group results associated with old test groups aren't displayed with test group information (#6285)
- Read the MarkUs version once at initialization instead of at every request (#6305)
- Allow spaces in file names (#6306)
- Fix bug where a request to cancel test runs failed if some test runs had already completed (#6320)
- Downloading files from a single repository no longer adds an additional subdirectory to the zip archive (#6323)
- Bulk submission collection: allow collecting the most recent revision and choosing whether to apply late penalties (#6341)
- Allow admins to role switch to instructors (#6353)
- Fix bug where rubric grades could not be selected with the return key (#6354)
- Allow admins to set the number of puma workers and threads from the settings files (#6348)
- Fix bug where a user who has switched roles could not view the about modal or log out (#6356)
- Fix bug where grades summary charts flicker in some browsers (#6352)
- Fix bug where emoji annotation options were available even when no text/region was selected (#6384)
- Fix bug where certain results attributes could not be updated if the result was incomplete (#6388)

## [v2.1.7]
- Switch from jquery-ui-timepicker-addon to flatpickr for datetime inputs (#6158)
- Allow results to be made available only through unique tokens (#6244)

## [v2.1.6]
- Fix bug where TAs were able to access urls for results they haven't been assigned to (#6321)
- Fix bug where the marking state was left as "complete" after a new criterion is created (#6303)
- Fix bug where writing starter files to repositories failed if the starter files contained a directory (#6294)
- Fix bug where csv summary download fails if criteria are created after marking (#6302)

## [v2.1.5]
- Add admin users to the .access file so that they can be authenticated as having access to the git repos (#6237)
- Optionally log which user makes each request by tagging the log files with user_names (#6241)
- Allow users to upload and download csv files for marks spreadsheets in the same format (#6267)
- Hide manual submission collection button from users who don't have permission (#6282)
- Fix bug where gzipped binary feedback files were not unzipped correctly (#6283)
- Fix bug where remark request summary table wasn't being rendered correctly (#6284)
- Fix bug where test results were being associated with the wrong test runs (#6287)

## [v2.1.4]
- Fix bug where git hooks are not run server side when symlinked (#6276/#6277)

## [v2.1.3]
- Fix bug where automated test results were occasionally associated with the wrong grouping (#6238)

## [v2.1.2]
- Fix bug preventing use of the update_grades API route (#6188)
- Fix overly restrictive policies for admin users (#6209)
- Add check for version format to ensure that Wiki links are well-formed (#6221)
- Fix bug where empty groups are hidden by default (#6222)
- Fix bug where test run table did not re-render when switching results (#6223)
- Allow admin users to manage the maximum file size setting through the UI (#6195)

## [v2.1.1]
- Fix bug where files could not be uploaded using drag and drop if no files or folders previously existed. (#6117)
- Added drag and drop functionality to upload starter files and automated tests. (#6117)
- Added new summary statistics display for grade entry forms and grade entry column items (#6118)
- Moved markdown text preview to new tab in the modify/create annotation modal (#6138)
- Enable bulk removal of students from section in student table (#6145)
- Enable updating student active/inactive status in student edit form (#6145)

## [v2.1.0]
- Remove unmaintained locales (#5727)
- Introduce standalone ruby script as an alternative method to checking for repository access (#5736)
- Added the ability to submit URLs (#5822)
- Switch Javascript bundling to jsbundling-rails gem, and update to webpack v5 (#5833)
- Remove group name displayed attribute from assignment properties table (#5834)
- Rework scanned exam page (#5839)
- Replace uses of first name and last name attributes with display name (#5844)
- Fix bug for rubric criteria level's mark update where one of the marks = an old mark (#5854)
- Upgrade to Rails 7 (#5885)
- Move footer and information in top right corner of navigation bar into a dropdown menu in the top right corner (#5886)
- Modified login to allow admin users to login via the UI (#5897)
- Fix bug where admins viewing the admin page were not redirected properly when timed out (#5909)
- Added a list of courses to manage for new markus administration view (#5907)
- Added a page in new markus administration view that allows admins to edit the attributes of a course (#5915)
- Added a page in new markus administration view that allows admins to create a new course (#5917)
- Added a list of users to manage for new markus administration view (#5918)
- Added Resque monitoring views for admin users (#5919)
- Added a page in new markus administration view that allows admins to edit user information (#5921)
- Added a page in new markus administration view that allows admins to create users (#5923)
- Added course visibility status to admin courses list (#5924)
- Added ability for instructors to edit course visibility (#5925)
- Fix bugs when handling remark requests with deductive annotations (#5926)
- Modified model associations so that a role belongs to a user (#5948)
- Fix display of flash messages when creating criteria and annotations (#5949)
- Display error messages on group csv upload when there are invalid group names (#5952)
- Created a new admin role (#5956)
- Added a bulk upload of end users to admin users page (#5959)
- Fix display of "Submit File" to "Upload File" for non submission views (#5960)
- Added an "Assign Scans" link to exam templates page (#5962)
- Added background job to clean tmp folder (#5963)
- Removed consideration of due date from scanned exam (#5964)
- Added Exception Notification Gem (#5965)
- Bug fixes for peer reviews (#5968)
- Added Rails Performance to Admin Dashboard (#5967)
- Added a detailed view for assignment statistics (#6000)
- Resolved issue 5905 by adding an explicit download icon to file manager, to differentiate from file preview action (#6001)
- Added student data such as user name, last name, first name, section, id number and email on grade reports for the whole course, individual assignments and grade entry forms (#6005)
- Update Groups API to return member role IDs instead of user IDs (#6006)
- Switch rendering of RMarkdown submission files to plaintext, rather than converting to HTML (#6008)
- Ensure consistent order when displaying test results (#6010)
- Added Capybara Gem (#6012)
- Enable students to rename files during submission (#6045)
- Separated peer review assignment upload/download from parent (#6048)
- Expanded summary stats UI (#6050)
- Fix bug for submission modal where students could submit files even if no file was chosen (#6052)
- Added ability to have a non-uniform group distribution when assigning graders (#6055)
- Added new "submit_file" API assignment route for students (#6057)
- Removed searchbar used to filter files on submissions page (#6058)
- Removed "outstanding_remark_request_count" attribute (#6059)
- Added checklist for required files on submissions page (#6061)
- Changed flash message that is displayed when students upload a file with an incorrect name. (#6062)
- Added emoji annotations for graders and removed `control+click` quick annotations. (#6093)
- Sorted courses on the dashboard. (#6099)
- Added summary statistics for criteria (#6100)
- Improved UI on 404 and 403 pages to match the style on MarkUs' dashboard. (#6101)
- Pass group name and starter files to the autotester when running tests (#6104)
- Handle multiple feedback files sent from the autotester (#6106)
- Added API CRUD requests for tags (#6107)
- Disabled admin editing of course name and allowed instructors to edit display name (#6111)
- Added explicit status and filtering for inactive students and groups in assignment groups page. (#6112)
- Fixed flaky automated test file tests by rearranging order of test file cleanup (#6114)
- Changed nav bar layout by moving the MarkUs logo beside the course name on the top bar (#6115)
- Replace standalone ruby script to check for repository access with database function (#6116)
- Update git over ssh scripts to optionally use the database function to check for repository access (#6116)
- Ensure each file viewer has independent syntax highlighting (#6139)
- Update git over ssh scripts to use the database function to check for authorized keys (#6142)
- Remove support for sqlite and mysql database types (#6143)
- Replace uglifier gem with terser gem to support ES6 syntax (#6146)
- Reorganize rake tasks to simplify steps required for asset precompilation in production (#6146)

## [v2.0.10]
- Fix bug when sorting batch test runs where sorting by date was not working (#5906)
- Ensure tabs in result view do not reload when switching between them (#5910)
- Fix bug where penalty periods were sometimes incorrectly ordered (#5908)

## [v2.0.9]
- Fix bug when downloading all automated test files where the files were saved to a sub directory (#5864)
- Fix bugs in assigning scanned exams and improve error message when assigning by name (#5895)
- Remove MarkUs logo from mobile view left navigation menu (#5899)
- Allow adding annotations to remark requests (#5900)

## [v2.0.8]
- Fix bug where "run tests" grader permission was not working for submission table (#5860)
- Fix bug for replacing exam template files (#5863)

## [v2.0.7]
- Fix bugs in starter files when assigning by section (#5846)

## [v2.0.6]
- Fix bug for "Delete Group" button generating an invalid path (#5768)
- When role switched, 403 errors are displayed as flash messages after redirecting back to the previous page (#5785)
- Update wiki urls to point to https://github.com/MarkUsProject/Wiki (#5781)
- Allow TAs to download grades for students they've been assigned to grade (#5793)
- Fix bug for menu icon not working on mobile devices / smaller screens (#5818)
- Fix bugs when submitting and cancelling remark requests (#5838)
- Do not trigger starter file changed timestamp when only starter_files_after_due assignment setting is changed (#5845)

## [v2.0.5]
- Add ability to annotate notebook (jupyter and Rmd) submissions (#5749)

## [v2.0.4]
- Fix bug where "Create Note" button was displaying when a course had no noteables (#5745)
- Redesign login page for multiple authentication options (#5752)
- Do not timeout users who are logged in using remote authentication (#5738)
- Ensure users logged in using remote authentication have their session expired when logging out from remote authentication (#5738)
- Display error message for users logging in using remote authentication if they do not exist in MarkUs database (#5738)
- Fix bug where git hooks were not finding the correct file containing the maximum file size for a given course (#5744)
- Allow setting optional role attributes through the api (#5748)
- Allow students to populate their repositories with starter files (#5754)

## [v2.0.3]
- Fix bug where repository access files were not taking multiple courses into account (#5734)
- Fix bug where sections and grace credits could not be updated from the student edit view (#5739)

## [v2.0.2]
- Fix bug in displaying feedback files for test results (#5719)
- Require starter group names to be unique for an assignment (#5721)
- Fix bug in updating the autotester url for a given course (#5724)

## [v2.0.1]
- Fix bug where a login with remote authentication failed to redirect to the landing page (#5690)
- Allow admin user to have a unique user name (#5691)

## [v2.0.0]
- Support multiple courses in a single MarkUs instance (#5685)

## [v1.14.1]
- Update wiki urls to point to https://github.com/MarkUsProject/Wiki (#5782)

## [v1.14.0]
- Add the ability to hide assignments from individual sections (#5445)
- Display smaller error message when nbconvert fails to avoid a cookie overflow (#5510)
- Fix bug with run test button in grading view when marks are released (#5527)
- Update repository access permissions to take into account the Assignment
  is_hidden and anonymize_groups attributes (#5547)
- Support syntax highlighting for R (#5558)
- Fixes in progress remark requests to display the remark request due date for students (#5562)
- Preserve exam template paper size and orientation when stamping with QR codes (#5573)
- Fix bugs in automatic parsing Python module (#5592)
- Fix exam template automatic parsing to only accept one crop box, and parse either
  ID number or user name (#5592)
- Fix scanned exams when using automatic parsing with multiple exam templates (#5592)
- Fixes assignment graders checkbox settings text to avoid double negatives (#5600)
- Add test results download modal for assignment summary (#5561)
- Improve accessibility of exam templates page (#5607)
- Fix display bug with infinitely expanding chart in student results view for grade entry form (#5612)
- Added the ability to copy over entire assignments (#5616)
- Fix bug in User#visible_assessments for students in a section (#5634)
- Fixed bug where tag edit modal closed whenever it is clicked (#5652)
- Fix bug where the datetime selector wasn't being shown for peer review assessments (#5659)
- Fix bug in displaying associated feedback files when switching between results (#5676)

## [v1.13.3]
- Display multiple feedback files returned by the autotester (#5524)
- Add workaround for CSP rules in Safari (#5526)
- Change level mark input field to accept change increments of 0.01 (#5546)
- Fix bug in annotation upload when updating categories not associated with a criterion (#5564)

## [v1.13.2]
- Ensure "Create all groups" button uses existing repos if they already exist (#5504)
- Set criteria marks after autotest run (#5508)

## [v1.13.1]
- Ensure that downloadable test specs file is portable between assignments and instances (#5469)
- Support rendering of Markdown in criterion descriptions (#5500)
- Ensure "Create all groups" button creates repositories for students usering their user name (#5499)

## [v1.13.0]
- Modify Result.get_total_extra_marks to differentiate between having extra marks that sum to zero and
  having no extra marks (#5220)
- Add copy to clipboard button for plaintext submission files in Results view (#5223)
- Add ability to associate feedback files to test group results (#5209)
- Communicate with autotester over http to support new autotesting configuration (#5225)
- Remove activerecord-import dependency (#5248)
- Combine all python dependencies (#5358)
- Rename "Tags/Notes" tab on grading page to "Submission Info", and move membership information to the tab (#5380)
- Respect referrer url when navigating between assignments (#5409)
- Remove delete link from TA table (#5407)
- Persist file size and rotation when navigating between text and image files (#5413)
- Improve student UI for timed assessments (#5417)
- When completing bulk actions, report errors instead of halting the whole process and rolling back (#5422)
- Add ability to download data from submissions table as csv file (#5418)
- Correctly update annotation category when creating annotation from "Did you mean" suggestion (#5448)
- Add route to download an example of the starter files that may be assigned to students (#5449)
- Validate a user's locale to ensure that it is set to a valid value (#5450)
- Display due date, collection date, and start time in repo browser view (#5462)
- Create dark mode versions of logo and favicon (#5463)
- Update UI for test results table (#5465)

## [v1.12.5]
- Fix bugs in grading view when switching between submissions (#5400)

## [v1.12.4]
- Symlink git repo hooks (#5283)

## [v1.12.3]
- Add workaround for content security policy to allow loading blobs in Safari (#5273)

## [v1.12.2]
- Require TestServer user to have a non-conflicting user name (#5268)

## [v1.12.1]
- Remove counter caches (#5222)
- Delay grouping creation for working-alone timed assessments to when the student starts the assessment (#5224)
- Add option to hide starter files after collection date (#5226)

## [v1.12.0]
- Remove annotations context menu from peer assignments view (#5116)
- Change 'Next' and 'Previous' submission button to use partial reloads (#5082)
- Add time zone validations (#5060)
- Add time zone to settings (#4938)
- Move configuration options to settings yaml files (#5061)
- Removed server_time information in submissions_controller.rb and server_time? from submission_policy.rb (#5071)
- Add rake tasks to un/archive all stateful files from a MarkUs instance (#5069)
- Fix bug where zip files with too many entries could not be uploaded (#5080)
- Add button to assignment's annotations tab to allow instructor to download one time annotations (#5088)
- Removed AssignmentStats table (#5089)
- Display assignment totals on the grade summary table rounded up to 2 decimal places (#5123)
- Removed results_average, results_median, results_fails, results_zeros cached stats (#5131)
- Do not allow users to set repo names by uploading csv files (#5132)
- Added a delete button to notes dialog under an results edit view and removed user_can_modify under note model,
  removed Notes#user_can_modify and replaced instances of usage with NotePolicy (#5128)
- Support Markdown syntax for assessment messages (#5135)
- Remove controller-specific css files (#5136)
- Replace non-UTF8 characters in text file preview (#5156)
- Rollback group creation if error is raised when creating a group for a working-alone student (#5169)
- Prevent deletion/modification of annotation texts associated with a result with a pending remark request (#5170)
- Enhancing student submission log with required assignment file info, file size (fixes issue 5171) (#5188)
- Ensure that browsers cache the correct state of overall comments when marking (#5173)
- Ensure that graders are shown the correct annotation categories (#5181)
- Show informative error message if an uploaded criteria yaml file did not contain a "type" key (#5184)
- Enable content security policies (#5186)
- Allow for multiple custom validation messages (#5194)
- Add ability to hold shift to select a range of values in checkbox tables (#5182)
- Update ssh authorization to be more flexible, secure, and permit a single user to use the same public key for multiple instances (#5199)
- Fix bug where creating an annotation or switching results reset the selected file (#5200)
- Fix bug in Assignment#get_num_marked that caused it to double-count remark and original results (#5205)
- Update permission files in background jobs (#5207)
- Fix bug where graders can't see the tests that they run (#5210)
- Fix bug where graders can't release results on the results page (#5210)
- Use DOMpurify library to sanitize rendered markdown content (#5211)
- Add percentage extra marks when calculating total extra marks properly (#5213)

## [v1.11.5]
- Account for percentage deductions when calculating total marks after deleting a criterion (#5176)
- Prevent students from downloading starter files early (#5189)

## [v1.11.4]
- Override defaultSortMethod for react-table to put null/undefined values at bottom (#5159)
- Fix bug where groupings created before starter files were uploaded could not download starter files (#5160)

## [v1.11.3]
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
