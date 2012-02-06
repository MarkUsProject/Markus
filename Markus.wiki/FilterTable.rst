================================================================================
The FilterTable Class
================================================================================

What is it?
================================================================================

FilterTable is a Javascript class that allows for easy client-side filtering
and sorting of table data. 

How do I use it?
================================================================================

The Constructor
--------------------------------------------------------------------------------

After including the FilterTable.js code in your HTML page, you must also make
sure to create a TABLE element that FilterTable can attach itself to, like
this::

    <table id="groups">
    </table>

You can then construct the table using code like this::

    groupings_table = new FilterTable({
      table_id: $('groups'),
      headers: $H({
        name: {display: "Name", sortable: true},
        members: {display: "Members", sortable: true},
        graders: {display: "Graders", sortable: true},
        valid: {display: "", sortable: false}
      }),
      can_select: true,
      can_select_all: true,
      can_sort: true,
      row_prefix: "groupings_row_",
      select_name: "groupings[]",
      select_id_prefix: "grouping_select_",
      footer: true,
      filters: {
        validated: function(row) {
          return row.filter_valid;
        },
        unvalidated: function(row) {
          return !row.filter_valid;
        },
        assigned: function(row) {
          return row.filter_assigned;
        },
        unassigned: function(row) {
          return !row.filter_assigned;
        }
      }
    });

Note that in this case, you should create the groupings_table after the DOM
has been loaded, so that it can find the "groups" table.  If you're using
Prototype, this can be done by putting the above code inside this function::

    document.observe('dom:loaded', function() {
       // Construct the FilterTable here...
    });

Here is a list of all parameters that can be set on FilterTable construction:

  * table_id:  The DOM ID of the table element to attach the FilterTable to

  * can_select:  Boolean that sets whether or not each row will get a checkbox
    that will allow users to select individual rows for manipulation.  Default
    is false;

  * can_select_all: Boolean that sets whether or not all rows can be selected
    with a checkbox in the header.  If can_select is false, this setting has
    no effect.  Default is false.

  * row_prefix:  Sets the prefix for the ID of each TR element in the table.
    For example, if the row_prefix is "student_row_", then the TR HTML element
    for a student with ID=1 would be "student_row_1"

  * select_name: Sets the name of all checkbox HTML input elements for each
    row.  In general, it's usually best if this is the plural for whatever is
    being displayed, followed by "[]".  For example, if the table is
    displaying student records, select_name should be "students[]".  This way,
    if the table is within an HTML form, the selected item IDs will be passed
    as an array "students" to the server.

  * select_id_prefix: Sets the ID prefix for the checkbox for each table row.
    For example, if the select_id_prefix is "students_select_", then for a
    Student row with ID=1, the select checkbox would have the ID
    "students_select_1".

  * headers:  See "Headers" below

  * footer:  Boolean that sets whether or not to have a footer that mirrors
    the header of the table.  The footer does not have sorting triggers
    attached to each column, but does have a select_all checkbox if
    can_select_all is enabled.

  * can_sort:  Boolean that sets whether or not this table can be sorted.
    Default is false.

  * default_sort:  Sets the key of the field that will be sorted on initially.
    By default, this is "id".

  * filters:  See "Filters" below

  * sorts:  See "Sorts" below

  * default_filters:  Takes an array of filter keys to set as default.  If not
    set, there are no default filters.

  * header_id_prefix: Sets the ID prefix for the TH elements for the header.
    By default, this is "FilterTable_header_".

  * header_class:  Sets the class of the TH elements for the header.  By
    default, this is "FilterTable_header"

  * sortable_class:  Sets the class of the TH elements for sortable header
    columns.  By default, this is "FilterTable_sortable".

  * sorting_by_class:  Sets the class of the TH element for the column that is
    currently being sorted.  By default, this is "FilterTable_sorting_by".

  * sorting_reverse_class:  Sets the class of the TH element for the column
    that is currently being sorted in reverse.  By default, this is
    "FilterTable_sorting_by_reverse"

  * selectable_class:  Sets the class name for the select checkboxes for each
    table row.  By default, this is "FilterTable_selectable".

  * select_all_top_id:  Sets the ID for the checkbox input in the header that
    allows users to select all rows.  By default, this is
    "FilterTable_select_all_top"

  * select_all_bottom_id:  Sets the ID for the checkbox input in the footer
    that allows users to select all rows.  By default, this is
    "FilterTable_select_all_bottom".

  * filter_count_ids:  See Filters: Filter Counts

  * total_count_id:  If set, on render, FilterTable will attempt to update an
    element with ID total_count_id with the number of all records in the
    table.  So, if you have a <span> element somewhere with
    ID="student_count", you could set the total_count_id to "student_count",
    and have it automatically populate with the number of records in the
    table.

Headers
********************************************************************************

When constructing the FilterTable, a "headers" object must be passed, like
so::

    var student_table = new FilterTable({
    ...
    headers: {
      user_name: {display: "User Name", sortable: true, sort_with: 'nohtml'},
      first_name: {display: "First Name", sortable: true},
      last_name: {display: "Last Name", sortable: true},
      active: {display: "Active", sortable: false}
    },
    ...
    });

In this case, the "keys" of the header object are user_name, first_name,
last_name, and active.  When displaying a table row, FilterTable will look for
these keys in the rows it is trying to render.  So, an example for for the
above FilterTable would be::

    {1:  {user_name: "c8smith", first_name: "Jane", last_name: "Smith",
          active: true, other_data: "Something"}}

The row can contain other information (like "other_data", in this case), but
since this key is not in the header, it won't be displayed.  This is useful
for storing information to filter or sort on, without display it.  Also note
the "1" preceding the row information.  This is the ID of the record.  See
below in "Populating with Data" to see more information on how this works.

In the header object, after defining the keys, we have to also provide
information on how the header should be behave and be displayed.  The
"display" parameter determines what the header content will be.  "sortable"
determines whether or not that header can be clicked on in order to perform a
sort.  "sort_with" allows us to define a custom sorting function - see Sorts
below.

Filters
********************************************************************************

In order to perform a filtering operation on FilterTable data, filtering
functions must be provided when constructing the FilterTable.

Here is an example of some filter functions::

    var student_table = new FilterTable({
    ...
    filters: {
      is_active: function(table_row) {
        return table_row.active;
      },
      is_inactive: function(table_row) {
        return !table_row.active;
      }
    },
    ...
    });

Each filter has a key that identifies it - in this case, "is_active" and
"is_inactive" are the keys.  Each filter function gets passed a single table
row object.  The job of the filter function is to simply return true or false
based on whether or not that row passes the filter.

After this is set up, filters can then be called like this::

    student_table.filter_only_by('is_active').render();

Filters can also be chained.  So, if we were displaying a table full of TODO
items with various properties, we could add various filters to them, like
this::

    todo_table.add_filter('incomplete');
    todo_table.add_filter('no_owner');
    todo_table.render(); // Displays incomplete todo items with no owners

Filters can be removed with::

    todo_table.remove_filter(filter_key).

Filters can be completely cleared like this::

    todo_table.clear_filters();
    todo_table.render();
    // Or alternatively, todo_table.clear_filters().render();

Filter Counts
********************************************************************************

It's possible that you will want to display the number of records that fall
under a certain filter somewhere on the document - for example, if you have a
series of links that trigger filtering, you may want to have them display the
number of records that pass that filter.

If you'd like to do that, FilterTable can be constructed with a
filter_count_ids parameter.  The parameter must be a collection, where the
keys map to filter names, and the values map to the DOM IDs of the elements
that you'd like to contain the counts.

For example, if there are two filters, "is_active" and "is_inactive" on a
table of students, you could display the filter counts by constructing the
FilterTable like this::

    var student_table = new FilterTable({
    ...
    filters: {
      is_active: function(table_row) {
        return table_row.active;
      },
      is_inactive: function(table_row) {
        return !table_row.active;
      }
    },
    filter_count_ids: {
      is_active: 'active_students_count',
      is_inactive: 'inactive_students_count'
    }
    ...
    });

Then, simply place an HTML element on the page with the IDs
"active_students_count" and "inactive_students_count", and they will
automatically be updated on renders.

Sorts
********************************************************************************

By default, FilterTable tries to sort alphabetically.  If, however, you want
to sort using your own rules (or, if you want to do something like strip the
HTML from a column before sorting alphabetically), you can define these rules
in the sorts parameter when constructing the FilterTable, like so::

    var student_table = new FilterTable({
    ...
    sorts: {
      // If, for example, the assignments row has HTML in it, we'll strip the tags before doing the comparison:
      assignments: function(a, b) {
        return a[assignments].stripTags() < b[assignments].stripTags();
      },
      // If we want to define a sort that will strip html tags from whichever column is selected, we have
      // to use FILTERTABLE_SORT to determine which column we're sorting on.
      nohtml: function(a, b) {
        return a[FILTERTABLE_SORT].stripTags() < b[FILTERTABLE_SORT].stripTags();
      }
    },
    ...
    });

Sorting can then be done programmatically like this::

    student_table.sort_by('assignments').render();

Sorting will be handled automatically for headers that have "sortable"
parameter set to true.  We could also use the "sort_with" parameter in the
header to override the default sorting on a column, like this::

    var student_table = new FilterTable({
    ...
    headers: {
      user_name: {display: "User Name", sortable: true, sort_with: 'nohtml'},
      ...
    },
    ...
    });

Populating with Data
--------------------------------------------------------------------------------

The FilterTable can be populated with data using the populate(data) method.

The data that the FilterTable populates should be a JSON string, structured as
follows::

    {
      1: {column_1_data: some_data, column_2_data: some_data},
      2: {column_1_data: some_data, column_2_data: some_data}
    }

The keys of these values (in this case, 1 and 2) should be the unique ID's of
the records that are being displayed.  The data that is attached to these ID
numbers should have keys that match the header keys that were defined when the
FilterTable was created.  So, for example, say we created a FilterTable like
this::

    groupings_table = new FilterTable({
      table_id: $('groups'),
      headers: {
        name: {display: "Name", sortable: true},
        members: {display: "Members", sortable: true, sort_with: 'nohtml'},
        graders: {display: "Graders", sortable: true},
        valid: {display: "", sortable: false}
      },
      can_select: true,
      can_select_all: true,
      can_sort: true,
      row_prefix: "groupings_row_",
      select_name: "groupings[]",
      select_id_prefix: "grouping_select_",
      footer: true,
      filters: {
        validated: function(row) {
          return row.filter_valid;
        },
        unvalidated: function(row) {
          return !row.filter_valid;
        },
        assigned: function(row) {
          return row.filter_assigned;
        },
        unassigned: function(row) {
          return !row.filter_assigned;
        }
      },
      sorts: {
        nohtml: function(a, b) {
          return a[FILTERTABLE_SORT].stripTags().toLowerCase() < b[FILTERTABLE_SORT].stripTags().toLowerCase();
        }
      }
    });

We could populate the FilterTable like this::

    data = {
      1: {name: "Some name", members: "c9smith", graders: "ta1", valid: true, hidden_property: true},
      2: {name: "Some other name", members: "s9jones", graders: "ta2", valid: true, hidden_property: false}
    }
    groupings_table.populate(data.toJSON()); // Using Prototypes toJSON() method
    groupings_table.render();
    // Alternatively:  groupings_table.populate(data.toJSON()).render();

Note that the hidden_property field will not be rendered, since
'hidden_property' did not match and of the header keys.  We can still do
filtering and sorting on this property if we wish though.

Modifying the Data
--------------------------------------------------------------------------------

Adding and Modifying rows
********************************************************************************

Adding or modifying rows involves using the write_row(row) method of
FilterTable, like so::

    groupings_table.write_row(2, {
      name: "New name", 
      members: "New member", 
      graders: "New graders", 
      valid: true, 
      hidden_property: true
    }.toJSON());

However, after adding a row, if you want to immediately display the new data,
you must resort and render the table::

    groupings_table.resort_rows().render();

Removing a row
********************************************************************************

Simply use the remove_row(id) method, like so::

    groupings_table.remove_row(2);
    groupings_table.resort_rows().render();
