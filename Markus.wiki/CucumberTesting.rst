================================================================================
Cucumber Testing
================================================================================

**disclaimer**: This page is a work in progress. Send feedback to Gabriel or
the `markus-dev` list.

Cucumber acceptance testing for MarkUs
================================================================================

Requirements
--------------------------------------------------------------------------------

In order to be able to run MarkUs' cucumber tests you'll need to have the
following gems installed :

 * `cucumber` version 0.4.4
 * `webrat` version 0.5.3
 
Since they're defined in `config/environment/cucumber.rb` they should normally
get installed when you invoke [*waiting for feedback*]::

    rake gems:install

If, for any reason, the aforementioned command fails (or give no output), you
could always install them manually with::

    [sudo] gem install --version '>= 0.4.4' cucumber 
    [sudo] gem install --version '>= 0.5.3' webrat

or assert their presence with::

    gem list | grep -E "cucumber|webrat"

***Note*** *for* ***Debian/Ubuntu*** *users*::

  > `webrat` requires some manual package download to install correctly. use `[sudo] apt-get install libxslt1-dev libxml2-dev`



Running the Tests
--------------------------------------------------------------------------------

You can always launch the whole cucumber test suite using `rake` with the
following command::

    rake cucumber

However, calling `cucumber` directly (from a project root folder) will also
work assuming that your `gems/bin` folder is effectively in your `PATH`.::

***Note*** *on running* `cucumber` *from the command-line interface*:

Keep in mind that when you invoke cucumber directly (without rake) you will
not get prompted if you need to `rake db:migrate` but rather see some of your
tests (or all of them) fail. Also, after `db:migrate`-ing, you will need to
`rake db:test:load` before running `cucumber` directly from the CLI.

But as features get written this is going to become longer and longer to
process. You'll also want to run a specific feature which you can achieve
with::

    cucumber path/to/file.feature

which is the shorter (and faster) version to::

    rake cucumber FEATURE=path/to/file.feature

You could also want to run a single scenario instead of a whole feature. This
is done by specifying the scenario's first line number like this::

    cucumber path/to/file.feature:15

As a concrete MarkUs example, if you want to test the login feature for
students and TAs only, you can do it by typing::

    cucumber features/login.feature:16:25

Writing the Tests
--------------------------------------------------------------------------------

Cucumber tests come separated in two groups. One is aimed at the client. It is
business readable and should use domain specific language. They're the
*feature* files. The other group defines the *steps* -- the actual ruby code
-- that gets triggered when the *feature* files are evaluated.



The Features
********************************************************************************

In an ideal world, acceptance tests are written by the client. In such a
world, the *feature* file is the one the client has to write. In the real
world, those file should ***at the very least*** be validated by the client.

A feature file should adopt the following conventions:

  * It is located in `features/` or one of its sub folders;
  * Its name ends with `.feature`;
  * It is written in plain english;
  * It uses domain specific language.

A feature file begins by describing the feature's: *name*, *goal* (should
usually be related to some business value), *stakeholder* (the related user)
and *behavior* like this:

    Feature: [Feature name]
      In order to [goal]
      [stakeholder]
      Wants [behavior]

followed by one or more (usually more) scenario written using the following
structure (notice how the word `Scenario` is aligned with the word `Wants`
from the previous example)::

      Scenario: [name]
        Given [some initial situation]
          And [some additional details]
        When [I do some action]
        Then [I should experience this outcomes]
          And [some additional details]
          But [not those details]

For any given `Given` or `Then` statement, there can be zero to many `And`
statement.  For any given `Then` statement, there can be zero to many `But`
statement.

This way of describing features and scenario has a name. It's called Gherkin
(a vegetable in the same family as the cucumber). Like in YAML and python, it
is indentation that defines the structure of the document. Also note that
keywords (given, when, then...) should begin with an upper-case letter.

To learn more:

  * [[Feature introduction |
    http://wiki.github.com/aslakhellesoy/cucumber/feature-introduction]]
  * [[Given-When-Then syntax |
  * http://wiki.github.com/aslakhellesoy/cucumber/given-when-then]]
  * [[Gherkin | http://wiki.github.com/aslakhellesoy/cucumber/gherkin]]

The Steps
********************************************************************************

The *step definition* files allow to define what code gets executed when
encountering some pattern in the *feature* file. The pattern can be a string
or a regular expression.

Two examples of step definition::

    Given "some string to match" do
      # some ruby code here
    end

    When /some regex to match/ do
      # some ruby code here
    end

The `Given` and `When` are interchangeable. In fact, a step definition starts
with an adjective or an adverb, and can be expressed in any of Cucumber’s
supported [[Spoken
languages | http://wiki.github.com/aslakhellesoy/cucumber/spoken-languages]].
Moreover, a *feature* file statement will get positively matched with a *step
definition* even though it does not begin with the same keyword.

If a step definition uses a regular expression, it can receive parameters. To
do so, add a block parameter with as many arguments as there are groups
(parenthesis) in your regular expression. Here's an example of a *step
definition* with parameters::

    Given /I have (\d+) cucumber in my belly do |cukes|
      # some ruby code here, taking advantage of the content of cukes
    end

Note that:

  1. *Step definitions* always receive their parameters as string.
     Appropriate conversion should be applied inside the block if necessary.
  1. All the *step definitions* declared in every
    `features/step_definitions/*.rb` file (including sub folders) are available
    to any *feature* file. This is the reason why you can not (and should not)
    reuse the same string/regex to identify a *step definition*, even across file.


Failure Versus Success
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For Cucumber, a step is a success if no error was raised during the *step
definition* block execution. Cucumber completely ignores the *step
definition*'s return value.

To learn more:

  * [[Step definitions |
    http://wiki.github.com/aslakhellesoy/cucumber/step-definitions]]

Scaffolding
********************************************************************************

To easily generate a *feature* and a *feature_steps* file, type::

    script/generate feature feature_name

and start editing the generated files.

Other References
--------------------------------------------------------------------------------

  * [[Cucumber home page | http://cukes.info/]]


