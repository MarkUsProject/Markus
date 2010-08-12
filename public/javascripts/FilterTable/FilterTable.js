/** FilterTable Class

Rules:
- This class requires/assumes the Prototype javascript library
**/

FILTERTABLE_SORT = null;

var FilterTable = Class.create({
  /* FilterTable Constructor
   *
   * The FilterTable constructor takes a Javascript object as its parameter.  So, for
   * example:
   *
   * var my_table = new FilterTable({
   *   table_id: 'student_table',
   *   headers: {
   *     user_name: {display: 'User Name', sortable: true},
   *     first_name: {display: 'First Name', sortable: true},
   *     last_name: {display: 'Last Name', sortable: true}
   *   },
   *   can_select: true,
   *   can_select_all: true,
   *   select_all_header: "All"
   *   can_sort: true,
   *   row_prefix: 'student_row_',
   *   select_name: 'students[]',
   *   select_id_prefix: 'student_',
   *   footer: true,
   *   filters: {
   *     inactive: function(table_row) {
   *       return table_row.hidden;
   *     },
   *     active: function(table_row) {
   *       return !table_row.hidden;
   *     }
   *   }
   * });
   *
   * For a full list of the options available for the constructor, see the MarkUs Wiki
   * article on the FilterTable component.
   */
  initialize: function(params) {
    this.table_id = $(params.table_id);
    this.can_select_all = this.set_or_default(params.can_select_all, false);
    this.can_select = this.set_or_default(params.can_select, false);
    this.select_all_header = this.set_or_default(params.select_all_header, "");
    this.row_prefix = params.row_prefix;
    this.select_name = params.select_name;
    this.select_id_prefix = params.select_id_prefix;
    this.headers = $H(params.headers);
    this.footer = params.footer;
    this.can_sort = this.set_or_default(params.can_sort, false);
    this.total_count_id = params.total_count_id;
    this.filter_count_ids = $H(params.filter_count_ids);
    // By default, we'll sort by id
    this.default_sort = this.set_or_default(params.default_sort, 'id');
    this.filters = $H(this.set_or_default(params.filters, null));

    // If we want extra TBODY elements above the main TBODY that FilterTable
    // uses, supply those IDs here, in order
    this.above_tbodys = $A(this.set_or_default(params.above_tbodys, null));

    // If we want extra TBODY elements above the main TBODY that FilterTable
    // uses, supply those IDs here, in order
    this.below_tbodys = $A(this.set_or_default(params.below_tbodys, null));


    // Filter callbacks
    this.after_clear_filters = this.set_or_default(params.after_clear_filters, null);
    this.after_filter_only_by = this.set_or_default(params.after_filter_only_by, null);

    this.sorts = $H(this.set_or_default(params.sorts, null));
    this.default_filters = $A(this.set_or_default(params.default_filters, null));

    // Default parameters can be overridden...
    this.header_id_prefix = this.set_or_default(params.header_id_prefix, 'FilterTable_header_');
    this.header_class = this.set_or_default(params.header_class, 'FilterTable_header');
    this.footer_id_prefix = this.set_or_default(params.footer_id_prefix, 'FilterTable_footer_');
    this.footer_class = this.set_or_default(params.footer_class, 'FilterTable_footer');

    this.sortable_class = this.set_or_default(params.sortable_class, 'FilterTable_sortable');
    this.sorting_by_class = this.set_or_default(params.sorting_by_class, 'FilterTable_sorting_by');

    this.sorting_reverse_class = this.set_or_default(params.sorting_reverse_class, 'FilterTable_sorting_by_reverse');

    this.selectable_class = this.set_or_default(params.selectable_class, 'FilterTable_selectable');
    this.select_onclick = this.set_or_default(params.select_onclick, null);

    this.select_all_top_id = this.set_or_default(params.select_all_top_id, 'FilterTable_select_all_top');
    this.select_all_bottom_id = this.set_or_default(params.select_all_bottom_id, 'FilterTable_select_all_bottom');

    this.json_table_data = [];
    this.current_filters = this.default_filters;
    this.current_sort = this.default_sort;
    this.table_body = null;
    this.sort_reverse = false;
    this.reset_filter_counts();
    this.construct_table();
    this.row_cache = {};
  },
  // Take some JSON data, and add it to the data store.
  populate: function(json_table_data) {
    this.table_data = $H(json_table_data.evalJSON());
    this.table_rows = this.table_data.values();
    this.construct_row_cache(this.table_rows);
    this.sort_by(this.default_sort);
    return this;
  },
  // Perform the sort of a column by the column key
  sort_by: function(sort_by_key) {
    this.perform_sort(sort_by_key);
    return this;
  },
  // Reverse the table rows
  reverse_rows: function() {
    this.table_rows.reverse();
    return this;
  },
  // Re-sort the table based on the current settings.  This is useful if you've
  // just added a new set of rows, and want to update the display.
  resort_rows: function() {
    this.perform_sort(this.current_sort);
    if(this.sort_reverse) {
      this.reverse_rows();
    }
    return this;
  },
  // Helper method for sort_by - actually does the sorting
  perform_sort: function(sort_by) {
    // If we're not sorting by the same thing we were already sorting by, try to remove
    // the sorting_by and sorting_reverse classes from those HTML elements
    if(this.current_sort != sort_by) {
      if($(this.header_id_prefix + this.current_sort) != null) {
        $(this.header_id_prefix + this.current_sort).removeClassName(this.sorting_by_class);
        $(this.header_id_prefix + this.current_sort).removeClassName(this.sorting_reverse_class);
      }
      if($(this.footer_id_prefix + this.current_sort) != null) {
        $(this.footer_id_prefix + this.current_sort).removeClassName(this.sorting_by_class);
        $(this.footer_id_prefix + this.current_sort).removeClassName(this.sorting_reverse_class);
      }
    }
    // We're now sorting by this new header key
    this.current_sort = sort_by;

    // If possible, add the sorting_by class to the header
    if ($(this.header_id_prefix + this.current_sort) != null) {
      $(this.header_id_prefix + sort_by).addClassName(this.sorting_by_class);
    }
    if ($(this.footer_id_prefix + this.current_sort) != null) {
      $(this.footer_id_prefix + sort_by).addClassName(this.sorting_by_class);
    }


    var sorting_function_key = sort_by;

    // Was there a general custom sort for this column?
    if(typeof this.headers.get(sort_by) != "undefined") {
      if(typeof this.headers.get(sort_by).sort_with != "undefined") {
        sorting_function_key = this.headers.get(sort_by).sort_with;
      }
    }

    FILTERTABLE_SORT = this.current_sort;
    // Was there a specific custom sort function for this column?
    if(typeof this.sorts.get(sorting_function_key) != "undefined") {
      this.table_rows.sort(this.sorts.get(sorting_function_key));
    } else {
      // Use some hackery to run Array.sort on our table data
      this.table_rows.sort(this.standard_sort);
    }
    FILTERTABLE_SORT = null;
  },
  // Add a filter to the current_filters collection
  add_filter: function(filter_key) {
    if(this.current_filters.indexOf(filter_key) == -1) {
      this.current_filters.push(filter_key);
    }
    return this;
  },
  // Remove a filter from the current_filters collection
  remove_filter: function(filter_key) {
    this.current_filters = this.current_filters.without(filter_key);
    return this;
  },
  get_current_filters: function() {
    return this.current_filters.clone();
  },
  // Clear all the filters
  clear_filters: function() {
    var current_filters = this.get_current_filters();
    if(this.after_clear_filters != null) {
      this.after_clear_filters.call(this, current_filters);
    }
    this.wipe_out_filters();
    return this;
  },
  wipe_out_filters: function() {
    this.current_filters = $A();
    return this;
  },
  // Only filter by this particular filter_key
  filter_only_by: function(filter_key) {
    var current_filters = this.get_current_filters();
    this.wipe_out_filters().add_filter(filter_key);
    if(this.after_filter_only_by != null) {
      this.after_filter_only_by.call(this, current_filters, filter_key);
    }
    return this;
  },
  reset_filter_counts: function() {
    this.filter_counts = $H();
    var me = this;
    this.filters.each(function(filter) {
      me.filter_counts.set(filter.key, 0);
    });
  },
  // Clear the contents of the table, visually.  Table data remains in memory.
  clear: function() {
    this.table_body.update('');
  },
  // Write a row to the table data in memory.  This will add a new row if the id doesn't
  // exist, or will replace the row if it does already exist.
  write_row: function(id, row) {
    this.table_data.set(id, row);
    this.table_rows = this.table_data.values();
    this.construct_row(row);
    return this;
  },
  write_rows: function(rows) {
    var rows = $H(rows);
    var me = this;
    rows.each(function(row) {
      me.write_row(row.key, row.value);
    });
  },
  // Removes a row with the given id.
  remove_row: function(id) {
    this.table_data.unset(id);
    this.row_cache[id] = undefined;
    this.table_rows = this.table_data.values();
    return this;
  },
  remove_rows: function(rows) {
    var rows = $A(rows);
    var me = this;
    rows.each(function(id) {
      me.remove_row(id);
    });
  },
  // Helper method for render to see if a table_row passes all filters
  pass_filters: function(table_row) {
    try {
      var me = this;

      // First, recalcuate for each filters count
      this.filters.each(function(filter_data) {
        if(filter_data.value.call(me, table_row)) {
          me.filter_counts.set(filter_data.key, me.filter_counts.get(filter_data.key) + 1);
        }
      });

      var pass_filters = true;
      this.current_filters.each(function(filter_key) {
        if(!me.filters.get(filter_key).call(me, table_row)) {
          pass_filters = false;
          throw $break;
        }
      });
      return pass_filters;
    } catch (e) {
      //TODO:  Graceful-ize this
      alert('Something went wrong: ' + e);
    }
  },
  // Display the sorted/filtered contents of the table.
  render: function() {
    this.reset_filter_counts();
    this.clear();
    var me = this;
    this.table_rows.each(function(table_row) {
      if(me.pass_filters(table_row)) {
        me.table_body.insert(me.retrieve_from_row_cache(table_row.id));
      }
    });
    this.render_counts();
    this.select_all(false);
    this.select_all_toggles(false);

  },
  render_counts: function() {
    if($(this.total_count_id) != null) {
      $(this.total_count_id).update(this.table_rows.size());
    }
    var me = this;
    this.filter_count_ids.each(function(filter_count_id) {
      if($(filter_count_id.value) != null) {
        $(filter_count_id.value).update(me.filter_counts.get(filter_count_id.key));
      }
    });
  },
  retrieve_from_row_cache: function(row_id) {
    return this.row_cache[row_id];
  },
  construct_row_cache: function(table_rows) {
    var me = this;
    table_rows.each(function(table_row) {
      me.construct_row(table_row);
    });
  },
  // Helper method used by render() - builds the HTML that will display the table row.
  construct_row: function(row) {
    try {
      var tr_element = new Element('tr', {id: this.row_prefix + row.id});
      var row_contents = row['filter_table_row_contents'].split('</td>')

      if(this.can_select) { //Make the select box
        var checkbox_element = new Element('input', {type: 'checkbox', name: this.select_name, value: row.id, id: this.select_id_prefix + row.id, "class": this.selectable_class, "onclick": this.select_onclick});
        var td_element = new Element('td');
        td_element.insert(checkbox_element);
        tr_element.insert({top: td_element});
      }
      var select = this.can_select
      var prefix = this.select_id_prefix
      this.headers.each(function(column_header, index) {
        var td_element = new Element('td');
        if(index == 0 && select){
          var label_element = new Element ('label', {"class": "inline_label", "for": prefix + row.id});
          label_element.insert(row_contents[0]);
          td_element.insert(label_element);
        }
        else {
          td_element.innerHTML = row_contents[index];
        }
        if(column_header.value['row_class'] != undefined) {
          td_element.addClassName(column_header.value['row_class']);
        }
        tr_element.insert(td_element);
      });
    }
    catch (e) {
      //TODO: More helpful error
      alert("Something went wrong: " + e);
    }
    this.row_cache[row.id] = tr_element;
    return tr_element;
  },
  // On initialization, this function constructs the table
  construct_table: function() {
    var me = this;

    var thead_element = new Element('thead');
    var thead_tr = new Element('tr');
    thead_element.insert(thead_tr);
    var tfoot_element = new Element('tfoot');
    var tfoot_tr = new Element('tr');
    tfoot_element.insert(tfoot_tr);

    this.table_body = new Element('tbody');

    this.headers.each(function(header_data) {
      var th_element_header = new Element('th', {id: me.header_id_prefix + header_data.key, "class": me.header_class }).update(header_data.value.display);
      var th_element_footer = new Element('td', {id: me.footer_id_prefix + header_data.key, "class": me.footer_class} ).update(header_data.value.display);

      if(me.can_sort && header_data.value.sortable) {
        th_element_header.addClassName(me.sortable_class);
        th_element_footer.addClassName(me.sortable_class);
        if(header_data.key == me.default_sort) {
          th_element_header.addClassName(me.sorting_by_class);
          th_element_footer.addClassName(me.sorting_by_class);
        }
        th_element_header.observe('click', function() {
          me.click_header(header_data.key);
        });
        th_element_footer.observe('click', function() {
          me.click_header(header_data.key);
        });
      }
      thead_tr.insert({bottom: th_element_header});
      tfoot_tr.insert({bottom: th_element_footer});
    });

    if(this.can_select) {
      var th_element_head = new Element('th');
      var th_element_foot = new Element('th');
      thead_tr.insert({top: th_element_head});
      tfoot_tr.insert({top: th_element_foot});
    }

    if(this.can_select && this.can_select_all) {

      var select_all_top_div = new Element('div');
      var select_all_top = new Element('input', {type: 'checkbox', id: this.select_all_top_id, "class": 'FilterTable_selectable'});
      var label_select_all_top = new Element ('label', {"for": select_all_top.id, "class": 'bold_inline_label'});
      label_select_all_top.insert(this.select_all_header);
      select_all_top_div.insert(select_all_top);
      select_all_top_div.insert(label_select_all_top);

      var select_all_function = function(event) {
        me.select_all($F(Event.element(event)));
      }

      select_all_top.observe('click', select_all_function);

      th_element_head.insert({top: select_all_top_div});

      var select_all_bottom_div = new Element('div');
      var select_all_bottom = new Element('input', {type: 'checkbox', id: this.select_all_bottom_id, "class": 'FilterTable_selectable'});
      var label_select_all_bottom = new Element ('label', { "for": select_all_bottom.id,  "class": 'bold_inline_label'});
      label_select_all_bottom.insert(this.select_all_header)
      select_all_bottom_div.insert  (select_all_bottom);
      select_all_bottom_div.insert(label_select_all_bottom);
        th_element_foot.insert({bottom: select_all_bottom_div});

      select_all_bottom.observe('click', select_all_function);

    }

    this.table_id.insert({top: thead_element});

    if(this.footer) {
      this.table_id.insert({bottom: tfoot_element});
    } else {
      delete tfoot_element;
    }

    this.above_tbodys.each(function(tbody_id) {
        me.table_id.insert({bottom: new Element('tbody', {id: tbody_id})});
    });

    this.table_id.insert({bottom: this.table_body});

    this.below_tbodys.each(function(tbody_id) {
        me.table_id.insert({bottom: new Element('tbody', {id: tbody_id})});
    });



  },
  // Function to select all rows if selectable.
  select_all: function(is_selected) {
    $$('.' + this.selectable_class).each(function(node) {
      $(node).setValue(is_selected);
      if($(node).onclick != null && $(node).onclick != undefined ){
        $(node).onclick();
      }
    });
  },
  select_all_toggles: function(is_selected) {
   if(this.can_select && this.can_select_all) {
      $(this.select_all_top_id).setValue(false);
      if(this.footer) {
        $(this.select_all_bottom_id).setValue(false);
      }
    }
  },
  focus_row: function(row_id) {
    var row = $(this.select_id_prefix + row_id);
    if(row != null) {
      row.scrollTo();
    }
  },
  // When all else fails, do the standard_sort...
  // Return 1 if a > b, or -1 if a < b.
  standard_sort: function(a, b) {
    if (typeof(a[FILTERTABLE_SORT]) == 'string') {
      return (a[FILTERTABLE_SORT].toLowerCase() > b[FILTERTABLE_SORT].toLowerCase()) ? 1 : -1;
    }
    return (a[FILTERTABLE_SORT] > b[FILTERTABLE_SORT]) ? 1 : -1;
  },
  // The click handler for headers
  click_header: function(header_key) {
    if(this.current_sort == header_key && !this.sort_reverse) {
      this.sort_reverse = true;
      if($(this.header_id_prefix + this.current_sort) != null) {
        $(this.header_id_prefix + this.current_sort).addClassName(this.sorting_reverse_class);
      }
      if($(this.footer_id_prefix + this.current_sort) != null) {
        $(this.footer_id_prefix + this.current_sort).addClassName(this.sorting_reverse_class);
      }
      this.reverse_rows().render();
    } else {
      if($(this.header_id_prefix + this.current_sort) != null) {
        $(this.header_id_prefix + this.current_sort).removeClassName(this.sorting_reverse_class);
      }
      if($(this.footer_id_prefix + this.current_sort) != null) {
        $(this.footer_id_prefix + this.current_sort).removeClassName(this.sorting_reverse_class);
      }
      this.sort_reverse = false;
      this.sort_by(header_key).render();
    }
  },
  // Utility method to either return a value if not "undefined", or return a default
  // value.  This is used in the constructor.
  set_or_default: function(value, default_value) {
    if (typeof value == 'undefined') {
      return default_value;
    } 
    return value;
  }
});
