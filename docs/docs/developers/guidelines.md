---
permalink: /developers/guidelines/
title: Guidelines
parent: Developers
nav_order: 1
---
# Guidelines for MarkUs Development
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

## Motivation

MarkUs is mainly developed by Computer Science students who volunteer to work on MarkUs, work on it for course credit or work full-time on MarkUs during their summer break. Whether developers work on Markus full-time or part-time, they usually work on it for one semester (4 months). So since development teams change pretty frequently and the MarkUs code-base grows constantly, it is inevitable for developers to stick to some basic rules in order to maintain or increase code quality.

## Development Process

When developing MarkUs, make sure to follow the following steps (where appropriate):

1. Write a plan for your changes and discuss them with the other MarkUs developers and maintainers.
2. Create a branch based off of the master branch and make a draft pull request for this branch.
3. Make your proposed changes and push the changes to your branch. If your changes differ from your original plan, update your plan and discuss the updates with your colleagues.
4. Write tests for your changes.
5. Write documentation for your changes.
6. Mark your pull request as "Ready for review" and request a review from one of the maintainers.
7. Make changes as necessary.

### DOs

- **Do** use Rails tools (such as [generators](http://wiki.rubyonrails.org/rails/pages/AvailableGenerators)) when appropriate in order to have code-stubs generated and for [migrations](http://guides.rubyonrails.org/migrations.html)
- **Do** use the [debugger](http://guides.rubyonrails.org/debugging_rails_applications.html).
- **Do** document your code appropriately. Add or update method-level and class-level docstrings as required. You can assume that the reader is familiar with Ruby and Rails. If your code requires more extensive documentation, you may wish to add or update a Wiki page. Remember, once you are done with your work, and you leave the project, new developers should be able to use what you have contributed without a lot of effort.
- **Do** ask for help. Ask questions commenting on your pull requests, emailing or in talking to the maintainers in person (if you can). But don't wait until the project is almost finished; problems can often be resolved quickly by sharing your code and asking questions.
- **Do** write tests! (see the [guides](#guides) for testing guides)

### DON'Ts

- **Don't** mark your pull request as "Ready for review" until you're entirely happy with it. Go, have a break and come back to your code after a while. Questions you should ask yourself are: Is my controller code really controller code, or should it be moved to a model? Is there a simpler solution? Can Rails help with what I am trying to achieve?
- **Don't** mull over problems alone for hours/days. Sometimes it's better to consult somebody else: two pairs of eyes see more than one. Maybe somebody else has had a similar problem, etc. Go ask questions!
- **Don't** fight Rails (it'll beat you). Sometimes Rails' "magic" is irritating. However, you are better off *using* rather than fighting it!
- **Don't** use absolute paths/URL's in any code (use `url_for` instead). *Always* let Rails generate URLs. You have to assume that there are more than one MarkUs applications running on a server, once deployed. Rails does a really good job on this, so use it.

## Code Styleguide

- Use 2 (two) **spaces** (instead of tabs) for indenting
- Make sure you provide a brief and understandable high-level-description of your Rails model/controller code (use RDoc syntax, where appropriate)).

## Logging

MarkUs writes structured logs using [Semantic Logger](https://logger.reidmorrison.com/rails) (see the [Logging](../administrators/logging.md) page in the administrator documentation). When you write a log entry:

- Use the `logger` of the current class (for example, `logger.info` in a controller, model, or background job) so that the entry is named after that class.
- Use a short message that does not contain any variable data, and put the variable data in the payload. For example, write `logger.info('Mark updated', user_name: current_role.user_name, submission_id: submission.id)` instead of ``logger.info("User #{current_role.user_name} updated the mark for submission #{submission.id}")``.
- Pass exceptions as their own argument (for example, `logger.error('Test results processing failed', { grouping_id: grouping.id }, e)`) so that the exception's class, message, and backtrace are logged as structured data.
- If you add or change an audit event, update the list of audit events on the Logging page.

In development, logs are written to `log/development.log` and to the standard output of the rails server and the resque workers. In tests, you can check that a log entry was written with the `log_semantic_logger_event` matcher:

```ruby
expect { get :logout }.to log_semantic_logger_event(level: :info, message: 'User logged out',
                                                    payload: { user_name: instructor.user_name })
```

## Managing Dependencies and Databases

If you create a new database migration or change one of the dependencies files, make sure that your changes are reflected in lockfiles and database schemas before you submit your changes as a pull request.

- If you create a new migration: run `bundle exec rails db:migrate` and you should see changes reflected in `db/structure.sql`
- If you update `Gemfile`: run `bundle install` and you should see changes reflected in `Gemfile.lock`
- If you update `package.json`: run `npm ci` and you should see changes reflected in `package-lock.json`
- If you update `markus.control`: run `equivs-build markus.control` and it should update `markus_1.0_all.deb` (this is a binary file so you won't be able to inspect the changes directly)

## Guides

Rails:

- <http://guides.rubyonrails.org/>
- <http://www.caliban.org/ruby/rubyguide.shtml>

RSpec:

- <https://www.rubyguides.com/2018/07/rspec-tutorial/>
- <https://www.betterspecs.org/>

Action Policy:

- <https://actionpolicy.evilmartians.io>
