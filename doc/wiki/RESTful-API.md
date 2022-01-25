# RESTful API Documentation

This document provides an overview of the MarkUs RESTful API for use by developers as well as instructors. The API allows the use of standard HTTP methods such as GET, PUT, POST and DELETE to manipulate and retrieve resources. Those resources may also be retrieved either individually or from within collections.

## General

### Authentication

Authentication with the RESTful API is done using the HTTP Authorization header. The authorization method used is "MarkUsAuth", and should precede the encoded API token that can be found on the MarkUs Dashboard.

To retrieve your API token: 1. Log in to MarkUs as an Admin or TA 2. Scroll to the bottom of the page, where you'll find your API key/token

Given `MzNjMDcwMDhjZjMzY2E0NjdhODM2YWRkZmFhZWVjOGE=` as one's MarkUs API token, an example header would include: `Authorization: MarkUsAuth MzNjMDcwMDhjZjMzY2E0NjdhODM2YWRkZmFhZWVjOGE=`

To test your auth key, feel free to try the following from a terminal:

    curl -H "Authorization: MarkUsAuth YourAuthKey" "http://example.com/api/users"

Replacing YourAuthKey and the example.com as necessary, the above command would return a list of all users in that particular MarkUs installation. Otherwise, if the authentication isn't successful, you'll receive an error with a 403 Forbidden HTTP Status Code. (should be 401 Unauthorized)

**Resetting Authentication Keys**

In case of stolen authentication tokens, they can be globally reset by the system administrator using the *markus:reset\_api\_key* rake task. For example:

    $ cd path/to/markus/app
    $ bundle exec rake markus:reset_api_key

### Response Formats

As with other RESTful APIs, both XML and JSON responses are supported. XML version 1.0 with UTF-8 encoding is the default response format used by the API. As would be expected, the response consists of an XML declaration followed by a root element, attributes, and may contain child elements and nested attributes. Due to it being the default format, the API will respond with XML if a .xml extension is present in the URL, or if no extension is provided. The following is an example XML response:

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

If a .json extension is used in the URL, a JSON response will be rendered. Its simpler format consists of objects, represented as associative arrays. To request a JSON response using CURL, one can use the following:

    curl -H "Authorization: MarkUsAuth YourAuthKey" "http://example.com/api/users/1.json"

Which would result in the following output (which has been formatted for readability):

    {
      "id":1,
      "last_name":"admin",
      "first_name":"admin",
      "notes_count":1,
      "type":"Admin",
      "user_name":"a",
      "grace_credits":0
    }

### RESTful Resources

Methods on resources and collections available via the MarkUs API conform to Rails' RESTful routes. They consist of the following:

    GET    - collection - List resources along with attributes in a collection
    POST   - collection - Create a new entry in the collection
    GET    - resource   - Retrieve a single resource
    PUT    - resource   - Replace a resource, or update parts of a resource
    DELETE - resource   - Delete a resource

And the above correspond to the following default Rails routes: index, new, show, update, and destroy. Furthermore, nested routes allow us to take advantage of the relationship between different collections, sub-collections, and resources.

For example, a GET request on `/api/users`, with users being a collection, would return all users by default assuming no filters or other arguments. `/api/users/1`, which corresponds to a resource in the collection of users, would return only that user which identified by the unique id 1. To further illustrate, `/api/users/1/notes`, with notes being a sub-collection, would return a list of all notes related to the user identified by the id 1. Sub-collections return only those resources which belong or apply to the parent resource.

### Available Routes

[`POST     /api/users/create_or_unhide`](#post-apiuserscreate_or_unhide)
[`PUT      /api/users/update_by_username`](#put-apiusersupdate_by_username)
[`GET      /api/users`](#get-apiusers)
[`POST     /api/users`](#post-apiusers)
[`GET      /api/users/:id`](#get-apiusersid)
[`PUT      /api/users/:id`](#put-apiusersid)
[`DELETE   /api/users/:id`](#delete-apiusersid)

[`PUT      /api/grade_entry_forms/:id/update_grades`](#put-apigrade_entry_formsidupdate_grades)
[`GET      /api/grade_entry_forms`](#get-apigrade_entry_forms)
[`POST     /api/grade_entry_forms`](#post-apigrade_entry_forms)
[`GET      /api/grade_entry_forms/:id`](#get-apigrade_entry_formsid)
[`PUT      /api/grade_entry_forms/:id`](#put-apigrade_entry_formsid)

[`DELETE   /api/assignments/:assignment_id/groups/:group_id/submission_files/remove_file`](#delete-apiassignmentsassignment_idgroupsgroup_idsubmission_filesremove_file)
[`DELETE   /api/assignments/:assignment_id/groups/:group_id/submission_files/remove_folder`](#delete-apiassignmentsassignment_idgroupsgroup_idsubmission_filesremove_folder)
[`POST     /api/assignments/:assignment_id/groups/:group_id/submission_files/create_folders`](#post-apiassignmentsassignment_idgroupsgroup_idsubmission_filescreate_folders)
[`GET      /api/assignments/:assignment_id/groups/:group_id/submission_files`](#get-apiassignmentsassignment_idgroupsgroup_idsubmission_files)
[`POST     /api/assignments/:assignment_id/groups/:group_id/submission_files`](#post-apiassignmentsassignment_idgroupsgroup_idsubmission_files)

[`GET      /api/assignments/:assignment_id/groups/:group_id/feedback_files`](#get-apiassignmentsassignment_idgroupsgroup_idfeedback_files)
[`POST     /api/assignments/:assignment_id/groups/:group_id/feedback_files`](#post-apiassignmentsassignment_idgroupsgroup_idfeedback_files)
[`GET      /api/assignments/:assignment_id/groups/:group_id/feedback_files/:id`](#get-apiassignmentsassignment_idgroupsgroup_idfeedback_filesid)
[`PUT      /api/assignments/:assignment_id/groups/:group_id/feedback_files/:id`](#put-apiassignmentsassignment_idgroupsgroup_idfeedback_filesid)
[`DELETE   /api/assignments/:assignment_id/groups/:group_id/feedback_files/:id`](#delete-apiassignmentsassignment_idgroupsgroup_idfeedback_filesid)

[`GET      /api/assignments/:assignment_id/groups/:group_id/test_group_results`](#get-apiassignmentsassignment_idgroupsgroup_idtest_group_results)
[`POST     /api/assignments/:assignment_id/groups/:group_id/test_group_results`](#post-apiassignmentsassignment_idgroupsgroup_idtest_group_results)
[`GET      /api/assignments/:assignment_id/groups/:group_id/test_group_results/:id`](#get-apiassignmentsassignment_idgroupsgroup_idtest_group_resultsid)
[`PUT      /api/assignments/:assignment_id/groups/:group_id/test_group_results/:id`](#put-apiassignmentsassignment_idgroupsgroup_idtest_group_resultsid)
[`DELETE   /api/assignments/:assignment_id/groups/:group_id/test_group_results/:id`](#delete-apiassignmentsassignment_idgroupsgroup_idtest_group_resultsid)

[`GET      /api/assignments/:assignment_id/groups/:group_id/test_group_results/:test_group_result_id/test_results`](#get-apiassignmentsassignment_idgroupsgroup_idtest_group_resultstest_group_result_idtest_results)
[`POST     /api/assignments/:assignment_id/groups/:group_id/test_group_results/:test_group_result_id/test_results`](#post-apiassignmentsassignment_idgroupsgroup_idtest_group_resultstest_group_result_idtest_results)
[`GET      /api/assignments/:assignment_id/groups/:group_id/test_group_results/:test_group_result_id/test_results/:id`](#get-apiassignmentsassignment_idgroupsgroup_idtest_group_resultstest_group_result_idtest_resultsid)
[`PUT      /api/assignments/:assignment_id/groups/:group_id/test_group_results/:test_group_result_id/test_results/:id`](#put-apiassignmentsassignment_idgroupsgroup_idtest_group_resultstest_group_result_idtest_resultsid)
[`DELETE   /api/assignments/:assignment_id/groups/:group_id/test_group_results/:test_group_result_id/test_results/:id`](#delete-apiassignmentsassignment_idgroupsgroup_idtest_group_resultstest_group_result_idtest_resultsid)

[`GET      /api/assignments/:assignment_id/groups/annotations`](#get-apiassignmentsassignment_idgroupsannotations)
[`GET      /api/assignments/:assignment_id/groups/group_ids_by_name`](#get-apiassignmentsassignment_idgroupsgroup_ids_by_name)
[`GET      /api/assignments/:assignment_id/groups/:id/annotations`](#get-apiassignmentsassignment_idgroupsidannotations)
[`POST     /api/assignments/:assignment_id/groups/:id/add_annotations`](#post-apiassignmentsassignment_idgroupsidadd_annotations)
[`POST     /api/assignments/:assignment_id/groups/:id/add_members`](#post-apiassignmentsassignment_idgroupsidadd_members)
[`POST     /api/assignments/:assignment_id/groups/:id/create_extra_marks`](#post-apiassignmentsassignment_idgroupsidcreate_extra_marks)
[`PUT      /api/assignments/:assignment_id/groups/:id/update_marks`](#put-apiassignmentsassignment_idgroupsidupdate_marks)
[`PUT      /api/assignments/:assignment_id/groups/:id/update_marking_state`](#put-apiassignmentsassignment_idgroupsidupdate_marking_state)
[`DELETE   /api/assignments/:assignment_id/groups/:id/remove_extra_marks`](#delete-apiassignmentsassignment_idgroupsidremove_extra_marks)
[`GET      /api/assignments/:assignment_id/groups`](#get-apiassignmentsassignment_idgroups)
[`GET      /api/assignments/:assignment_id/groups/:id`](#get-apiassignmentsassignment_idgroupsid)

[`GET      /api/assignments/:assignment_id/starter_file_groups/:id/entries`](#get-apiassignmentsassignment_idstarter_file_groupsidentries)
[`POST     /api/assignments/:assignment_id/starter_file_groups/:id/create_file`](#post-apiassignmentsassignment_idstarter_file_groupsidcreate_file)
[`POST     /api/assignments/:assignment_id/starter_file_groups/:id/create_folder`](#post-apiassignmentsassignment_idstarter_file_groupsidcreate_folder)
[`DELETE   /api/assignments/:assignment_id/starter_file_groups/:id/remove_file`](#delete-apiassignmentsassignment_idstarter_file_groupsidremove_file)
[`DELETE   /api/assignments/:assignment_id/starter_file_groups/:id/remove_folder`](#delete-apiassignmentsassignment_idstarter_file_groupsidremove_folder)
[`GET      /api/assignments/:assignment_id/starter_file_groups/:id/download_entries`](#get-apiassignmentsassignment_idstarter_file_groupsiddownload_entries)
[`GET      /api/assignments/:assignment_id/starter_file_groups`](#get-apiassignmentsassignment_idstarter_file_groups)
[`POST     /api/assignments/:assignment_id/starter_file_groups`](#post-apiassignmentsassignment_idstarter_file_groups)
[`GET      /api/assignments/:assignment_id/starter_file_groups/:id`](#get-apiassignmentsassignment_idstarter_file_groupsid)
[`PUT      /api/assignments/:assignment_id/starter_file_groups/:id`](#put-apiassignmentsassignment_idstarter_file_groupsid)
[`DELETE   /api/assignments/:assignment_id/starter_file_groups/:id`](#delete-apiassignmentsassignment_idstarter_file_groupsid)

[`GET      /api/assignments/:id/test_files`](#get-apiassignmentsidtest_files)
[`GET      /api/assignments/:id/grades_summary`](#get-apiassignmentsidgrades_summary)
[`GET      /api/assignments/:id/test_specs`](#get-apiassignmentsidtest_specs)
[`POST     /api/assignments/:id/update_test_specs`](#post-apiassignmentsidupdate_test_specs)
[`GET      /api/assignments`](#get-apiassignments)
[`POST     /api/assignments`](#post-apiassignments)
[`GET      /api/assignments/:id`](#get-apiassignmentsid)
[`PUT      /api/assignments/:id`](#put-apiassignmentsid)

#### POST /api/users/create_or_unhide

Creates a new user or unhides a user if they already exist

##### Parameters

- `user_name` (string, required)
- `type` (string, required, one of: [admin, ta, student])
- `first_name` (string, required)
- `last_name` (string, required)
- `section_name` (string)
- `grace_credits` (integer)

##### CURL example

```sh
curl 'http://example.com/api/users/create_or_unhide.json' --data '{"user_name": "testuser", "type": "admin", "first_name": "test", "last_name": "user"}' -H "Content-Type: application/json" -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

When creating:

```json
{
  "code": "201",
  "description": "The resource has been created."
}
```

When unhiding:

```json
{
  "code": "200",
  "description": "Success"
}
```

#### PUT /api/users/update_by_username

Update a user's attributes based on their user_name as opposed to their id (use the regular update method instead)

##### Parameters

same as [PUT /api/users/:id](#put-apiusersid) but requires `user_name`

##### CURL example

```sh
curl -X PUT 'http://example.com/api/users/update_by_username.json' --data '{"user_name": "testuser","first_name": "new_name"}' -H "Content-Type: application/json"  -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### GET /api/users

Get all user information

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/users.json' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
[
  {
    "id": 246,
    "user_name": "yyyy",
    "last_name": "asfda",
    "first_name": "sd",
    "grace_credits": 0,
    "type": "Ta",
    "email": "yyy@example.com",
    "id_number": "0123456789",
    "hidden": false,
    "notes_count": 0
  },
  {
    "id": 247,
    "user_name": "testuser",
    "last_name": "user",
    "first_name": "new_name",
    "grace_credits": 0,
    "type": "Admin",
    "email": "user@example.com",
    "id_number": "5678901234",
    "hidden": false,
    "notes_count": 0
  }
]
```

#### POST /api/users

##### Parameters

- `user_name` (string, required)
- `type` (string, required, one of: [admin, ta, student])
- `first_name` (string, required)
- `last_name` (string, required)
- `section_name` (string)
- `grace_credits` (integer)

##### CURL example

```sh
curl 'http://example.com/api/users.json' --data '{"user_name": "testuser", "type": "admin", "first_name": "test", "last_name": "user"}' -H "Content-Type: application/json" -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### GET /api/users/:id

Get user information for a single user

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/users/1.json' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
{
  "id": 1,
  "user_name": "a",
  "last_name": "admin",
  "first_name": "admin",
  "grace_credits": 0,
  "type": "Admin",
  "email": "user@example.com",
  "id_number": "5678901234",
  "hidden": false,
  "notes_count": 0
}
```

#### PUT /api/users/:id

Update a single user

##### Parameters

- `user_name` (string)
- `type` (string, one of: [admin, ta, student])
- `first_name` (string)
- `last_name` (string)
- `section_name` (string)
- `grace_credits` (integer)

##### CURL example

```sh
curl -X PUT 'http://example.com/api/users/247.json' --data '{"first_name": "newuser2"}'  -H "Authorization: MarkUsAuth myapikeyhere" -H "Content-Type: application/json"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### DELETE /api/users/:id

Delete a user.

> :spiral_notepad: **Note**: currently, users cannot be deleted from MarkUs

##### Parameters

None

##### CURL example

```sh
curl -X DELETE 'http://example.com/api/users/247.json' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### PUT /api/grade_entry_forms/:id/update_grades

Update grades for a user on a grade entry form

##### Parameters

- `user_name` (string, required)
- `grade_entry_items` (list of lists, required)
	- [[column name (string), mark (integer)]]

##### CURL example

```sh
curl -X PUT 'http://example.com/api/grade_entry_forms/8/update_grades.json' --data '{"user_name": "g9schuma", "grade_entry_items": [["Q1", 2], ["Q3", 6]]}'  -H "Authorization: MarkUsAuth myapikeyhere" -H "Content-Type: application/json"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### GET /api/grade_entry_forms

Get information about all grade entry forms

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/grade_entry_forms.json' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
[
  {
    "id": 8,
    "short_identifier": "Quiz2",
    "description": "Class Quiz on Conditionals",
    "is_hidden": true,
    "show_total": false,
    "grade_entry_items": [
      {
        "id": 4,
        "name": "Q1",
        "out_of": 6
      },
      {
        "id": 5,
        "name": "Q2",
        "out_of": 7
      },
      {
        "id": 6,
        "name": "Q3",
        "out_of": 8
      }
    ]
  }
]
```


#### POST /api/grade_entry_forms

Create a new grade entry form

##### Parameters

- `short_identifier` (string, required)
- `description` (string, required)
- `date` (datetime string)
- `is_hidden` (boolean)
- `grade_entry_items` (list of hashes)
	- [{`name` (string, required),
		`out_of` (integer, required),
		`bonus` (boolean, required)}]

##### CURL example

```sh
curl -X POST 'http://example.com/api/grade_entry_forms.json' --data '{"short_identifier": "Form3", "description": "3rd form", "grade_entry_items": [{"name": "Q1", "out_of": 2, "bonus": false}, {"name": "Q2", "out_of": 10, "bonus": true}]}'  -H "Authorization: MarkUsAuth myapikeyhere" -H "Content-Type: application/json"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### GET /api/grade_entry_forms/:id

Get grade information from a grade entry form (as csv data)

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/grade_entry_forms/8' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```csv
"",Q1,Q2,Q3
Out Of,6.0,7.0,8.0
c5anthei,1.0,5.0,3.0
c5bennet,"","",""
c5berkel,5.0,2.0,0.0
```

#### PUT /api/grade_entry_forms/:id

Update a grade entry form

##### Parameters

- `description` (string, required)
- `date` (datetime string)
- `is_hidden` (boolean)
- `grade_entry_items` (list of hashes)
	- [{`name` (string, required),
		`out_of` (integer, required),
		`bonus` (boolean, required)}]

##### CURL example
```sh
curl -X PUT 'http://example.com/api/grade_entry_forms/12.json' --data '{"description": "4th form", "grade_entry_items": [{"name": "Q5", "out_of": 2, "bonus": false}]}'  -H "Authorization: MarkUsAuth myapikeyhere" -H "Content-Type: application/json"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### DELETE /api/assignments/:assignment_id/groups/:group_id/submission_files/remove_file

##### Parameters

- `filename` (string, required)

##### CURL example

```sh
curl -X DELETE 'http://example.com/api/assignments/1/groups/5/submission_files/remove_file.json' -F 'filename=About.md' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### DELETE /api/assignments/:assignment_id/groups/:group_id/submission_files/remove_folder

##### Parameters

- `folder_path` (string, required)

##### CURL example

```sh
curl -X DELETE 'http://example.com/api/assignments/1/groups/5/submission_files/remove_folder.json' -F 'folder_path=new/path' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```


#### POST /api/assignments/:assignment_id/groups/:group_id/submission_files/create_folders

Create a folder in the group's repository.

> :spiral_notepad: **Note**: file_path can contain a relative path from the assignment root directory.

##### Parameters

- `folder_path` (string, required)

##### CURL example

```sh
curl -X POST 'http://example.com/api/assignments/1/groups/5/submission_files/create_folders.json' -F 'folder_path=new/path/here' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
{
  "code": "201",
  "description": "The resource has been created."
}
```


#### GET /api/assignments/:assignment_id/groups/:group_id/submission_files

Download a zip file containing all submission files for the given group

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/assignments/1/groups/5/submission_files'  -H "Authorization: MarkUsAuth myapikeyhere" -H "Content-Type: application/json"
```

##### Example Response

Binary data (zip file contents)

#### POST /api/assignments/:assignment_id/groups/:group_id/submission_files

Upload a file to the group's repository.

> :spiral_notepad: **Note**: filename can contain a relative path from the assignment root directory.

##### Parameters

- `filename` (string, required)
- `mime_type` (string, required)
- `file_content` (file data, required)

##### CURL example

```sh
curl -X POST 'http://example.com/api/assignments/1/groups/5/submission_files.json' --data-binary 'filename=About.md' --data-binary 'mime_type=text/plain' --data-binary 'file_content=@./About.md' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
{
  "code": "201",
  "description": "The resource has been created."
}
```

#### GET /api/assignments/:assignment_id/groups/:group_id/feedback_files

Get info about all feedback files for this group

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/assignments/1/groups/5/feedback_files.json' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

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


#### POST /api/assignments/:assignment_id/groups/:group_id/feedback_files

Create a new feedback file for the given group

##### Parameters

- `filename` (string, required)
- `mime_type` (string)
- `file_content` (file data or string, required)

##### CURL example

```sh
curl -X POST 'http://example.com/api/assignments/1/groups/5/feedback_files.json' -F 'filename=feedback.txt' -F 'mime_type=text/plain' -F 'file_content="some content"'  -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
{
  "code": "201",
  "description": "The resource has been created."
}
```


#### GET /api/assignments/:assignment_id/groups/:group_id/feedback_files/:id

Get the content of a feedback file

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/assignments/1/groups/5/feedback_files/13.json' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

file content as a string

#### PUT /api/assignments/:assignment_id/groups/:group_id/feedback_files/:id

Update the content or filename of a feedback file.

##### Parameters

- `filename` (string)
- `file_content` (file data or string)

##### CURL example

```sh
curl -X PUT 'http://example.com/api/assignments/1/groups/5/feedback_files/13.json' -F 'filename=feedback2.txt' -F 'mime_type=text/plain' -F 'file_content="some content"' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### DELETE /api/assignments/:assignment_id/groups/:group_id/feedback_files/:id

Delete a feedback file

##### Parameters

None

##### CURL example

```sh
curl -X DELETE 'http://example.com/api/assignments/1/groups/5/feedback_files/13.json' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### GET /api/assignments/:assignment_id/groups/:group_id/test_group_results

Get automated test results for a given submission

##### Parameters

- `submission_id` (integer, required)

##### CURL example

```sh
curl 'http://example.com/api/assignments/1/groups/1/test_group_results.json?submission_id=9' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
[
  {
    "id": 1,
    "test_group_id": 1,
    "marks_earned": 0,
    "created_at": "2020-09-02T13:50:40.150-04:00",
    "updated_at": "2020-09-02T13:50:40.205-04:00",
    "time": 1493,
    "marks_total": 10,
    "test_run_id": 2,
    "extra_info": null,
    "error_type": null,
    "test_results": [
      {
        "id": 1,
        "name": "PyTA internet.py",
        "status": "fail",
        "marks_earned": 0,
        "output": "153 error(s)",
        "created_at": "2020-09-02T13:50:40.192-04:00",
        "updated_at": "2020-09-02T13:50:40.192-04:00",
        "marks_total": 10,
        "time": null,
        "test_group_result_id": 1
      }
    ]
  }
]
```

#### POST /api/assignments/:assignment_id/groups/:group_id/test_group_results

Create a new test group result. This route is used by the autotester.

##### Parameters

- `test_run_id` (integer, required)
- `test_output` (json string, required)
  - json string represents a hash with the following fields:
    ```
    {
      "test_groups": [
        {
          "time": (integer, required), # time it took to run all tests in the group in seconds
          "timeout": (integer), # if the tests timed out, the duration of the timeout in seconds
          "stderr": (string), # error messages written to stderr while running the tests
          "malformed": (string), # malformed test results
          "extra_info": (hash, required), # extra info from the test settings (should contain "test_group_id" key)
          "tests": [
            {
              "name": (string, required),  # name of the test
              "status": (string, required), # one of 'pass', 'fail', 'partial', 'error'
              "marks_earned": (number, required), # marks earned by the test
              "output": (string, required), # output returned by the test
              "marks_total": (number, required), # total possible marks for the test
              "time": (integer), # time it took to run the test in seconds
            }
          ]
        }
      ],
      "error": (string, required), # error messages from running the tests
      "hooks_error": (string, required), # error messages from running the callback hooks around the tests
      "time_to_service": (integer, required) # amount of time the test waited in the queue
    }
    ```

##### CURL example

```sh
curl -X POST 'http://example.com/api/assignments/1/groups/1/test_group_results.json' -F 'test_output={"test_groups":[{"time":20, "extra_info": {"test_group_id": 1}, "tests":[{"name": "test100", "status": "pass", "marks_earned": 5, "marks_total": 5, "output": "good job!"}]}], "error": "", "hooks_error": "", "time_to_service": 10}' -F 'test_run_id=3' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
{
  "code": "201",
  "description": "The resource has been created."
}
```

#### GET /api/assignments/:assignment_id/groups/:group_id/test_group_results/:id

Get one automated test result for a given submission

##### Parameters


- `submission_id` (integer, required)

##### CURL example

```sh
curl 'http://example.com/api/assignments/1/groups/1/test_group_results/1.json?submission_id=9' -H "Authorization: MarkUsAuth myapikeyhere"
```

##### Example Response

```json
  {
    "id": 1,
    "test_group_id": 1,
    "marks_earned": 0,
    "created_at": "2020-09-02T13:50:40.150-04:00",
    "updated_at": "2020-09-02T13:50:40.205-04:00",
    "time": 1493,
    "marks_total": 10,
    "test_run_id": 2,
    "extra_info": null,
    "error_type": null,
    "test_results": [
      {
        "id": 1,
        "name": "PyTA internet.py",
        "status": "fail",
        "marks_earned": 0,
        "output": "153 error(s)",
        "created_at": "2020-09-02T13:50:40.192-04:00",
        "updated_at": "2020-09-02T13:50:40.192-04:00",
        "marks_total": 10,
        "time": null,
        "test_group_result_id": 1
      }
    ]
  }
```


#### PUT /api/assignments/:assignment_id/groups/:group_id/test_group_results/:id

Update the test group result by deleting the associated test result and creating a new one

##### Parameters

Same as [GET /api/assignments/:assignment_id/groups/:group_id/test_group_results/:id](#post-apiassignmentsassignment_idgroupsgroup_idtest_group_results)

##### CURL example

```sh
curl -X PUT 'http://example.com/api/assignments/1/groups/1/test_group_results/3.json' -F 'test_output={"test_groups":[{"time":20, "extra_info": {"test_group_id": 1}, "tests":[{"name": "test100", "status": "pass", "marks_earned": 5, "marks_total": 10, "output": "good job!"}]}], "error": "", "hooks_error": "", "time_to_service": 10}' -F 'test_run_id=3' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```


#### DELETE /api/assignments/:assignment_id/groups/:group_id/test_group_results/:id

Delete a test group result

##### Parameters

None

##### CURL example

```sh
curl -X DELETE 'http://example.com/api/assignments/1/groups/1/test_group_results/3.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### GET /api/assignments/:assignment_id/groups/:group_id/test_group_results/:test_group_result_id/test_results

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/assignments/1/groups/3/test_group_results/5/test_results.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
[
  {
    "id": 5,
    "name": "test100",
    "status": "pass",
    "marks_earned": 5,
    "output": "good job!",
    "created_at": "2020-09-04T11:36:02.980-04:00",
    "updated_at": "2020-09-04T11:36:02.980-04:00",
    "marks_total": 5,
    "time": null,
    "test_group_result_id": 5
  }
]
```


#### POST /api/assignments/:assignment_id/groups/:group_id/test_group_results/:test_group_result_id/test_results

Create a new test result

##### Parameters

- `name` (string, required)
- `status` (string, required)
- `marks_earned`, (number, required)
- `output` (string, required)

##### CURL example

```sh
curl -X POST 'http://example.com/api/assignments/1/groups/3/test_group_results/5/test_results.json' -F 'name=new-test' -F 'status=fail' -F 'marks_earned=0' -F 'output=bad job' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "201",
  "description": "The resource has been created."
}
```


#### GET /api/assignments/:assignment_id/groups/:group_id/test_group_results/:test_group_result_id/test_results/:id

Get information about a single test result

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/assignments/1/groups/3/test_group_results/5/test_results/6.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "id": 6,
  "name": "new-test",
  "status": "fail",
  "marks_earned": 0,
  "output": "bad job",
  "created_at": "2020-09-04T11:44:32.532-04:00",
  "updated_at": "2020-09-04T11:44:32.532-04:00",
  "marks_total": 0,
  "time": null,
  "test_group_result_id": 5
}
```


#### PUT /api/assignments/:assignment_id/groups/:group_id/test_group_results/:test_group_result_id/test_results/:id

##### Parameters

- `name` (string)
- `status` (string)
- `marks_earned`, (number)
- `output` (string)

##### CURL example

```sh
curl -X PUT 'http://example.com/api/assignments/1/groups/3/test_group_results/5/test_results/6.json' -F 'name=new name' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```


#### DELETE /api/assignments/:assignment_id/groups/:group_id/test_group_results/:test_group_result_id/test_results/:id

Delete a test result.

##### Parameters

None

##### CURL example

```sh
curl -X DELETE 'http://example.com/api/assignments/1/groups/3/test_group_results/5/test_results/6.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### GET /api/assignments/:assignment_id/groups/annotations

Get all annotations from all groups for the given assignment.

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/assignments/1/groups/annotations.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
[
  {
    "type": "TextAnnotation",
    "content": "Quod laboriosam.",
    "filename": "hello.py",
    "path": "A0",
    "page": null,
    "group_id": 13,
    "category": "sed",
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
    "content": "Vel sed.",
    "filename": "pdf.pdf",
    "path": "A0/another-test-files-in-inner-dirs",
    "page": 1,
    "group_id": 15,
    "category": "veniam",
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


#### GET /api/assignments/:assignment_id/groups/group_ids_by_name

Get all group ids for the given assignment associated to the group name.

##### Parameters

None

##### CURL example
```sh
curl 'http://example.com/api/assignments/1/groups/group_ids_by_name.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "c9magnar A0": 1,
  "g8butter A0": 2,
  "c5granad A0": 3
}
```


#### GET /api/assignments/:assignment_id/groups/:id/annotations

Get all annotations on files submitted by the given group for the given assignment.

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/assignments/1/groups/1/annotations.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
[
  {
    "type": "TextAnnotation",
    "content": "Quia.",
    "filename": "hello.py",
    "path": "A0",
    "page": null,
    "group_id": 1,
    "category": "veniam",
    "creator_id": 1,
    "content_creator_id": 1,
    "line_end": 9,
    "line_start": 7,
    "column_start": 6,
    "column_end": 15,
    "x1": null,
    "y1": null,
    "x2": null,
    "y2": null
  },
  {
    "type": "ImageAnnotation",
    "content": "Quia.",
    "filename": "deferred-process.jpg",
    "path": "A0",
    "page": null,
    "group_id": 1,
    "category": "veniam",
    "creator_id": 1,
    "content_creator_id": 1,
    "line_end": null,
    "line_start": null,
    "column_start": null,
    "column_end": null,
    "x1": 132,
    "y1": 199,
    "x2": 346,
    "y2": 370
  }
]
```


#### POST /api/assignments/:assignment_id/groups/:id/add_annotations

Add a text annotation to a file submitted by the given group for the given assignment.

##### Parameters

- `force_complete` (boolean) # add annotations even if the result has been completed
- `annotations` (list of hashes, required)
    - `annotation_category_name` (string)
    - `filename` (string, required)
    - `content` (string, required)
    - `line_start` (integer, required)
    - `line_end` (integer, required)
    - `column_start` (integer, required)
    - `column_end` (integer, required)

##### CURL example

```sh
curl -X POST 'http://example.com/api/assignments/1/groups/1/add_annotations.json' --data '{"force_complete": true, "annotations": [{"filename": "hello.py", "content": "some content", "line_start": 0, "line_end": 0, "column_start": 0, "column_end": 0}]}' -H "Authorization: MarkUsAuth yourapikeyhere" -H "Content-Type: application/json"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### POST /api/assignments/:assignment_id/groups/:id/add_members

Add members to a group by their user name

##### Parameters

- `members` (list of strings, required)

##### CURL example

```sh
curl -X POST 'http://example.com/api/assignments/1/groups/1/add_members.json' --data '{"members": ["g9thomps"]}' -H "Authorization: MarkUsAuth yourapikeyhere" -H "Content-Type: application/json"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### POST /api/assignments/:assignment_id/groups/:id/create_extra_marks

Create an extra mark (bonus or deduction) to the collected result for the given group for the given assignment.

> :spiral_notepad: **Note**: extra marks cannot be created for released results

##### Parameters

- `extra_marks` (number, required) # bonus if positive, deduction if negative
- `description` (string, required)

##### CURL example

```sh
curl -X POST 'http://example.com/api/assignments/1/groups/1/create_extra_marks.json' -F 'extra_marks=2' -F 'description=bonus mark' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Extra mark created successfully"
}
```

#### PUT /api/assignments/:assignment_id/groups/:id/update_marks

Update the marks for a given group based on the criteria name.

> :spiral_notepad: **Note**: extra marks cannot be created for completed results

##### Parameters

Parameters are the name of a criteria for the given assignment mapped to the updated mark.

For example, if there is a criteria named "code_style" and you want to update the mark to 3, the parameters are the same as in the CURL example below.

##### CURL example
```sh
curl -X PUT 'http://example.com/api/assignments/1/groups/1/update_marks.json' -F 'code_style=3' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### PUT /api/assignments/:assignment_id/groups/:id/update_marking_state

Set the marking state to either complete or incomplete

##### Parameters

- `marking_state` (string, required) # either 'complete' or 'incomplete'

##### CURL example

```sh
curl -X PUT 'http://example.com/api/assignments/1/groups/1/update_marking_state.json' -F 'marking_state=complete' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### DELETE /api/assignments/:assignment_id/groups/:id/remove_extra_marks

Delete an extra mark (bonus or deduction).

##### Parameters

At least one is required to identify which extra mark to delete:

- `extra_marks` (number)
- `description` (string)

##### CURL example

```sh
curl -X DELETE 'http://example.com/api/assignments/1/groups/1/remove_extra_marks.json' -F 'extra_marks=2' -F 'description=bonus mark' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Extra mark removed successfully"
}
```

#### GET /api/assignments/:assignment_id/groups

Get information about all groups for the given assignment and their members.

##### Parameters

None

##### CURL example
```sh
curl 'http://example.com/api/assignments/1/groups.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
[
  {
    "id": 14,
    "group_name": "c8delius A0",
    "members": [
      {
        "membership_status": "inviter",
        "user_id": 27
      },
      {
        "membership_status": "accepted",
        "user_id": 48
      }
    ]
  },
  {
    "id": 15,
    "group_name": "c8holstg A0",
    "members": [
      {
        "membership_status": "inviter",
        "user_id": 29
      },
      {
        "membership_status": "accepted",
        "user_id": 50
      }
    ]
  }
]
```


#### GET /api/assignments/:assignment_id/groups/:id

Get information about one group for the given assignment and their members.

##### Parameters

None

##### CURL example
```sh
curl 'http://example.com/api/assignments/1/groups/14.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
[
  {
    "id": 14,
    "group_name": "c8delius A0",
    "members": [
      {
        "membership_status": "inviter",
        "user_id": 27
      },
      {
        "membership_status": "accepted",
        "user_id": 48
      }
    ]
  }
]
```

#### GET /api/assignments/:assignment_id/starter_file_groups/:id/entries

Get the name of all entries for a given starter file group. Entries are file or directory names.

##### Parameters

None

##### CURL example
```sh
curl 'http://example.com/api/assignments/1/starter_file_groups/1/entries.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
["data.csv", "subdir/"]
```


#### POST /api/assignments/:assignment_id/starter_file_groups/:id/create_file

Upload a file to the starter file group

> :spiral_notepad: **Note**: filename can contain a relative path from the starter file group root directory.

##### Parameters

- `filename` (string, required)
- `file_content` (file data, required)

##### CURL example

```sh
curl -X POST 'http://example.com/api/assignments/1/starter_file_groups/1/create_file.json' --data-binary 'filename=About.md' --data-binary 'file_content=@./About.md' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "201",
  "description": "The resource has been created."
}
```

#### POST /api/assignments/:assignment_id/starter_file_groups/:id/create_folder

Create a folder in the starter file group

> :spiral_notepad: **Note**: filename can contain a relative path from the starter file group root directory.

##### Parameters

- `folder_path` (string, required)

##### CURL example
```sh
curl -X POST 'http://example.com/api/assignments/1/starter_file_groups/1/create_folder.json' -F 'folder_path=subdir' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "201",
  "description": "The resource has been created."
}
```

#### DELETE /api/assignments/:assignment_id/starter_file_groups/:id/remove_file

Delete a file from the starter file group

> :spiral_notepad: **Note**: filename can contain a relative path from the starter file group root directory.

##### Parameters

- `filename` (string, required)

##### CURL example
```sh
curl -X DELETE 'http://example.com/api/assignments/1/starter_file_groups/1/remove_file.json' -F 'filename=About.md' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```


#### DELETE /api/assignments/:assignment_id/starter_file_groups/:id/remove_folder

Delete a folder from the starter file group

> :spiral_notepad: **Note**: filename can contain a relative path from the starter file group root directory.

##### Parameters

- `folder_path` (string, required)

##### CURL example
```sh
curl -X DELETE 'http://example.com/api/assignments/1/starter_file_groups/1/remove_folder.json' -F 'folder_path=subdir' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### GET /api/assignments/:assignment_id/starter_file_groups/:id/download_entries

Get the content of all files and directories in this starter file group as the content of a zip file.

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/assignments/1/starter_file_groups/1/download_entries' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

Binary data (zip file contents)


#### GET /api/assignments/:assignment_id/starter_file_groups

Get information about all starter file groups for this assignment

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/assignments/1/starter_file_groups.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
[
  {
    "id": 1,
    "assessment_id": 1,
    "entry_rename": "",
    "use_rename": false,
    "name": "New Starter File Group"
  },
  {
    "id": 2,
    "assessment_id": 1,
    "entry_rename": "",
    "use_rename": false,
    "name": "New Starter File Group"
  }
]
```


#### POST /api/assignments/:assignment_id/starter_file_groups

Create a new empty starter file group.

##### Parameters

None

##### CURL example

```sh
curl -X POST 'http://example.com/api/assignments/1/starter_file_groups.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "201",
  "description": "The resource has been created."
}
```

#### GET /api/assignments/:assignment_id/starter_file_groups/:id

Get information about one starter file group for this assignment

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/assignments/1/starter_file_groups/1.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "id": 1,
  "assessment_id": 1,
  "entry_rename": "",
  "use_rename": false,
  "name": "New Starter File Group"
}
```


#### PUT /api/assignments/:assignment_id/starter_file_groups/:id

Update information about a starter file group.

##### Parameters

- `name` (string)
- `entry_rename` (string)
- `use_rename` (boolean)

##### CURL example

```sh
curl -X PUT 'http://example.com/api/assignments/1/starter_file_groups/1.json' -F 'name=new name' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```


#### DELETE /api/assignments/:assignment_id/starter_file_groups/:id

Delete a starter file group

##### Parameters

None

##### CURL example

```sh
curl -X DELETE 'http://example.com/api/assignments/1/starter_file_groups/1.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### GET /api/assignments/:id/test_files

Get the content of all test files for this assignment as the content of a zip file.

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/assignments/1/test_files' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

Binary data (zip file content)


#### GET /api/assignments/:id/grades_summary

Get the content of a csv file with all grades for this assignment

##### Parameters

None

##### CURL example
```sh
curl 'http://example.com/api/assignments/1/grades_summary' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```csv
User name,Group,Final grade,dolores,iusto,delectus,adipisci,dolorum,eaque,officia,illum,culpa,Bonus/Deductions
"",Out of,19.0,4.0,4.0,4.0,1.0,1.0,2.0,1.0,1.0,1.0,""
c9magnar,c9magnar A0,11.0,3.0,1.0,3.0,0.0,1.0,1.0,1.0,0.0,1.0,0
c5schrek,c9magnar A0,11.0,3.0,1.0,3.0,0.0,1.0,1.0,1.0,0.0,1.0,0
g9thomps,c9magnar A0,11.0,3.0,1.0,3.0,0.0,1.0,1.0,1.0,0.0,1.0,0
```

#### GET /api/assignments/:id/test_specs

Get the settings for the automated tests for this assignment

##### Parameters

None

##### CURL example
```sh
curl 'http://example.com/api/assignments/1/test_specs.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "testers": [
    {
      "tester_type": "pyta",
      "test_data": [
        {
          "student_files": [
            {
              "max_points": 10,
              "file_path": "internet.py"
            }
          ],
          "category": [
            "admin"
          ],
          "timeout": 90,
          "upload_annotations": false,
          "extra_info": {
            "name": "Test group",
            "display_output": "instructors",
            "test_group_id": 1
          }
        }
      ]
    }
  ]
}
```


#### POST /api/assignments/:id/update_test_specs

Upload test settings for the automated tests for this assignment

##### Parameters

- `specs` (hash, required) # see Example Response from [above](#get-apiassignmentsidtest_specs)

##### CURL example
```sh
curl -X POST 'http://example.com/api/assignments/1/update_test_specs.json' --data '{"specs":{"testers":[{"tester_type":"pyta","test_data":[{"student_files":[{"max_points":10,"file_path":"internet.py"}],"category":["admin"],"timeout":120,"upload_annotations":true,"extra_info":{"name":"Test group","display_output":"instructors","test_group_id":1}}]}]}}'  -H "Authorization: MarkUsAuth yourapikeyhere" -H "Content-Type: application/json"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```

#### GET /api/assignments

Get information about all assignments

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/assignments.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
[
  {
    "id": 1,
    "description": "Variables and Simple Operations",
    "short_identifier": "A0",
    "message": "using basic operators and assigning variables",
    "due_date": "2020-08-25T16:29:34.985-04:00",
    "group_min": 2,
    "group_max": 3,
    "tokens_per_period": 0,
    "allow_web_submits": true,
    "student_form_groups": true,
    "remark_due_date": null,
    "remark_message": null,
    "assign_graders_to_criteria": false,
    "enable_test": true,
    "enable_student_tests": false,
    "allow_remarks": false,
    "display_grader_names_to_students": false,
    "group_name_autogenerated": true,
    "repository_folder": "A0",
    "is_hidden": false,
    "vcs_submit": false,
    "token_period": 1,
    "non_regenerating_tokens": false,
    "unlimited_tokens": false,
    "token_start_date": "2020-08-26T16:27:00.000-04:00",
    "has_peer_review": false,
    "starter_file_type": "simple",
    "default_starter_file_group_id": null
  },
  {
    "id": 2,
    "description": "Conditionals and Loops",
    "short_identifier": "A1",
    "message": "Learn to use conditional statements, and loops.",
    "due_date": "2020-08-26T16:29:35.008-04:00",
    "group_min": 1,
    "group_max": 1,
    "tokens_per_period": 0,
    "allow_web_submits": true,
    "student_form_groups": false,
    "remark_due_date": "2020-08-24T16:27:20.239-04:00",
    "remark_message": null,
    "assign_graders_to_criteria": false,
    "enable_test": false,
    "enable_student_tests": false,
    "allow_remarks": true,
    "display_grader_names_to_students": false,
    "group_name_autogenerated": true,
    "repository_folder": "A1",
    "is_hidden": false,
    "vcs_submit": false,
    "token_period": 1,
    "non_regenerating_tokens": false,
    "unlimited_tokens": false,
    "token_start_date": "2020-08-26T16:27:20.239-04:00",
    "has_peer_review": true,
    "starter_file_type": "simple",
    "default_starter_file_group_id": null
  }
]
```


#### POST /api/assignments

Create a new assignment

##### Parameters

- short_identifier (string, required)
- due_date (string, required)
- description (string, required)
- repository_folder (string)
- group_min (integer)
- group_max (integer)
- tokens_per_period (integer)
- submission_rule_type (string)
- allow_web_submits (boolean)
- display_grader_names_to_students (boolean)
- enable_test (boolean)
- assign_graders_to_criteria (boolean)
- message (string)
- allow_remarks (boolean)
- remark_due_date (string)
- remark_message (string)
- student_form_groups (boolean)
- group_name_autogenerated (boolean)
- submission_rule_deduction (integer)
- submission_rule_hours (integer)
- submission_rule_interval (integer)

##### CURL example

```sh
curl -X POST 'http://example.com/api/assignments.json' -F 'short_identifier=A10' -F 'due_date=2020-08-25T16:29' -F 'description=a new assignment' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "201",
  "description": "The resource has been created."
}
```

#### GET /api/assignments/:id

Get information about one assignment

##### Parameters

None

##### CURL example

```sh
curl 'http://example.com/api/assignments/1.json' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "id": 1,
  "description": "Variables and Simple Operations",
  "short_identifier": "A0",
  "message": "using basic operators and assigning variables",
  "due_date": "2020-08-25T16:29:34.985-04:00",
  "group_min": 2,
  "group_max": 3,
  "tokens_per_period": 0,
  "allow_web_submits": true,
  "student_form_groups": true,
  "remark_due_date": null,
  "remark_message": null,
  "assign_graders_to_criteria": false,
  "enable_test": true,
  "enable_student_tests": false,
  "allow_remarks": false,
  "display_grader_names_to_students": false,
  "group_name_autogenerated": true,
  "repository_folder": "A0",
  "is_hidden": false,
  "vcs_submit": false,
  "token_period": 1,
  "non_regenerating_tokens": false,
  "unlimited_tokens": false,
  "token_start_date": "2020-08-26T16:27:00.000-04:00",
  "has_peer_review": false,
  "starter_file_type": "simple",
  "default_starter_file_group_id": null
}
```

#### PUT /api/assignments/:id

Update settings for an assignment

##### Parameters

Same as [POST /api/assignments](#post-apiassignments)

##### CURL example

```sh
curl -X PUT 'http://example.com/api/assignments/4.json' -F 'description=an updated description' -H "Authorization: MarkUsAuth yourapikeyhere"
```

##### Example Response

```json
{
  "code": "200",
  "description": "Success"
}
```
