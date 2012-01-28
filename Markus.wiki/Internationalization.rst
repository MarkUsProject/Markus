================================================================================
Internationalization
================================================================================

More and more universities are interested by using Markus, and some foreign
universities are starting to look at it. In order to have them use it, Markus
must be ready for internationalisation. Here are a few guidelines to help for
internationalisation

All locales are located in config/locales in YAML format.

Internationalisation
================================================================================

Internationalisation of models, views and controllers
--------------------------------------------------------------------------------

Make sure models, views and controllers are internationalised :
Everything should be internationalised, **except from logging messages**.

For exemple: groups_controller.rb::

  301 raise "You must select at least one grader for random assignment"

needs to be::

  301 raise I18n.t(:groups.no_graders_selected)

or::

  301 raise t(:groups.no_graders_selected)

The html tags that can appear in the internationalisation are:
  * ``<strong>``
  * ``<em>``
  * ``<span>``
  * ``<sup>``
  * ``<sub>``
  * ``<a>``, and the link. **Note that the link can sometimes be different from one 
    language to another**. For example, the link that points to the MIT licence
    can point to the MIT licence translated in french.

The html tags that **should not** appear in the translation are:
  * ``<p>``
  * ``<div>``

Missing ActiveRecord Translations
--------------------------------------------------------------------------------

At the end of each yml file, we added missing activerecord translations. (the
task rake i18n:missing_keys have to return 0 missing keys)

Finding missing locales keys
--------------------------------------------------------------------------------

You now have the missing_keys task which enables you to find all missing keys
in all languages presents in config/locales/::
  rake i18n:missing_keys

Bash command to find text in source files
--------------------------------------------------------------------------------

::

  find PATH_OF_THE_PROJECT -name "*" -exec grep --color -Hn "KEY_TO_FIND" {} \;



Internationalization of Javascript files
--------------------------------------------------------------------------------

::

  alert('You must select the Penalty Period Submission Rule to add a grace period.');

becomes

::

  alert("#{I18n.t("submission_rules.penalty_period_submission_rule.alert")}");



Localisation of dates and times
--------------------------------------------------------------------------------

At the moment, there are two dates format in MarkUs : ::
  
  ###################################################################
  # Date/Time display formats
  ###################################################################
  # Short form (displays month, day, year)
  SHORT_DATE_TIME_FORMAT = "%B %d, %Y"
  # Long form (displays month, day, year, hour, minute)
  LONG_DATE_TIME_FORMAT = "%B %d, %Y: %I:%M%p"</pre>

  Configurations can be found in the config/environments/_ENVIRONMENT_.rb files
  (where _ENVIRONMENT_ is development, test, production)

  We are no longer using this vars in config/environments/_ENVIRONMENT_.rb

  #### Dates using strftime format

We don't use strftime() method anymore : ::

  <%= assignment.due_date.strftime(LONG_DATE_TIME_FORMAT) %>

becomes ::

  <%= I18n.l(assignment.due_date, :format => :long_date) %>


with appropriate references in the config/_LANG_.yml (en.yml default)

::

  date:
    #MarkUs LONG_DATE_TIME_FORMAT
    long_date: "%B %d, %Y: %I:%M%p"
    #MarkUs SHORT_DATE_TIME_FORMAT
    short_date: "%B %d, %Y"

Internationalizers 
================================================================================

French locale : Benjamin Vialle (benjaminvialle_AT_gmail.com)
