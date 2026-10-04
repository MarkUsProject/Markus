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

MarkUs writes its logs using [Semantic Logger](https://logger.reidmorrison.com/rails). Every log entry is a structured record with a timestamp, a log level, the name of the class that wrote the entry, a short message, and a payload of named values. All MarkUs processes (the web server, the Resque workers, and rake tasks) write to the same log file.

As well as the requests handled by the web server and the background jobs that it runs, MarkUs logs actions that are important for auditing, such as logging in and out, switching roles, updating marks, and releasing marks.

> 🗒️ **Note**: earlier versions of MarkUs also wrote these actions as plain text to separate files for each process (`log/info_<environment>.log.<pid>` and `log/error_<environment>.log.<pid>`). These files are no longer written.

## Configuration

Logging is configured with the following [settings](configuration.md#settings):

| Setting                      | Description                                                                                                                                        | Default (development) | Default (production) |
|------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------|----------------------|
| `rails.log_level`            | The minimum level of the entries to write (one of: `debug`, `info`, `warn`, `error`, `fatal`, `unknown`)                                           | `debug`               | `info`               |
| `logging.log_file`           | The path to the log file, relative to the MarkUs root directory                                                                                    | `log/development.log` | `log/production.log` |
| `logging.format`             | The format of each entry: `json` (a single line of JSON), `text` (a line of human-readable text), or `color` (`text` with ANSI color codes)       | `color`               | `json`               |
| `logging.tag_with_usernames` | Whether to tag each entry written while handling a request with the user name of the user who made the request (this requires that `rails.session_store.type` is `cookie_store`) | `true` | `true` |

In development, log entries are also written to the output of `rails server`. When running `rails console`, log entries are also written to the console.

## Log entry format

Here is an example of an entry written in the `json` format (formatted over multiple lines here for readability; in the log file, each entry is written on a single line):

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
    "ip": "192.0.2.17",
    "user_name": "instructor1"
  },
  "name": "ResultsController",
  "message": "Mark updated",
  "payload": {
    "user_name": "instructor1",
    "submission_id": 1529,
    "short_identifier": "A1",
    "group_name": "group_0007"
  }
}
```

The `message` of an entry does not contain any variable data, so it can be used to search for a particular kind of entry. The details are in its `payload`. Entries that describe an error also contain an `exception` field with the name, message, and stack trace of the exception.

Entries written while handling a request have the following `named_tags`:

- `ip`: the IP address of the client that made the request
- `user_name`: the user name of the user who made the request, if they are logged in and `logging.tag_with_usernames` is true. If an instructor has [switched roles](../instructors/student-view.md), this is `<instructor> as <user>`.

The `text` and `color` formats contain the same information on a single line of text.

### Request logs

When the web server finishes handling a request, it writes a single entry with the message `Completed #<action>` at the `info` level. Its payload contains the controller and action that handled the request, the request's parameters (with the values of sensitive parameters such as passwords replaced with `[FILTERED]`), the HTTP method, path, and response status, and how long the request took. The `Started`, `Processing`, and `Rendered` entries for each request are written at the `debug` level.

## Log rotation

MarkUs does not rotate or delete its log file. We recommend using [logrotate](https://linux.die.net/man/8/logrotate) to rotate, compress, and delete old log files, with the `copytruncate` option, since MarkUs keeps the log file open while it is running.
