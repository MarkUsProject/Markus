================================================================================
Basic Guidelines for MarkUs Development
================================================================================

Motivation
================================================================================

MarkUs is mainly developed by Computer Science students who volunteer to work
on MarkUs, work on it for course credit or work full-time on MarkUs during
their summer break. Irrespective if developers work on Markus full-time or
part-time, they usually work on it for one semester (4 months). So since
development teams change pretty frequently and the MarkUs code-base grows
constantly, it is inevitable for developers to stick to some basic rules in
order to maintain or increase code quality.

Development Process: Dos and Don'ts
================================================================================

When developing MarkUs these are usually the steps you should do (**This is
important!**):

 1. Use Rails tools (such as generators) when appropriate in order to have
   code-stubs generated
 2. Write tests
 3. Write code (and document it adequately)
 4. Check if your code is working
 5. Read some Rails documentation which might be relevant for your code (if you
   are new to Rails)
 6. Go over your code and check if there is a "Rails" way of doing it (If you
   are constructing AJAX calls by hand you are doing something wrong!)
 7. Put your new code up for review (Do *not* commit it until your code has
   been peer-reviewed)
 3. Let your peers know that you have put up a new review request (optional)
 8. Once you got your "ship it", commit your code

DOs
--------------------------------------------------------------------------------

 2. **Do** use Rails tools (such as [[generators |
   http://wiki.rubyonrails.org/rails/pages/AvailableGenerators); especially for
  [[migrations | http://guides.rubyonrails.org/migrations.html]])
 2. **Do** use <code>script/console</code> (see the [[Rails command line guide
   | http://guides.rubyonrails.org/command_line.html]]
 2. **Do** use the [[debugger |
   http://guides.rubyonrails.org/debugging_rails_applications.html]]
 2. **Do** use [[Review-Board | http://review.markusproject.org/]] (even for the
   smallest commit)

 1. **Do** document your code appropriately. As a rule of thumb provide a
   brief high-level-description of what your methods do and add comments
   elsewhere in the code as you find appropriate. You can assume that the
   reader is familiar with Ruby and Rails. If your code requires more
   extensive documentation, add a Wiki page describing its functionality (or
   how to use it). Check "Component Descriptions" section on the Wiki for
   examples. Remember, once you are done with your work and you leave the
   project, new developers should be able to use what you have contributed
   without a lot of effort.

 4. **Do** ask for help. Ask questions via IRC, email or in person if you
   can. But don't wait until the next meeting. Often questions can be resolved
   quickly when another person looks at the code.

 5. **Do** write unit/functional/integration tests/checks (see [[Adam's blog
   post on Rails testing | http://adam.goucher.ca/?p=1188]])

DON'Ts
--------------------------------------------------------------------------------

 2. **Don't** put the first working version up for review. Go, have a break
   and come back to your code after a while. Questions you should ask yourself
   are: Is my controller code really controller code, or should it be moved to a
   model? Is there a simpler solution? Can Rails help with what I am trying to
   achieve?

 3. **Don't** mull over problems alone for hours/days<br/>Sometimes it's better
   to consult somebody else: two pairs of eyes see more than one :-). Maybe
   somebody else has had a similar problem, etc. Go ask questions!

 3. **Don't** fight Rails (it'll beat you). Sometimes Rails' "magic" is
   irritating. However, you are better off *using* rather then fighting it :-)
   Really!

 3. **Don't** use absolute paths/url's in any code (use url_for
   instead). *Always* let Rails generate URLs. You have to assume that
   there are more than one MarkUs applications running on a server, once
   deployed. Rails does a really good job on this, so use it.

Code Styleguide
================================================================================

* Use 2 (two) spaces (instead of tabs) for indenting

* Make sure you provide a brief and understandable high-level-description of
  your Rails model/controller code (use RDoc syntax, where appropriate). These
  high-level-descriptions will be part of MarkUs' API documentation (see the
  [[MarkUs RDoc API | http://www.markusproject.org/dev/app_doc/]]).

Guides
================================================================================

* <http://guides.rubyonrails.org/>
* <http://www.caliban.org/ruby/rubyguide.shtml>
