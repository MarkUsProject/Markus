---
permalink: /technical-guides/restful-api/
title: RESTful API
parent: Technical Guides
nav_order: 1
---
# RESTful API Documentation

This document provides an overview of the MarkUs RESTful API for use by developers as well as instructors. The API allows the use of standard HTTP methods such as GET, PUT, POST and DELETE to manipulate and retrieve resources. Those resources may also be retrieved either individually or from within collections.

## General

### Authentication

Authentication with the RESTful API is done using the HTTP Authorization header. The authorization method used is "MarkUsAuth", and should precede the encoded API token that can be found on the MarkUs Dashboard.

To retrieve your API token:

1. Log in to MarkUs.
2. At the top right of the page click the "Settings" button and go to the "Your API Key" section. Your api key should be visible (or it may be "unavailable" if it hasn't been generated for the first time yet)
3. copy the api key or click the "Reset API Key" button to generate a new one.

Given `MzNjMDcwMDhjZjMzY2E0NjdhODM2YWRkZmFhZWVjOGE=` as one's MarkUs API token, an example header would include: `Authorization: MarkUsAuth MzNjMDcwMDhjZjMzY2E0NjdhODM2YWRkZmFhZWVjOGE=`

#### Resetting Authentication Keys

In case of stolen authentication tokens, they can be globally reset by the system administrator using the `markus:reset_api_key` rake task. For example:

```console
cd path/to/markus/app
bundle exec rake markus:reset_api_key
```

### Response Formats

Both XML and JSON responses are supported. XML version 1.0 with UTF-8 encoding is the default response format used by the API. The response consists of an XML declaration followed by a root element, attributes, and may contain child elements and nested attributes. Due to it being the default format, the API will respond with XML if a .xml extension is present in the URL, or if no extension is provided. The following is an example XML response:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<user>
  <notes-count>1</notes-count>
  <grace-credits>0</grace-credits>
  <last-name>admin</last-name>
  <type>Admin</type>
  <first-name>admin</first-name>
  <id>1</id>
  <user-name>a</user-name>
</user>
```

If a .json extension is used in the URL, a JSON response will be rendered. Its simpler format consists of objects, represented as associative arrays. To request a JSON response using CURL, one can use the following:

```console
curl -H "Authorization: MarkUsAuth YourAuthKey" "http://example.com/api/users/1.json"
```

Which would result in the following output:

```json
{
  "id": 1,
  "user_name": "a",
  "last_name": "instructor",
  "first_name": "instructor",
  "type": "EndUser",
  "email": null,
  "id_number": null
}
```

### Common optional parameters

#### filter

The filter parameter is commonly used when multiple records are expected, this parameter will filter the records so that only those that match the filter are returned.

For example, if a route returns multiple user records, you may choose to filter on the first name by passing the following parameter (formatted as json):

```json
{"filter": {"first_name": "Steve"}}
```

and only users with the first name "Steve" will be returned

#### fields

The fields parameter is commonly used when multiple fields per record are expected, this parameter will filter the fields so that only the requested fields are returned. By default all fields are returned.

For example, if a route normally returns the following user record:

```json
{
  "id": 1,
  "user_name": "a",
  "last_name": "instructor",
  "first_name": "instructor",
  "type": "EndUser",
  "email": null,
  "id_number": null
}
```

but you only care about the id and user_name fields you can pass the following parameter (formatted as json):

```json
{"fields": ["id", "user_name"]}
```

and the route will now return the following instead:

```json
{
  "id": 1,
  "user_name": "a"
}
```

### GET /api/users

- description: Display all user information
- optional parameters:
    - [filter](#filter)
    - [fields](#fields)
- example response (json):

```json
[{
  "id": 1,
  "user_name": "a",
  "last_name": "instructor",
  "first_name": "instructor",
  "type": "EndUser",
  "email": null,
  "id_number": null
}]
```

NOTE: this method is only available to AdminUser users

### POST /api/users

- description: Create a user
- required parameters:
    - user_name (string)
    - type (one of "EndUser", "AdminUser")
    - first_name (string)
    - last_name (string)
- optional parameters:
    - email (string)
    - id_number (string)

NOTE: this method is only available to AdminUser users

### PUT /api/users/update_by_username

- description: Update attributes for a single user identified by their user_name
- required parameters:
    - user_name (string)
- optional parameters:
    - first_name (string)
    - last_name (string)
    - email (string)
    - id_number (string)

NOTE: this method is only available to AdminUser users

### GET /api/users/:id

- description: Display user information for a single user
- optional parameters:
    - [filter](#filter)
    - [fields](#fields)
- example response (json):

```json
{
  "id": 1,
  "user_name": "a",
  "last_name": "instructor",
  "first_name": "instructor",
  "type": "EndUser",
  "email": null,
  "id_number": null
}
```

NOTE: this method is only available to AdminUser users

### PUT /api/users/:id

- description: Update attributes for a single user
- optional parameters:
    - first_name (string)
    - last_name (string)
    - email (string)
    - id_number (string)

NOTE: this method is only available to AdminUser users

### GET /api/courses

- description: Display all course information
- optional parameters:
    - [filter](#filter)
    - [fields](#fields)
- example response (json):

```json
[
  {
    "id": 1,
    "name": "course1",
    "is_hidden": false,
    "display_name": "a longer course name to display in the UI",
    "start_at": "2026-01-05T00:00:00.000-05:00",
    "end_at": "2026-04-27T00:00:00.000-04:00"
  }
]
```

NOTE: If not an AdminUser, this will only return courses where the current user is enrolled as an Instructor

### POST /api/courses

- description: Create a course
- required parameters:
    - name (string)
    - is_hidden (boolean)
    - display_name (string)

NOTE: this method is only available to AdminUser users

### GET /api/courses/:id

- description: Display course information for a single course
- optional parameters:
    - [filter](#filter)
    - [fields](#fields)
- example response (json):

```json
{
  "id": 1,
  "name": "course1",
  "is_hidden": false,
  "display_name": "a longer course name to display in the UI",
  "start_at": "2026-01-05T00:00:00.000-05:00",
  "end_at": "2026-04-27T00:00:00.000-04:00"
}
```

NOTE: If not an AdminUser, this will only return courses where the current user is enrolled as an Instructor

### PUT /api/courses/:id

- description: Update attributes for a single course
- optional parameters:
    - name (string)
    - is_hidden (boolean)
    - display_name (string)
    - start_at (datetime)
    - end_at (datetime)

NOTE: this method is only available to AdminUser users

### PUT /api/courses/:id/update_autotest_url

- description: Update or set the url of the server running the [automated test software](https://github.com/MarkUsProject/markus-autotesting) for this course
- required parameters:
    - url (string: well formed URL)

NOTE: this method is only available to AdminUser users

### GET /api/courses/:id/test_autotest_connection

- description: Test whether MarkUs can connect to the server running the [automated test software](https://github.com/MarkUsProject/markus-autotesting) for this course.

NOTE: this method is only available to AdminUser users

### PUT /api/courses/:id/reset_autotest_connection

- description: Resend all automated test settings (for each assignment) to the [automated test software](https://github.com/MarkUsProject/markus-autotesting) for this course and get an updated schema.

NOTE: this method is only available to AdminUser users

### GET /api/courses/:course_id/roles

- description: Display all role information for the given course
- optional parameters:
    - [filter](#filter)
    - [fields](#fields)
- example response (json):

```json
[
  {
    "id": 230,
    "type": "Student",
    "hidden": false,
    "grace_credits": 0,
    "user_name": "role123",
    "email": null,
    "id_number": null,
    "first_name": "Stu",
    "last_name": "Dent"
  }
]
```

### POST /api/courses/:course_id/roles

- description: Create a role for a user in the given course
- required parameters:
    - user_name (string: a user with this user name must exist)
    - type (string: one of "Instructor", "Ta", "Student", "AdminRole")
- optional parameters:
    - grace_credits (integer)
    - hidden (boolean)
    - section_name (string: name of a Section for the given course)

NOTE: the "AdminRole" type can only be used by AdminUser users

### POST /api/courses/:course_id/roles/create_or_unhide

- description: Create a role for a user in the given course, if the given role already exists set the hidden attribute to `false` instead
- required parameters:
    - user_name (string: a user with this user name must exist)
    - type (string: one of "Instructor", "Ta", "Student", "AdminRole")
- optional parameters:
    - grace_credits (integer)
    - hidden (boolean)
    - section_name (string: name of a Section for the given course)

NOTE: the "AdminRole" type can only be used by AdminUser users

## PUT /api/courses/:course_id/roles/update_by_username

- description: Update attributes for a role identified by the user name attribute
- required parameters:
    - user_name (string: a user with this user name must exist)
- optional parameters:
    - grace_credits (integer)
    - hidden (boolean)
    - section_name (string: name of a Section for the given course)

### GET /api/courses/:course_id/roles/:id

- description: Display role information for a single role
- optional parameters:
    - [filter](#filter)
    - [fields](#fields)
- example response (json):

```json
{
  "id": 230,
  "type": "Student",
  "hidden": false,
  "grace_credits": 0,
  "user_name": "role123",
  "email": null,
  "id_number": null,
  "first_name": "Stu",
  "last_name": "Dent"
}
```

### PUT /api/courses/:course_id/roles/:id

- description: Update attributes for a single role
- optional parameters:
    - grace_credits (integer)
    - hidden (boolean)
    - section_name (string: name of a Section for the given course)

### GET /api/courses/:course_id/grade_entry_forms

- description: Display all grade entry form information for the given course
- optional parameters:
    - [filter](#filter)
    - [fields](#fields)
- example response (json):

```json
[
  {
    "id": 7,
    "short_identifier": "Quiz1",
    "description": "Class Quiz on Variables",
    "due_date": "2080-12-16T11:26:48.264-05:00",
    "is_hidden": false,
    "show_total": false,
    "grade_entry_items": [
      {
        "id": 1,
        "name": "Q1",
        "out_of": 3
      },
      {
        "id": 2,
        "name": "Q2",
        "out_of": 4
      },
      {
        "id": 3,
        "name": "Q3",
        "out_of": 5
      }
    ]
  }
]
```

### POST /api/courses/:course_id/grade_entry_forms

- description: Create a grade entry form for the given course
- required parameters:
    - short_identifier (string)
- optional parameters:
    - description (string)
    - is_hidden (boolean)
    - show_total (boolean)
    - due_date (string: that can be parsed into a Ruby DateTime object)
    - grade_entry_items:
        - name (string)
        - out_of (integer)
        - bonus (boolean)

### GET /api/courses/:course_id/grade_entry_forms/:id

- description: Display grade entry form information for a single form
- default response: CSV export of all student grades (backward compatible)
- JSON response: Use the `.json` extension or set the `Accept: application/json` header to receive structured JSON with student grades
- optional parameters (applies to both CSV and JSON):
    - user_names (list of strings: filter results to specific students)

#### CSV example (default)

```console
curl -H "Authorization: MarkUsAuth YourAuthKey" \
  "http://example.com/api/courses/1/grade_entry_forms/7"
```

Returns a CSV file with columns: User name, Last name, First name, Section name, Id number, Email, followed by one column per grade entry item.

#### JSON example

```console
curl -H "Authorization: MarkUsAuth YourAuthKey" \
  "http://example.com/api/courses/1/grade_entry_forms/7.json"
```

```json
{
  "id": 7,
  "short_identifier": "Quiz1",
  "description": "Class Quiz on Variables",
  "due_date": "2080-12-16T11:26:48.264-05:00",
  "is_hidden": false,
  "show_total": true,
  "grade_entry_items": [
    {
      "id": 1,
      "name": "Q1",
      "out_of": 3,
      "bonus": false
    },
    {
      "id": 2,
      "name": "Q2",
      "out_of": 4,
      "bonus": false
    }
  ],
  "students": [
    {
      "user_name": "c5anthei",
      "last_name": "George",
      "first_name": "Antheil",
      "id_number": "0000001",
      "email": "c5anthei@example.com",
      "section_name": "LEC0101",
      "grades": {
        "Q1": 2.0,
        "Q2": 1.0
      },
      "total_grade": 3.0
    }
  ]
}
```

#### JSON with user_names filter

```console
curl -H "Authorization: MarkUsAuth YourAuthKey" \
  "http://example.com/api/courses/1/grade_entry_forms/7.json?user_names[]=c5anthei"
```

Returns the same JSON structure but with only the matching students in the `students` array.

NOTE: `total_grade` is only included when `show_total` is `true`. Students with no grades have an empty `grades` object (`{}`). Hidden students are excluded.

### PUT api/courses/:course_id/grade_entry_forms/:id

- description: Update attributes for a grade entry form for the given course
- optional parameters:
    - short_identifier (string)
    - description (string)
    - is_hidden (boolean)
    - show_total (boolean)
    - due_date (string: that can be parsed into a Ruby DateTime object)
    - grade_entry_items:
        - id: (integer or null : if null a new grade_entry_item will be created)
        - name (string)
        - out_of (integer)
        - bonus (boolean)

## PUT /api/courses/:course_id/grade_entry_forms/:id/update_grades

- description: Update the grade(s) in this grade_entry_form for a student
- required parameters:
    - user_name (string : user name of a student in this course)
    - grade_entry_items (list of hashes: the key is a grade entry item name and the value is an integer or float to be assigned as a score. For example: `[{"Q1": 100}, {"Q2": 23}]`)

### GET /api/courses/:course_id/tags

- description: Display all tag information for a given course
- optional parameters:
    - [filter](#filter)
    - [fields](#fields)
- example response (json):

```json
[
  {
    "id": 20,
    "name": "tag1",
    "description": "desc",
    "creator": "user1",
    "use": 30,
  }
]
```

### POST /api/courses/:course_id/tags

- description: Create a new tag for a given course
- required parameters:
    - assignment_id (integer: id of the assignment of the tag)
    - name (string)
- optional parameters:
    - grouping_id (integer: id of grouping to pair the tag with)
    - description (string)

### PUT /api/courses/:course_id/tags/:id

- description: Update a given tag
- optional parameters:
    - name (string)
    - description (string)

### DELETE /api/courses/:course_id/tags/:id

- description: Delete a given tag

### GET /api/courses/:course_id/assignments

- description: Display all assignment information for the given course
- optional parameters:
    - [filter](#filter)
    - [fields](#fields)
- example response (json):

```json
[
  {
    "id": 18,
    "description": "Assignment the first",
    "short_identifier": "A1",
    "message": "",
    "due_date": "1934-12-23T12:09:24.976-05:00",
    "group_min": 1,
    "group_max": 1,
    "tokens_per_period": 0,
    "allow_web_submits": true,
    "student_form_groups": false,
    "remark_due_date": null,
    "remark_message": null,
    "assign_graders_to_criteria": false,
    "enable_test": true,
    "enable_student_tests": true,
    "allow_remarks": false,
    "display_grader_names_to_students": false,
    "group_name_autogenerated": false,
    "repository_folder": "autotest_racket",
    "is_hidden": false,
    "vcs_submit": false,
    "token_period": 1,
    "non_regenerating_tokens": false,
    "unlimited_tokens": true,
    "token_start_date": "1956-12-16T12:09:00.000-05:00",
    "has_peer_review": false,
    "starter_file_type": "simple",
    "default_starter_file_group_id": null
  }
]
```

### POST /api/courses/:course_id/assignments

- description: Create an assignment for the given course
- required parameters:
    - short_identifier (string)
    - description (string)
    - due_date (string: that can be parsed into a Ruby DateTime object)
- optional parameters:
    - message (string)
    - group_min (integer)
    - group_max (integer)
    - tokens_per_period (integer)
    - allow_web_submits (boolean)
    - student_form_groups (boolean)
    - remark_due_date (string: that can be parsed into a Ruby DateTime object)
    - remark_message (string)
    - assign_graders_to_criteria (boolean)
    - enable_test (boolean)
    - enable_student_tests (boolean)
    - allow_remarks (boolean)
    - display_grader_names_to_students (boolean)
    - group_name_autogenerated (boolean)
    - is_hidden (boolean)
    - vcs_submit (boolean)
    - token_period (integer)
    - non_regenerating_tokens (boolean)
    - unlimited_tokens (boolean)
    - token_start_date (string: that can be parsed into a Ruby DateTime object)
    - has_peer_review (boolean)
    - starter_file_type (one of "simple", "sections", "shuffle", "group")

### GET /api/courses/:course_id/assignments/:id

- description: Display attributes for a single assignment
- optional parameters:
    - [filter](#filter)
    - [fields](#fields)
- example response (json):

```json
{
  "id": 18,
  "description": "Assignment the first",
  "short_identifier": "A1",
  "message": "",
  "due_date": "1934-12-23T12:09:24.976-05:00",
  "group_min": 1,
  "group_max": 1,
  "tokens_per_period": 0,
  "allow_web_submits": true,
  "student_form_groups": false,
  "remark_due_date": null,
  "remark_message": null,
  "assign_graders_to_criteria": false,
  "enable_test": true,
  "enable_student_tests": true,
  "allow_remarks": false,
  "display_grader_names_to_students": false,
  "group_name_autogenerated": false,
  "repository_folder": "autotest_racket",
  "is_hidden": false,
  "vcs_submit": false,
  "token_period": 1,
  "non_regenerating_tokens": false,
  "unlimited_tokens": true,
  "token_start_date": "1956-12-16T12:09:00.000-05:00",
  "has_peer_review": false,
  "starter_file_type": "simple",
  "default_starter_file_group_id": null
}
```

### PUT /api/courses/:course_id/assignments/:id

- description: Update attributes for a single assignment
- optional parameters:
    - description (string)
    - due_date (string: that can be parsed into a Ruby DateTime object)
    - message (string)
    - group_min (integer)
    - group_max (integer)
    - tokens_per_period (integer)
    - allow_web_submits (boolean)
    - student_form_groups (boolean)
    - remark_due_date (string: that can be parsed into a Ruby DateTime object)
    - remark_message (string)
    - assign_graders_to_criteria (boolean)
    - enable_test (boolean)
    - enable_student_tests (boolean)
    - allow_remarks (boolean)
    - display_grader_names_to_students (boolean)
    - group_name_autogenerated (boolean)
    - is_hidden (boolean)
    - vcs_submit (boolean)
    - token_period (integer)
    - non_regenerating_tokens (boolean)
    - unlimited_tokens (boolean)
    - token_start_date (string: that can be parsed into a Ruby DateTime object)
    - has_peer_review (boolean)
    - starter_file_type (one of "simple", "sections", "shuffle", "group")

### DELETE /api/courses/:course_id/assignments/:id

- description: Delete the assignment corresponding to the given course and assignment id's, if it has no groups.
- required parameters:
    - id (integer)
    - course_id (integer)

NOTE: this is only available to authorised instructors (or admins)

### GET /api/courses/:course_id/assignments/:id/test_files

- description: Download a zip file containing all autotesting test files for this assignment

### GET /api/courses/:course_id/assignments/:id/grades_summary

- description: Download a csv file containing a summary of grades the given assignment

### GET /api/courses/:course_id/assignments/:id/test_specs

- description: Download a json string containing the autotesting settings for this assignment
- example response (json):

```json
{
  "testers": [
    {
      "test_data": [
        {
          "category": [
            "instructor"
          ],
          "extra_info": {
            "name": "Test group",
            "display_output": "instructors",
            "test_group_id": 12
          },
          "script_files": [],
          "timeout": 30
        }
      ],
      "tester_type": "java"
    }
  ]
}
```

### POST /api/courses/:course_id/assignments/:id/update_test_specs

- description: Update the autotesting settings for this assignment
- required parameters:
    - specs (json string : see the `GET test_specs` description above for an example of the expected format)

NOTE: This will also send the updated specs to the server running the autotester

### POST /api/courses/:course_id/assignments/:id/submit_file

- description: Submit a file in the currently authenticated user's groups repository for the given assignment. If the user does not yet have a group, this also creates a group for the user.
- required parameters:
    - filename (string)
    - mime_type (string)
    - file_content (string or binary data)

NOTE: This route is for STUDENT USE ONLY.

NOTE: the filename string can include a nested path if the file should be added in a subfolder (ex: "filename=some/nested/dir/submission.txt")

NOTE: not all parent directories need to exist in order to create a nested file. For example, if "filename=some/nested/dir/submission.txt"  and "some/" doesn't exist yet, then "some/", "some/nested", and "some/nested/dir" will all be created as well.

### GET /api/courses/:course_id/assignments/:assignment_id/groups

- description: Get all group information for the given assignment
- optional parameters:
    - [filter](#filter)
    - [fields](#fields)
- example response (json):

```json
[
  {
    "id": 1,
    "group_name": "group_0001",
    "members": [
      {
        "membership_status": "inviter",
        "role_id": 9
      },
      {
        "membership_status": "accepted",
        "role_id": 24
      }
    ]
  }
]
```

### POST /api/courses/:course_id/assignments/:assignment_id/groups

- description: Create a new group for the given assignment
- optional parameters:
    - new_group_name
    - members: a list of student usernames

### GET /api/courses/:course_id/assignments/:assignment_id/groups/annotations

- description: Get all annotation information for the given assignment
- example response (json):

```json
[
    {
    "type": "TextAnnotation",
    "content": "Ut magni.",
    "filename": "hello.py",
    "path": "A0",
    "page": null,
    "group_id": 15,
    "category": "asperiores",
    "creator_id": 1,
    "content_creator_id": 1,
    "line_end": 12,
    "line_start": 12,
    "column_start": 1,
    "column_end": 26,
    "x1": null,
    "y1": null,
    "x2": null,
    "y2": null
  },
  {
    "type": "PdfAnnotation",
    "content": "Officia et dolore.",
    "filename": "pdf.pdf",
    "path": "A0/another-test-files-in-inner-dirs",
    "page": 1,
    "group_id": 15,
    "category": "suscipit eos",
    "creator_id": 1,
    "content_creator_id": 1,
    "line_end": null,
    "line_start": null,
    "column_start": null,
    "column_end": null,
    "x1": 27740,
    "y1": 58244,
    "x2": 4977,
    "y2": 29748
  }
]
```

### GET /api/courses/:course_id/assignments/:assignment_id/groups/group_ids_by_name

- description: Get a mapping of group names to id for the given assignment
- example response (json):

```json
{
  "c9talmal": 204,
  "c8tchaik": 205,
  "g6takemi": 206,
  "c6weinbe": 207,
  "c7franca": 208,
  "c5nancar": 209,
  "c9simpso": 210,
  "c7kimear": 211,
  "g9koppel": 212,
  "c6lloydg": 213,
}
```

### GET /api/courses/:course_id/assignments/:assignment_id/groups/:id

- description: Get group information for a single group
- example response (json):

```json
{
  "id": 1,
  "group_name": "group_0001",
  "members": [
    {
      "membership_status": "inviter",
      "role_id": 9
    },
    {
      "membership_status": "accepted",
      "role_id": 24
    }
  ]
}
```

### GET /api/courses/:course_id/assignments/:assignment_id/groups/:id/annotations

- description: Get all annotations associated with the given group's submissions for the current assignment
- example response (json):

```json
[
    {
    "type": "TextAnnotation",
    "content": "Ut magni.",
    "filename": "hello.py",
    "path": "A0",
    "page": null,
    "group_id": 15,
    "category": "asperiores",
    "creator_id": 1,
    "content_creator_id": 1,
    "line_end": 12,
    "line_start": 12,
    "column_start": 1,
    "column_end": 26,
    "x1": null,
    "y1": null,
    "x2": null,
    "y2": null
  },
  {
    "type": "PdfAnnotation",
    "content": "Officia et dolore.",
    "filename": "pdf.pdf",
    "path": "A0/another-test-files-in-inner-dirs",
    "page": 1,
    "group_id": 15,
    "category": "suscipit eos",
    "creator_id": 1,
    "content_creator_id": 1,
    "line_end": null,
    "line_start": null,
    "column_start": null,
    "column_end": null,
    "x1": 27740,
    "y1": 58244,
    "x2": 4977,
    "y2": 29748
  }
]
```

### POST /api/courses/:course_id/assignments/:assignment_id/groups/:id/add_annotations

- description: Add one or more annotations to files submitted by the given group for the given assignment. All annotation types are supported (text, image, PDF, and HTML). The annotation type is determined by the file being annotated.
- required parameters:
    - annotations (list of hashes)
        - filename (string: the submission file to annotate)
        - content (string: the annotation's text content)
        - type (string, optional: one of "TextAnnotation", "ImageAnnotation", "PdfAnnotation", "HtmlAnnotation". If omitted, the type is derived from the file. If provided, it must match the file's type, otherwise the request is rejected.)
        - annotation_category_name (string, optional)
        - location fields, which depend on the annotation type (see below)
- optional parameters:
    - force_complete (boolean : whether to assign the annotation even if the marking is complete)

The annotation type is derived from the file being annotated:

| File | Extension(s) | Annotation type |
|------|--------------|-----------------|
| Image | `.jpeg`, `.jpg`, `.gif`, `.png`, `.heic`, `.heif` | `ImageAnnotation` |
| PDF | `.pdf` | `PdfAnnotation` |
| Notebook / R Markdown | `.ipynb`, `.Rmd` (when R Markdown conversion is enabled) | `HtmlAnnotation` |
| Anything else | — | `TextAnnotation` |

The location fields required for each annotation type are:

- `TextAnnotation`:
    - line_start (integer)
    - line_end (integer)
    - column_start (integer)
    - column_end (integer)
- `ImageAnnotation`:
    - x1, y1 (integers: top-left corner of the annotation rectangle)
    - x2, y2 (integers: bottom-right corner of the annotation rectangle)
- `PdfAnnotation`:
    - x1, y1 (integers: top-left corner of the annotation rectangle)
    - x2, y2 (integers: bottom-right corner of the annotation rectangle)
    - page (integer)
- `HtmlAnnotation`:
    - start_node (string)
    - start_offset (integer)
    - end_node (string)
    - end_offset (integer)

- example request body (json):

```json
{
  "annotations": [
    {
      "type": "TextAnnotation",
      "filename": "hello.py",
      "content": "Consider edge cases here",
      "line_start": 10,
      "line_end": 12,
      "column_start": 0,
      "column_end": 20
    },
    {
      "type": "PdfAnnotation",
      "filename": "essay.pdf",
      "content": "See the rubric",
      "x1": 100,
      "y1": 200,
      "x2": 300,
      "y2": 250,
      "page": 1
    }
  ]
}
```

NOTE: The `type` parameter is optional. When omitted, the type is derived from the file (see the table above). When provided, it must agree with the file — for example, you cannot create a `PdfAnnotation` on a `.py` file. A mismatch returns a 422.

NOTE: The entire request is validated before any annotation is created. If any annotation in the list is invalid — an unknown `type`, a `type`/file mismatch, an unknown `filename`, or a missing required location field for the type — the request is rejected with a 422 and no annotations are created.

### POST /api/courses/:course_id/assignments/:assignment_id/groups/:id/add_members

- description: Add members to the given group for the given assignment
- required parameters:
    - members (list of strings : user names of students to add to the group)

### POST /api/courses/:course_id/assignments/:assignment_id/groups/:id/create_extra_marks

- description: Add extra marks to the collected result for the given group for the given assignment.
- required parameters:
    - extra_marks (integer : can be positive or negative)
    - description (string)

### PUT /api/courses/:course_id/assignments/:assignment_id/groups/:id/update_marks

- description: Update the marks for a given group based on the criteria name.
- required paramters:
    - "criteria name" (integer)

NOTE: "criteria name" is not the actual name of the parameter but should be replaced by the name of a criteria created for the given assignment. For example, if a criteria exists with the name "code_style", and you want to set the mark for that criteria for the given group to 9, then include the paramter "code_style=9".

### PUT /api/courses/:course_id/assignments/:assignment_id/groups/:id/update_marking_state

- description: Set the marking state to either complete or incomplete for the collected result for the given group
- required parameters:
    - marking_state (one of "complete", "incomplete")

### DELETE /api/courses/:course_id/assignments/:assignment_id/groups/:id/remove_extra_marks

- description: Delete an extra mark assigned to the given group's result based on the description and mark value.
- required parameters:
    - extra_marks (integer : can be positive or negative)
    - description (string)

### DELETE /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/submission_files/remove_file

- description: Remove a file from a groups repository form the given assignment
- required parameters:
    - filename (string)

NOTE: the filename string can include a nested path if the file to remove is in a subfolder (ex: "filename=some/nested/dir/submission.txt")

### DELETE /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/submission_files/remove_folder

- description: Remove a folder from a groups repository for the given assignment
- required parameters:
    - folder_path (string)

NOTE: the folder_path string can include a nested path if the folder to remove is in a subfolder (ex: "folder_path=some/nested/dir/")

### POST /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/submission_files/create_folders

- description: Create a folder in a groups repository for the given assignment
- required parameters:
    - folder_path (string)

NOTE: the folder_path string can include a nested path if the folder should be added in a subfolder (ex: "folder_path=some/nested/dir/")

NOTE: not all parent directories need to exist in order to create a nested directory. For example, if "folder_path=some/nested/dir/"  and "some/" doesn't exist yet, then "some/", "some/nested", and "some/nested/dir" will all be created.

### POST /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/submission_files

- description: Create a file in a groups repository for the given assignment
- required parameters:
    - filename (string)
    - mime_type (string)
    - file_content (string or binary data)

NOTE: the filename string can include a nested path if the file should be added in a subfolder (ex: "filename=some/nested/dir/submission.txt")

NOTE: not all parent directories need to exist in order to create a nested file. For example, if "filename=some/nested/dir/submission.txt"  and "some/" doesn't exist yet, then "some/", "some/nested", and "some/nested/dir" will all be created as well.

### GET /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/submission_files

- description: Download a zip archive containing submission files submitted by the given group for the given assignment **or** the content of a single file
- optional parameters:
    - filename (string)
    - collected (boolean)

NOTE: the filename string can include a nested path if the requested file is in a subfolder (ex: "filename=some/nested/dir/submission.txt")

NOTE: if the collected parameter included, the collected version of the group's submission is downloaded. Otherwise the most recent verstion is downloaded

NOTE: if the filename parameter is given, only the content from a single file will be downloaded. Otherwise, a zip archive containing the entire submission will be downloaded.

### POST /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/feedback_files

- description: Create a feedback file for the given group for the given assignment
- required parameters:
    - filename (string)
    - mime_type (string)
    - file_content (string or binary data)

NOTE: adding feedback files to subdirectories is currently not supported

NOTE: the size of file_content must not exceed 1 GB.

### GET /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/feedback_files

- description: Get all feedback file information for a given group for a given assignment
- optional parameters:
    - [filter](#filter)
    - [fields](#fields)
- example response (json):

```json
[
  {
    "id": 13,
    "filename": "humanfb.txt"
  },
  {
    "id": 14,
    "filename": "machinefb.txt"
  }
]
```

### PUT /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/add_tag

- description: Add a tag to a grouping
- required parameters:
    - tag_id (integer)

### PUT /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/remove_tag

- description: Remove a tag from a grouping
- required parameters:
    - tag_id (integer)

### POST /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/collect_submission

- description: Collect submission from a grouping
- optional parameters:
    - collect_current (boolean)
    - revision_identifier (string, git commit hash identifier)
    - apply_late_penalty (boolean)
    - retain_existing_grading (boolean)

NOTE: collect_current value meanings:

- true: collect most recent files submitted, regardless of assignment due date or late period.
- false: collect most recent files submitted before the due date, including any late period.

### POST /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/add_test_results

- description: Submit automated test results for the given group for the given assignment. This endpoint is used by the autotesting service to report test execution results.
- required parameters:
    - test_results (object)
        - status (string: test execution status, e.g., "pass", "fail", "finished")
        - error (string or null: error message if test execution failed)
        - test_groups (array of objects)
            - time (integer or null: execution time in milliseconds)
            - tests (array of objects)
                - name (string: test name)
                - status (string: one of "pass", "partial", "fail", "error", "error_all")
                - marks_earned (integer: points earned)
                - marks_total (integer: maximum points)
                - output (string: test output/feedback)
                - time (integer or null: execution time in milliseconds)
            - extra_info (object)
                - name (string: test group name)
                - test_group_id (integer: ID of the test group)
                - display_output (integer: 0=instructors, 1=instructors_and_student_tests, 2=instructors_and_students)
                - criterion (string or null: associated criterion name)
- optional parameters (within test_groups):
    - timeout (integer: timeout value if test timed out)
    - stderr (string: standard error output)
    - malformed (string: malformed output information)
    - annotations (array of objects: code annotations to add)
        - content (string: annotation content)
        - filename (string: file to annotate)
        - type (string: "TextAnnotation", "ImageAnnotation", etc.)
        - line_start, line_end, column_start, column_end (integers: for text annotations)
        - x1, x2, y1, y2 (integers: for image/PDF annotations)
    - feedback (array of objects: feedback files to attach)
        - filename (string)
        - mime_type (string)
        - content (string: file content, may be base64 encoded)
        - compression (string: "gzip" if content is compressed)
    - tags (array of objects: tags to apply to the grouping)
        - name (string: tag name)
        - description (string: tag description)
    - overall_comment (string: overall comment to add to the result)
- example request body (json):

```json
{
  "test_results": {
    "status": "finished",
    "error": null,
    "test_groups": [
      {
        "time": 1250,
        "extra_info": {
          "name": "Correctness Tests",
          "test_group_id": 42,
          "display_output": 2,
          "criterion": "Correctness"
        },
        "tests": [
          {
            "name": "test_addition",
            "status": "pass",
            "marks_earned": 2,
            "marks_total": 2,
            "time": 125,
            "output": "All test cases passed"
          },
          {
            "name": "test_subtraction",
            "status": "fail",
            "marks_earned": 0,
            "marks_total": 2,
            "time": 98,
            "output": "Expected 5, got 3"
          }
        ],
        "annotations": [
          {
            "content": "Consider edge cases for negative numbers",
            "filename": "calculator.py",
            "line_start": 10,
            "line_end": 12,
            "column_start": 0,
            "column_end": 20
          }
        ],
        "tags": [
          {
            "name": "needs_review",
            "description": "Requires manual review"
          }
        ],
        "overall_comment": "Good attempt, but edge cases need work"
      }
    ]
  }
}
```

- example success response (json):

```json
{
  "status": "success",
  "test_run_id": 1234
}
```

NOTE: This endpoint creates a TestRun record with associated test results, annotations, feedback files, and tags. All operations are performed atomically within a transaction.

NOTE: The request body is validated against a schema and must not exceed 10MB in size.

NOTE: Authentication is required via API key. The authenticated user's role is used as the creator of the test run.

### GET /api/courses/:course_id/assignments/:assignment_id/groups/:id/test_results

- description: Get automated test results for the given group for the given assignment. Returns only the latest test run, grouped by test group name. Matches the UI download format.
- supported content types: `application/json`, `application/xml`
- example response (json):

```json
{
  "Test Group 1": [
    {
      "name": "Test Group 1",
      "test_groups_id": 7,
      "group_name": "group1",
      "test_result_name": "test_addition",
      "status": "pass",
      "marks_earned": 3.0,
      "marks_total": 5.0,
      "output": "All test cases passed",
      "extra_info": null,
      "error_type": null
    }
  ]
}
```

NOTE: This endpoint returns only the most recent test run results for the group, not historical test runs.

NOTE: Results are grouped by test group name (the keys in the JSON object are test group names).

NOTE: Supports XML responses by setting the `Accept` header to `application/xml` or using the `.xml` extension.

NOTE: Returns 404 if the group has no test results.

### GET /api/courses/:course_id/assignments/:assignment_id/groups/:id/test_runs

- description: Get test runs for the given group for the given assignment. Returns all test runs and the associated test group results.
- supported content types: `application/json`, `application/xml`
- example response (json):

```json
[
  {
    "id": 1,
    "test_batch_id": null,
    "grouping_id": 123,
    "created_at": "2026-06-26T13:22:57.032-04:00",
    "updated_at": "2026-06-26T13:23:08.271-04:00",
    "submission_id": 456,
    "revision_identifier": null,
    "problems": null,
    "autotest_test_id": null,
    "status": "complete",
    "role_id": 1,
    "test_group_results": [
          {
            "id": 8,
            "test_group_id": 23,
            "marks_earned": 1.0,
            "created_at": "2026-06-26T13:23:08.298-04:00",
            "updated_at": "2026-06-26T13:23:08.327-04:00",
            "time": 100,
            "marks_total": 3.0,
            "test_run_id": 1,
            "extra_info": null,
            "error_type": null
          },
          {
            "id": 9,
            "test_group_id": 24,
            "marks_earned": 5.0,
            "created_at": "2026-06-26T13:23:08.338-04:00",
            "updated_at": "2026-06-26T13:23:08.541-04:00",
            "time": 200,
            "marks_total": 9.0,
            "test_run_id": 1,
            "extra_info": null,
            "error_type": null
          }
        ]
  },
  {
    "id": 2,
    "test_batch_id": null,
    "grouping_id": 123,
    "created_at": "2026-06-26T13:23:14.346-04:00",
    "updated_at": "2026-06-26T13:23:25.660-04:00",
    "submission_id": null,
    "revision_identifier": "251f484fa09488ac165f8396112c2b13e60d0cbe",
    "problems": null,
    "autotest_test_id": null,
    "status": "complete",
    "role_id": 2,
    "test_group_results": [
      {
        "id": 10,
        "test_group_id": 24,
        "marks_earned": 5.0,
        "created_at": "2026-06-26T13:23:25.694-04:00",
        "updated_at": "2026-06-26T13:23:25.745-04:00",
        "time": 300,
        "marks_total": 9.0,
        "test_run_id": 2,
        "extra_info": null,
        "error_type": null
      }
    ]
  }
]
```

### GET /api/course/:course_id/assignments/:assignment_id/groups/:id/overall_comment

- description: Get the overall comment in the results for the given group for the given assignment for the given course
- supported content types: `application/json`, `application/xml`

### PATCH /api/course/:course_id/assignments/:assignment_id/groups/:id/overall_comment

- description: Update the overall comment in the results for the given group for the given assignment for the given course
- required parameters:
    - overall_comment

NOTE: Returns 422 if the assignment results have been released to students

### POST /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/extension

- description: Create an extension for the given group for the given assignment
- required parameters:
    - extension
        - time_delta
            - weeks (integer)
            - days (integer)
            - hours (integer)
            - minutes (integer)
        - apply_penalty (boolean, optional)
        - note (string, optional)

NOTE: for time_delta, at least one of the following is required: weeks, days, hours, minutes.

### PATCH /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/extension

- description: Update an extension for the given group for the given assignment
- required parameters:
    - extension
        - time_delta
            - weeks (integer)
            - days (integer)
            - hours (integer)
            - minutes (integer)
        - apply_penalty (boolean, optional)
        - note (string, optional)

NOTE: for time_delta, at least one of the following is required: weeks, days, hours, minutes.

### DELETE /api/courses/:course_id/assignments/:assignment_id/groups/:group_id/extension

- description: Delete an extension for the given group for the given assignment

### GET /api/courses/:course_id/feedback_files/:id

- description: Download the content of the given feedback file

### PUT /api/courses/:course_id/feedback_files/:id

- description: update the filename or content of the given feedback file
- optional parameters:
    - filename (string)
    - file_content (string or binary data)

### DELETE /api/courses/:course_id/feedback_files/:id

- description: delete the given feedback file

### GET /api/courses/:course_id/assignments/:assignment_id/starter_file_groups

- description: get information about all starter file groups for the given assignment
- example response (json):

```json
[
  {
    "id": 4,
    "assessment_id": 1,
    "entry_rename": "",
    "use_rename": false,
    "name": "A starter file group"
  },
  {
    "id": 5,
    "assessment_id": 1,
    "entry_rename": "",
    "use_rename": false,
    "name": "another one"
  }
]
```

### POST /api/courses/:course_id/assignments/:assignment_id/starter_file_groups

- description: create a starter file group for the given assignment
- required parameters:
    - name (string)
- optional parameters:
    - entry_rename (string)
    - use_rename (boolean)

NOTE: if use_rename is true then files (or folders) assigned as starter files from this starter file group will be renamed to the value of entry_rename when the students download the starter files (see the [starter file documentation](../instructors/assignments/starter-files.md) for more details)

### GET /api/courses/:course_id/starter_file_groups/:id

- description: get information about a single starter file group
- example response (json):

```json
{
  "id": 4,
  "assessment_id": 1,
  "entry_rename": "",
  "use_rename": false,
  "name": "A starter file group"
}
```

### PUT /api/courses/:course_id/starter_file_groups/:id

- description: update the attributes of a starter file group
- required parameters:
    - name (string)
- optional parameters:
    - entry_rename (string)
    - use_rename (boolean)

### DELETE /api/courses/:course_id/starter_file_groups/:id

- description: delete a starter file group

### GET /api/courses/:course_id/starter_file_groups/:id/entries

- description: get the path of all files and folders in this starter file group
- example response (json):

```json
[
  "instructions.md",
  "some/",
  "some/subfolder/",
  "some/subfolder/textfile.txt",
]
```

### POST /api/courses/:course_id/starter_file_groups/:id/create_file

- description: Add a file to the given starter file group
- required parameters:
    - filename (string)
    - file_content (string or binary data)

NOTE: the filename string can include a nested path if the given file is in a subfolder (ex: "filename=some/nested/dir/submission.txt")

### POST /api/courses/:course_id/starter_file_groups/:id/create_folder

- description: Add a folder to the given starter file group
- required parameters:
    - folder_path (string)

NOTE: the folder_path string can include a nested path if the folder should be added in a subfolder (ex: "folder_path=some/nested/dir/")

### DELETE /api/courses/:course_id/starter_file_groups/:id/remove_file

- description: Delete a folder from the given starter file group
- required parameters:
    - filename (string)

NOTE: the filename string can include a nested path if the requested file is in a subfolder (ex: "filename=some/nested/dir/submission.txt")

### DELETE /api/courses/:course_id/starter_file_groups/:id/remove_folder

- description: Delete a folder from the given starter file group
- required parameters:
    - folder_path (string)

NOTE: the folder_path string can include a nested path if the folder to be removed is in a subfolder (ex: "folder_path=some/nested/dir/")

### GET /api/courses/:course_id/starter_file_groups/:id/download_entries

- description: Download a zip archive containing all entries (files and folders) in this starter file group

### POST /api/courses/:course_id/sections

- description: Create a new section for the given course.
- required parameters:
    - section
        - name (string)

### DELETE /api/courses/:course_id/sections/:id

- description: Delete the section uniquely identified by the given course and section id's.
- NOTE: The section must be non-empty (must not have any students).

### PUT /api/courses/:course_id/sections/:id

- description: Update the section uniquely identified by the given course and section id's.
- required parameters:
    - name (string)

### GET /api/courses/:course_id/sections

- description: Get all sections for this course

### GET /api/courses/:course_id/sections/:id

- description: Get the section uniquely identified by the given course and section id's.
