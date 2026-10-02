---
permalink: /administrators/logging/
title: Logging
nav_order: 4
parent: Administrators
---
# Logging
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

## Overview

MarkUs writes its logs using [Semantic Logger](https://logger.reidmorrison.com/rails). Instead of lines of free-form text, every log entry is a structured record containing (among other things) a timestamp, a log level, the name of the class that wrote the entry, a short message, and a payload of named values. In production, each log entry is written to the log file as a single line of JSON so that the logs can be searched and filtered precisely, either with command line tools such as [jq](https://jqlang.org/) or by a centralized logging system (for example, the Elastic Stack, Grafana Loki, or Splunk).

All MarkUs processes write to the same log file: the web server, the Resque workers that run background jobs, the Resque scheduler, and any rake tasks or rails runner scripts.

MarkUs logs three kinds of entries:

- **Request logs**: one entry for each request handled by the MarkUs web server, recording who made the request, what was requested, and the response.
- **Background job logs**: entries recording when each background job (for example, collecting submissions or splitting scanned exams) was enqueued and performed.
- **Audit events**: entries recording actions that are important for auditing, such as logging in and out, switching roles, updating marks, and releasing results. These are described in [Audit events](#audit-events) below.

## Configuration

Logging is configured with the following [settings](configuration.md#settings):

```yaml
rails:
  log_level: # the minimum level of the entries to write (one of: debug info warn error fatal unknown)
logging:
  log_file: # path to the log file, either absolute or relative to the MarkUs root directory
  format: # format of each log entry (one of: json text color)
  tag_with_usernames: # boolean indicating whether to tag each entry written while handling a request with the user names of the user who made the request
```

The default values are:

| Setting                      | Development            | Production            |
|------------------------------|------------------------|-----------------------|
| `rails.log_level`            | `debug`                | `info`                |
| `logging.log_file`           | `log/development.log`  | `log/production.log`  |
| `logging.format`             | `color`                | `json`                |
| `logging.tag_with_usernames` | `true`                 | `true`                |

The available formats are:

- `json`: each entry is written as a single line of JSON. This is recommended for production because each entry can be parsed reliably.
- `text`: each entry is written as a line of human-readable text.
- `color`: the same as `text`, but with ANSI color codes. This is useful when reading logs in a terminal (for example, with `tail -f` or `less -R`).

Like any other setting, these can also be set with [environment variables](configuration.md#environment-variables). For example, to write human-readable logs at the `debug` level:

```sh
MARKUS__RAILS__LOG_LEVEL=debug MARKUS__LOGGING__FORMAT=text bundle exec rails server
```

> 🗒️ **Note**: tagging entries with user names requires that `rails.session_store.type` is set to `cookie_store` (the default).

## Log entry format

Here is an example of an audit event written in the `json` format (formatted over multiple lines here for readability; in the log file, each entry is written on a single line):

```json
{
  "host": "markus.example.com",
  "application": "MarkUs",
  "environment": "production",
  "timestamp": "2026-10-02T19:21:37.418520Z",
  "level": "info",
  "level_index": 2,
  "pid": 41305,
  "thread": "puma srv tp 002",
  "named_tags": {
    "request_id": "2d0c64f0-5bd3-4c0b-9d16-2a5c4f6a83f1",
    "ip": "192.0.2.17",
    "real_user_name": "instructor1",
    "user_name": "instructor1"
  },
  "name": "ResultsController",
  "message": "Mark updated",
  "payload": {
    "user_name": "instructor1",
    "submission_id": 1529,
    "assignment_id": 3,
    "short_identifier": "A1",
    "group_name": "group_0007",
    "criterion_id": 21,
    "previous_mark": 2.0,
    "mark": 3.5
  }
}
```

Each entry may contain the following fields:

| Field          | Description                                                                                                                                         |
|----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `host`         | The name of the machine that wrote the entry.                                                                                                      |
| `application`  | Always `MarkUs`.                                                                                                                                    |
| `environment`  | The Rails environment (for example, `production`).                                                                                                  |
| `timestamp`    | The time when the entry was written, in UTC (ISO 8601 format).                                                                                      |
| `level`        | The log level: `trace`, `debug`, `info`, `warn`, `error`, or `fatal`. `level_index` is the same level as a number from 0 (`trace`) to 5 (`fatal`). |
| `pid`          | The id of the process that wrote the entry.                                                                                                         |
| `thread`       | The name of the thread that wrote the entry.                                                                                                        |
| `named_tags`   | Values that describe the context in which the entry was written. See [Request logs](#request-logs) below.                                         |
| `tags`         | Like `named_tags`, but without names. Background job entries are tagged with the job's class and id.                                               |
| `name`         | The name of the class that wrote the entry (for example, `ResultsController`, `User`, or `SubmissionsJob`).                                        |
| `message`      | A short description of the entry. Messages do not contain any variable data, so they can be used to search for a particular kind of entry.        |
| `payload`      | Named values that describe the entry in detail.                                                                                                    |
| `duration_ms`  | For entries that describe an operation (such as handling a request or performing a job), how long the operation took in milliseconds. `duration` contains the same value in a human-readable format. |
| `exception`    | For entries that describe an error, the `name`, `message`, and `stack_trace` of the exception that was raised (and of its `cause`, if any).        |
| `metric`       | An identifier for the kind of operation described by the entry (for example, `rails.controller.process_action` for completed requests).          |

The `text` and `color` formats contain the same information. The example above would be written in the `text` format as:

```text
2026-10-02 15:21:37.418520 I [41305:puma srv tp 002] {request_id: 2d0c64f0-5bd3-4c0b-9d16-2a5c4f6a83f1, ip: 192.0.2.17, real_user_name: instructor1, user_name: instructor1} ResultsController -- Mark updated -- {user_name: "instructor1", submission_id: 1529, assignment_id: 3, short_identifier: "A1", group_name: "group_0007", criterion_id: 21, previous_mark: 2.0, mark: 3.5}
```

### Request logs

When the MarkUs web server finishes handling a request, it writes a single entry with the message `Completed #<action>` at the `info` level. The `name` of the entry is the controller that handled the request, and its payload contains:

- `controller` and `action`: the controller and action that handled the request
- `method`, `path`, and `format`: the HTTP method, path, and format of the request
- `params`: the request parameters. The values of sensitive parameters (such as passwords, email addresses, and API keys) are replaced with `[FILTERED]`.
- `status` and `status_message`: the HTTP status of the response
- `db_runtime` and `view_runtime`: the time spent querying the database and rendering views, in milliseconds
- `queries_count` and `cached_queries_count`: the number of database queries that were made (and of those, how many were served from the query cache)
- `allocations`, `cpu_time`, `idle_time`, and `gc_time`: performance statistics

Requests that redirect, or that send a file, also write a `Redirected to` or `Sent file` / `Sent data` entry. Errors that occur while handling a request are logged with the `exception` field.

All entries written while handling a request have the following named tags:

- `request_id`: a unique id for the request. Use it to find all of the entries written for a particular request.
- `ip`: the IP address of the client that made the request
- `real_user_name`: the user name of the user who made the request (only if `logging.tag_with_usernames` is true and the user is logged in)
- `user_name`: the user name of the user that `real_user_name` is viewing MarkUs as. This is the same as `real_user_name` unless an instructor has [switched roles](../instructors/student-view.md) (only if `logging.tag_with_usernames` is true and the user is logged in).

Requests made to the [API](../technical-guides/restful-api.md) are authenticated with an API key instead of a login session, so they do not have the `real_user_name` and `user_name` tags.

### Background job logs

MarkUs writes the following entries for each [background job](admin-dashboards.md#resque):

- `Enqueued <JobClass> ...` when the job is added to a queue
- `Performing <JobClass> ...` when a worker starts performing the job
- `Performed <JobClass> ...` when the job finishes (including how long it took), or `Error performing <JobClass> ...` (at the `error` level, with the `exception` field) if the job failed

The payloads of these entries contain the `job_class`, `job_id`, `queue`, and `arguments` of the job. Entries written while a job is performed (including any [audit events](#audit-events)) are tagged with the job's class and id.

## Audit events

MarkUs writes the following entries to record actions that are important for auditing. Unless otherwise noted, `user_name` in the payload is the user name of the user who performed the action. If an instructor has switched roles, this is the user that they are viewing MarkUs as; the instructor's own user name is in the `real_user_name` named tag.

### Authentication

| Message                      | Level  | Logged when                                                                                                                  | Payload                                                |
|------------------------------|--------|------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------|
| `User authenticated`         | `info` | the [validation script](configuration.md#user-authentication-options) accepted a user's credentials                         | `user_name`, `auth_type`                              |
| `User authentication failed` | `warn` | the validation script rejected a user's credentials, or the credentials contained illegal characters                         | `user_name`, `auth_type`, `exit_status`, `reason`      |
| `User logged out`            | `info` | a user logged out                                                                                                            | `user_name`                                           |
| `Role switch started`        | `info` | an instructor switched roles to view a course as another user                                                                | `real_user_name` (the instructor), `user_name` (the user they are viewing the course as), `course_id` |
| `Role switch ended`          | `info` | an instructor stopped viewing a course as another user                                                                       | `real_user_name`, `user_name`, `course_id`             |

`auth_type` is `local` for users who log in with a user name and password, and `remote` for users who log in with [remote authentication](configuration.md#user-authentication-options). `exit_status` is the exit status of the validation script, and `reason` is the corresponding message from the `validate_custom_status_message` setting (if any).

### Grading

| Message             | Level  | Logged when                                                     | Payload                                                                                                                        |
|---------------------|--------|-----------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|
| `Viewed submission` | `info` | a grader opened a submission in the grading view                 | `user_name`, `submission_id`, `assignment_id`, `short_identifier`, `group_name`                                               |
| `Mark updated`      | `info` | a grader updated the mark for a criterion                        | `user_name`, `submission_id`, `assignment_id`, `short_identifier`, `group_name`, `criterion_id`, `previous_mark`, `mark`      |
| `Mark update failed`| `warn` | a mark could not be updated (for example, because it was invalid) | `user_name`, `submission_id`, `assignment_id`, `short_identifier`, `group_name`, `criterion_id`, `mark`, `errors`             |
| `Marks released`    | `info` | results were released to students                                | for assignments: `user_name`, `assignment_id`, `short_identifier`, `num_groupings`, and `grouping_ids` (or `peer_review_ids` for peer review assignments); for marks spreadsheets: `user_name`, `grade_entry_form_id`, `short_identifier`, `num_students`, `grade_entry_student_ids` |
| `Marks unreleased`  | `info` | results were unreleased                                          | the same as `Marks released`                                                                                                   |
| `Viewed results`    | `info` | a student viewed their results for an assignment                 | `user_name`, `assignment_id`, `short_identifier`, `result_id`                                                                  |

`short_identifier` is the short identifier of the assignment or marks spreadsheet. A `mark` of `null` means that the mark was cleared.

### Groups

| Message                      | Level           | Logged when                                                                 | Payload                                                               |
|------------------------------|-----------------|-----------------------------------------------------------------------------|-----------------------------------------------------------------------|
| `Group created`              | `info`          | a student created a group (or chose to work alone)                          | `user_name`, `assignment_id`, `group_name`                            |
| `Group creation failed`      | `warn`, `error` | a group could not be created by a student, or from an uploaded groups file  | `user_name` (if created by a student), `assignment_id`, `group_name` (if known), `errors` |
| `Group deleted`              | `info`          | a student deleted their group                                               | `user_name`, `assignment_id`, `group_name`                            |
| `Group deletion failed`      | `warn`, `error` | a student's group could not be deleted                                      | `user_name`, `assignment_id`, `group_name` (if known), `errors`       |
| `Accepted group invitation`  | `info`          | a student accepted an invitation to join a group                            | `user_name`, `assignment_id`, `group_name`                            |
| `Declined group invitation`  | `info`          | a student declined an invitation to join a group                            | `user_name`, `assignment_id`, `group_name`                            |
| `Cancelled group invitation` | `info`          | a student cancelled an invitation that they sent to another student         | `user_name`, `assignment_id`, `group_name`, `invited_user_name`       |
| `Finished creating groups`   | `info`          | MarkUs finished creating the groups from an uploaded groups file            | `assignment_id`, `short_identifier`, `num_groups`                     |

### Submissions and scanned exams

| Message                  | Level   | Logged when                                                   | Payload                                                                                                                                              |
|--------------------------|---------|---------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Collecting submission`  | `info`  | MarkUs started collecting a group's submission                | `assignment_id`, `short_identifier`, `grouping_id`                                                                                                   |
| `Collected submissions`  | `info`  | MarkUs finished collecting submissions                        | `assignment_id`, `short_identifier`, `num_groupings`                                                                                                 |
| `Submission collection error` | `error` | a submission could not be collected, or its grading data could not be copied | `assignment_id`, `grouping_id`, `errors`                                                                                              |
| `Generated exam copies`  | `info`  | MarkUs generated copies of an exam template                   | `exam_template_id`, `num_copies`, `start`                                                                                                            |
| `Split scanned exam PDF` | `info`  | MarkUs finished splitting an uploaded PDF of scanned exams     | `exam_template_id`, `split_pdf_log_id`, `num_pages`, `num_groups_in_complete`, `num_groups_in_incomplete`, `num_pages_qr_scan_error`                |

### Other events

MarkUs also writes the following entries, which can help administrators diagnose problems:

| Message                          | Level           | Logged when                                                                                       | Payload                                          |
|----------------------------------|-----------------|---------------------------------------------------------------------------------------------------|--------------------------------------------------|
| `Repository creation failed`     | `error`         | a group's repository could not be created                                                         | `group_name`, `repo_name`, `collision` (whether a repository with the same name already exists), and the `exception` |
| `Repository access failed`       | `warn`          | the working copy of a git repository is missing or could not be opened (MarkUs then recreates it) | `repo_path`, and either `reason` or the `exception` |
| `Recloned repository`            | `info`          | MarkUs recreated the working copy of a git repository                                            | `repo_path`                                      |
| `Repository reclone failed`      | `error`         | MarkUs could not recreate the working copy of a git repository                                   | `repo_path`, and the `exception`                  |
| `Test results processing failed` | `error`         | test results sent to the API by the automated tester could not be saved                          | `grouping_id`, `submission_id`, and the `exception` |
| `Jupyter submission failed`      | `error`         | an unexpected error occurred while submitting a file from JupyterHub                             | the `exception`                                  |
| `LTI roster sync failed for user`| `error`         | a user could not be synced from an LMS roster                                                    | `user_name`, `errors`                            |
| `LTI key rotated`                | `info`          | a new [LTI signing key](configuration.md#lti-key-rotation) was created                          | `file_name`, `kid` (the key id)                  |
| `LTI key rotation not due`       | `info`          | the scheduled LTI key rotation ran, but the current key is not old enough to be rotated          | `key_age_days`, `max_age_days`                   |
| `LTI key pruned`                 | `info`          | an LTI signing key that was retired more than `overlap_days` ago was deleted                     | `file_name`, `retired_days_ago`                  |

## Searching JSON logs

Because every entry is a single line of JSON, you can search the log file with [jq](https://jqlang.org/). For example:

```sh
# Show the audit events and requests of a particular user
jq -c 'select(.payload.user_name == "jsmith" or .named_tags.real_user_name == "jsmith")' log/production.log

# Show who released or unreleased marks for the assignment with short identifier A1, and when
jq -c 'select((.message == "Marks released" or .message == "Marks unreleased") and .payload.short_identifier == "A1")
       | {timestamp, message, user_name: .payload.user_name, num_groupings: .payload.num_groupings}' log/production.log

# Show the history of a submission's marks
jq -c 'select(.message == "Mark updated" and .payload.submission_id == 1529)' log/production.log

# Show all failed logins
jq -c 'select(.message == "User authentication failed")' log/production.log

# Show all errors
jq 'select(.level == "error" or .level == "fatal")' log/production.log

# Show all entries written while handling a particular request
jq 'select(.named_tags.request_id == "2d0c64f0-5bd3-4c0b-9d16-2a5c4f6a83f1")' log/production.log

# Show requests that took longer than 5 seconds
jq -c 'select(.metric == "rails.controller.process_action" and .duration_ms > 5000)
       | {timestamp, path: .payload.path, duration_ms}' log/production.log

# Follow the log in a human-readable format
tail -f log/production.log | jq -r '"\(.timestamp) \(.level) \(.name) -- \(.message) \(.payload // "")"'
```

## Log rotation

MarkUs does not rotate its log file. We recommend using [logrotate](https://linux.die.net/man/8/logrotate) to rotate, compress, and delete old log files. Use the `copytruncate` option, since MarkUs keeps the log file open while it is running. For example, the following configuration (in `/etc/logrotate.d/markus`) rotates the log file every day and keeps the logs from the last two weeks:

```text
/path/to/markus/log/production.log {
  daily
  rotate 14
  compress
  delaycompress
  copytruncate
  missingok
  notifempty
}
```

## Upgrading from an earlier version

Earlier versions of MarkUs wrote audit events as plain text to separate files for each process (`log/info_<environment>.log.<pid>` and `log/error_<environment>.log.<pid>`). Audit events are now written as structured entries to the main log file, and the following settings have been removed:

- `logging.enabled`
- `logging.rotate_by_interval`
- `logging.rotate_interval`
- `logging.size_threshold`
- `logging.old_files`
- `logging.error_file`

The default value of `logging.log_file` has changed from `log/info_<environment>.log` to `log/<environment>.log`. If you set `logging.log_file` yourself, all log entries (and not only audit events) are now written to that file.
