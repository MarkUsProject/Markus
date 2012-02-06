================================================================================
Style Guide for Rails Views
================================================================================

What do the ERb tags mean?
================================================================================

Basically, use \<% %\> and \<%= %\> where appropriate in your .html.erb files.

This is what the Rails API documentation says:

You trigger ERb by using embeddings such as \<% %\>, \<%- -%\>, and \<%= %\>.
The \<%= %\> tag set is used when you want output. Consider the following loop
for names::

    <b>Names of all the people</b>
    <% for person in @people %>
      Name: <%= person.name %><br/>
    <% end %>

The loop is setup in regular embedding tags <% %> and the name is written
using the output embedding tag <%= %>. Note that this is not just a usage
suggestion. Regular output functions like print or puts won‘t work with ERb
templates. So this would be wrong::

    Hi, Mr. <% puts "Frodo" %>

If you absolutely must write from within a function, you can use the
[[TextHelper#concat |
http://api.rubyonrails.org/classes/ActionView/Helpers/TextHelper.html#M001710]].
See [[ActionView::Base | http://api.rubyonrails.org/]] for more details. 

'\<%-  -%\>' is the same as '\<%  %\>'
--------------------------------------------------------------------------------

Since \<%- and -%\> suppress leading and trailing whitespace, including the
trailing newline and can be used interchangeably with \<% and %\>, we
*discourage* using them in order to avoid confusion.

Comments in .html.erb files
================================================================================

If you are about to add comments in an .html.erb file use the following
syntax, **please**::

    <% # This is a comment
    %>

as compared to::

    <% # This is a comment %>

We think in the latter case, the closing <code>%\></code> is ignored and
causes errors in particular cases. So stick to the **first** syntax example!


