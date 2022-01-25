# PR 5551

Add link `R` to list at Instructor-Guide--Assignments--Automated-Testing.md#tester-types which links to:

#### R

- *Package requirements*: In this section you may specify additional CRAN (https://cran.r-project.org/) packages required by your tests. Use a space to separate different package names.


# Proposed Change to the "Instructor-Guide--Importing-and-Exporting-Data" page

**Overview:** In order to provide proper documentation on the the zip file that is downloaded/uploaded when copying an assignment to a new instance, a new section must be added to the "Instructor-Guide--Importing-and-Exporting-Data" page.

This change relates to pull request [#5498](https://github.com/MarkUsProject/Markus/pull/5498) as it adds a new modal that links to a page
to give the user more documentation when uploading the related zip file.

This new section will be called "Assignment Configuration" and will be added at the end of the page as an additional section.

It will look like the following:

## Assignment Configuration

Instructors are able to upload/download a group of files that contain all the settings and files required to configure
an assignment (that is, it's properties, tags, criteria, annotations, starter files and automated tests).

This upload/download **DOES NOT** copy assignment settings related to students or graders (i.e. section specific settings, group
information, etc.). Hence, after copying an assignment over, it is recommended that users check the assignment's settings
to make sure it is configured as they desire.

### Supported formats

A zip file that contains the following yml files for an assignment:

- [properties](Instructor-Guide--Importing-and-Exporting-Data.md#assignments)
- [tags](Instructor-Guide--Importing-and-Exporting-Data.md#tags)
- [criteria](Instructor-Guide--Importing-and-Exporting-Data.md#criteria)
- [annotation categories](Instructor-Guide--Importing-and-Exporting-Data.md#annotation-categories) (excluding one time annotations)

In addition, the zip file has three folders that contain:

- An assignment's starter files and starter file settings (`starter_file_config_files`) which includes:
  - A starter file rules yml file which contains:
    - The name of the default starter file group within the zip file.
    - Information about each starter file group:
      - The name of the starter file group within the zip file.
      - The actual name of the starter group.
      - Whether it uses a different display name and if so, what that display name is.
  - Every uploaded starter file located in folders corresponding to which starter file group each file belongs to.
    - Every starter file group does not need a corresponding folder. In such a case, the group is assumed to have no starter files.
- An assignment's automated test settings (`automated_tests_config_files`) which includes:
  - An automated test specs json file.
  - A folder containing every uploaded test file.
    - This is an optional folder. If it does not exist, that means there are no test files.
- Settings for an assignment's peer review assignment (`peer-review-config-files`)
  - This is an optional folder. If it exists, a peer review assignment will try to be created.
  - This folder is formatted exactly the same as a normal assignment just without an automated tests folder and another peer review folder.

> **Important:**
> While the contents of the yml files and folders can be extracted and modified for offline configuration, this is NOT
> recommended and may result in the assignment being unable to be copied over.


# PR 5592

Add this section to the Scanned Exam page under "Exam format requirements", before "Generating exam papers".

### Automatic parsing of student information

MarkUs supports automatic matching of student papers based on student user names or ID numbers written on the cover page of a test.
If this feature is enabled, MarkUs will attempt to scan a portion of the test cover page and parse handwritten corresponding to either a student's user name or ID number attempt to match the test paper to a student in the course.

*Note*: this feature is meant to assist, but not replace, the manual matching process described below. MarkUs may be unable to correctly parse this information from the test cover page, or it may be written incorrectly and not match any students.

Automatic parsing is configured separately for each exam template.
To enable and use the automatic parsing feature for an exam template:

1. Go to the Settings -> Exam Templates tab, and find the exam template.
    - Ensure that your exam template has a *rectangular grid* for where students should enter their user name or id number (see our [sample file](https://github.com/MarkUsProject/Markus/blob/master/db/data/scanned_exams/midterm1-v2-test.pdf) for an example).

2. Under the "Automatic Parsing Selection" field, select the "Automatically parse student information" option.
3. MarkUs will display the cover page of the exam template and a drop-down menu.

    a. On the cover page, click-and-drag to select the region of the page where the students will write their user name/id number. We recommend including a small margin to account for positional adjustments when you scan the test papers.
    b. On the drop down, select whether to match the information on the students' user name or id number. You must choose one or the other; MarkUs does not support matching on both.
4. Press Save. You will be able to update these settings any time before scanning and uploading your test papers.
5. Then after giving the test, follow the instructions under "Uploading completed test papers" below. As part of that process, MarkUs will automatically parse and handwriting in the selected region, and attempt to match it against the selected student field (user name or id number). You can view the results of this matching under the "Groups" tab, and match the remaining test papers to students by following the instructions under "Matching test papers to students" below.

    **Note**: MarkUs takes a conservative approach, and will only match students if there is an exact match on the handwritten field.

#### Known limitations

1. MarkUs requires a rectangular grid for where students write their user name/id number.
2. MarkUs requires the student information to be written on the first page of the test paper. Other positions (e.g., the last page) are currently not supported.
