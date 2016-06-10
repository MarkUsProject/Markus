/** @jsx React.DOM */

/* This is the component that implements a filterable,
 * sortable, and searchable table.
 *
 * Props:
 *   data - an array of javascript objects. Each object's attributes
 *          will be used to populate the table. You define the attributes
 *          (and columns, later) yourself. Each object must have a unique 'id'
 *          attribute. These attributes must be strings or React DOM objects.
 *          N.B. the array can be empty, this is usually useful in the initial
 *          state while you're waiting on an AJAX call to return stuff.
 *
 *   search_placeholder - a string for the placeholder text in the search
 *                        bar. This is optional. Try to make it i18n.
 *
 *   columns - an array of javascript objects with these attributes:
 *                  - id: the key Table uses to access each object. Must be a string.
 *                  - content: the stuff that gets placed in the table header.
 *                             Must be a string or React DOM object.
 *                             Remember to make this I18n.
 *                  - sortable: boolean that determines whether a column is sortable.
 *                  - compare: a function defining custom comparison behaviour
 *                             for sorting by column. Leave undefined to use the
 *                             default comparison operators.
 *                  - searchable: boolean that determines whether the stuff in a column
 *                                can be searched.
 *             columns is used to create the table header.
 *
 *  filters - an array of javascript objects with these attributes:
 *                  - name: a name for the filter. This doesn't really serve any purpose actually.
 *                  - text: the text used for the filter, like 'All', 'Completed', etc. Remember
 *                          to make this I18n.
 *                  - func: the filter function that gets applied over every data object when
 *                          a filter is activated. An object belonging to the filter should return
 *                          true to this method (and the contrapositive of this statement).
 *
 *  secondary_filters - an array of javascript objects of the same form as in filters for an additional set of filters
 *
 *  filter_type - a boolean that determines how the filter is styled. Pass true if you want a select dropdown
 *                or false for a flat listing. Usually you want the dropdown if there are 3+ filters.
 *
 *  selectable - a boolean for whether the elements in the data can be selected. This adds a checkbox to the header
 *               and to each row. Also see below.
 *
 *  onSelectedRowsChange - a function that is called every time a row is selected or unselected. The implementation
 *                         defines one argument, which is an array of the selected data objects. Please see the
 *                         StudentsTable for a usage example.
 */

var Table = React.createClass({displayName: 'Table',
  propTypes: {
    data: React.PropTypes.array,
    search_placeholder: React.PropTypes.string,
    columns: React.PropTypes.array,
    filters: React.PropTypes.array, // Optional: pass null
    secondary_filters: React.PropTypes.array, // Optional: pass null
    filter_type: React.PropTypes.bool, // True for select filter, falsy for simple
    selectable: React.PropTypes.bool, // True if you want checkboxed elements
    onSelectedRowsChange: React.PropTypes.func // function to call when selected rows change
  },
  getDefaultProps: function() {
      return {
          search: true,
          footer: true
      }
  },
  getInitialState: function() {
    var first_sortable_column = this.props.columns.filter(function(col) {
      return col.sortable == true;
    })[0];
    var first_filter_name =
        this.props.filters ? this.props.filters[0].name : null;
    var first_filter_func =
        this.props.filters ? this.props.filters[0].func : null;
    var first_secondary_filter_name =
        this.props.secondary_filters ? this.props.secondary_filters[0].name : null;
    var first_secondary_filter_func =
        this.props.secondary_filters ? this.props.secondary_filters[0].func : null;
    return {
      visible_rows: [],
      selected_rows: [],
      filter: first_filter_name,
      filter_func: first_filter_func,
      secondary_filter: first_secondary_filter_name,
      secondary_filter_func: first_secondary_filter_func,
      sort_column: first_sortable_column.id,
      sort_direction: 'asc',
      sort_compare: first_sortable_column.compare,
      header_selected: false
    }
  },
  componentDidMount: function() {
    this.setState({visible_rows: this.updateVisibleRows({})});
  },
  componentWillReceiveProps: function(nextProps) {
    this.setState({visible_rows: this.updateVisibleRows({data:nextProps.data})});
  },
  // A filter was clicked. Adjust state accordingly.
  synchronizeFilter: function(filter) {
    var filter_func = this.props.filters.filter(function(fltr) {
        return fltr.name == filter;
      })[0].func;
    var visible_rows = this.updateVisibleRows({
      filter_func: filter_func
    });
    this.setState({
      filter: filter,
      filter_func: filter_func,
      visible_rows: visible_rows
    });
  },
  // A secondary filter was clicked. Adjust state accordingly.
  synchronizeSecondaryFilter: function(filter) {
    var filter_func = this.props.secondary_filters.filter(function(fltr) {
        return fltr.name == filter;
      })[0].func;
    var visible_rows = this.updateVisibleRows({
      secondary_filter_func: filter_func
    });
    this.setState({
      secondary_filter: filter,
      secondary_filter_func: filter_func,
      visible_rows: visible_rows
    });
  },
  // Search input changed. Adjust state accordingly.
  synchronizeSearchInput: function(search_text) {
    var visible_rows = this.updateVisibleRows({search_text: search_text});
    this.setState({
      search_text: search_text.toLowerCase(),
      visible_rows: visible_rows
    });
  },
  // Header col was clicked. Adjust state accordingly.
  synchronizeHeaderColumn: function(sort_column, sort_direction) {
    var compare_func = this.props.columns.filter(function(col) {
        return col.id == sort_column;
    })[0].compare;
    this.setState({
      sort_column: sort_column,
      sort_direction: sort_direction,
      sort_compare: compare_func
    });
  },
  headerCheckboxClicked: function(event) {
    var value = event.currentTarget.checked;
    var new_selected_rows = null;
    if (value) {
      new_selected_rows = this.state.visible_rows.map(function(x){return x.id});
    } else {
      new_selected_rows = [];
    }
    this.setState({selected_rows: new_selected_rows, header_selected: value});
    this.props.onSelectedRowsChange(new_selected_rows);
  },
  rowCheckboxClicked: function(event) {
    var value = event.currentTarget.checked;
    var row_id = parseInt(event.currentTarget.parentNode.parentNode.getAttribute('id'), 10);

    var new_selected_rows = this.state.selected_rows.slice();
    if (value) {
      new_selected_rows.push(row_id);
    } else {
      new_selected_rows.splice(new_selected_rows.indexOf(row_id), 1);
    }
    this.setState({selected_rows:new_selected_rows});
    this.props.onSelectedRowsChange(new_selected_rows);
  },
  clearCheckboxes: function() {
    this.setState({selected_rows: [], header_selected: false});
  },
  // If search input or filter changed, pass the changed item into an object changed inhere
  // and it'll return the new visible rows so you can update the state with it.
  updateVisibleRows: function(changed) {
    var searchables = this.props.columns.filter(function(col) {
      return col.searchable;
    }).map(function(col) {
      return col.id;
    });

    var new_data = changed.hasOwnProperty('data') ? changed.data : this.props.data;
    var filter_function = changed.hasOwnProperty('filter_func') ? changed.filter_func : this.state.filter_func;
    var secondary_filter_function = changed.hasOwnProperty('secondary_filter_func') ? changed.secondary_filter_func : this.state.secondary_filter_func;
    var search_text = changed.hasOwnProperty('search_text') ? changed.search_text: this.state.search_text;

    var filtered_data = filter_data(new_data,
                                    filter_function);
    var secondary_filtered_data = filter_data(filtered_data,
                                    secondary_filter_function);
    var searched_data = search_data(secondary_filtered_data,
                                    searchables,
                                    search_text);
    var visible_data = searched_data;
    return visible_data;
  },
  render: function() {
    var columns = null;
    if (this.props.selectable) {
      columns = [{id:'checkbox', content:
        React.DOM.input({type:'checkbox', checked:this.state.header_selected, onChange:this.headerCheckboxClicked})}]
        .concat(this.props.columns);
    } else {
      columns = this.props.columns;
    }
    var secondary_filter_div = null;
    if (this.props.secondary_filters != null) {
      secondary_filter_div = TableFilter( {
        filters:        this.props.secondary_filters,
        current_filter: this.state.secondary_filter,
        onFilterChange: this.synchronizeSecondaryFilter,
        data:           this.props.data,
        filter_type:    this.props.filter_type
      });
    }
    var footer_div = TableFooter( {
      columns:        columns,
      sort_column:    this.state.sort_column,
      sort_direction: this.state.sort_direction } );
    if (!this.props.footer) {
      footer_div = null;
    }
    var search_div = TableSearch( {
      onSearchInputChange: this.synchronizeSearchInput,
      placeholder:         this.props.search_placeholder} );
    if (!this.props.search) {
      search_div = null;
    }
    return (
      React.DOM.div( {className:"react-table"},
        TableFilter( {
          filters:          this.props.filters,
          current_filter:   this.state.filter,
          onFilterChange:   this.synchronizeFilter,
          data:             this.props.data,
          filter_type:      this.props.filter_type} ),
        secondary_filter_div,
        search_div,
        React.DOM.div( {className:"table"},
          React.DOM.table( {},
            TableHeader( {
              columns:              columns,
              sort_column:          this.state.sort_column,
              sort_direction:       this.state.sort_direction,
              onHeaderColumnChange: this.synchronizeHeaderColumn} ),
            TableRows( {
              columns:              columns,
              rowCheckboxClicked:   this.rowCheckboxClicked,
              selectable:           this.props.selectable,
              getVisibleRows:       this.updateVisibleRows,
              state:                this.state} ),
            footer_div
          )
        )
      )
    );
  }
});

TableSearch = React.createClass({displayName: 'TableSearch',
  // Tells parent that the search box changed.
  // Consider using event.target.value instead?
  searchInputChanged: function() {
    this.props.onSearchInputChange(this.refs.searchText.getDOMNode().value);
  },
  render: function() {
    return (
      React.DOM.div( {className:"table-search"},
        React.DOM.input(
          {type:"text",
          placeholder:this.props.placeholder,
          value:this.props.search_text,
          ref:"searchText",
          onChange:this.searchInputChanged} )
      )
    );
  }
});

TableFilter = React.createClass({displayName: 'TableFilter',
  propTypes: {
      filters: React.PropTypes.array,
      current_filter: React.PropTypes.string,
      data: React.PropTypes.array,
      onFilterChange: React.PropTypes.func,
      filter_type: React.PropTypes.bool
   },
   render: function() {
     if (this.props.filters) {
       if (this.props.filter_type) {
         return (SelectTableFilter( {filters:this.props.filters,
           current_filter:this.props.current_filter,
           onFilterChange:this.props.onFilterChange} ));
       } else {
         return (SimpleTableFilter( {filters:this.props.filters,
           current_filter:this.props.current_filter,
           data:this.props.data,
           onFilterChange:this.props.onFilterChange}));
       }
     } else {
       return (React.DOM.div(null));
     }
   }
});

SimpleTableFilter = React.createClass({displayName: 'SimpleTableFilter',
  propTypes: {
    filters: React.PropTypes.array,
    current_filter: React.PropTypes.string,
    data: React.PropTypes.array,
    onFilterChange: React.PropTypes.func
  },
  // Tells parent that filter changed and to adjust accordingly.
  filterClicked: function(event) {
    this.props.onFilterChange(event.currentTarget.id);
  },
  render: function() {
    var filters_dom = [];

    for (var i = 0; i < this.props.filters.length; i++) {
      // Get number of elements that pass filter
      var number = this.props.data.filter(this.props.filters[i].func).length;
      var fltr =
        (this.props.current_filter == this.props.filters[i].name ?
         React.DOM.span( {key:this.props.filters[i].name},
           this.props.filters[i].text + " (" + number + ")"
           ) :
          React.DOM.a( {key:this.props.filters[i].name,
            id:this.props.filters[i].name,
            onClick:this.filterClicked},
            this.props.filters[i].text + " (" + number + ")"
          ));
      filters_dom.push(fltr);
    }
    return (
      React.DOM.div({className:"table-filters"},
        filters_dom
      )
    );
  }
});

SelectTableFilter = React.createClass({displayName: 'SelectTableFilter',
  propTypes: {
    filters: React.PropTypes.array,
    current_filter: React.PropTypes.string,
    onFilterChange: React.PropTypes.func
  },
  // Tells parent that filter changed and to adjust accordingly.
  filterChanged: function(event) {
    this.props.onFilterChange(event.currentTarget.value);
  },
  render: function() {
    var filters_dom = [];
    for (var i = 0; i < this.props.filters.length; i++) {
      var filter = React.DOM.option( {value:this.props.filters[i].name}, this.props.filters[i].text)
      filters_dom.push(filter);
    }
    return (
      React.DOM.select(
        {
          value:this.current_filter,
          onChange:this.filterChanged
        },
        filters_dom
      )
    );
  }
});

TableHeader = React.createClass({displayName: 'TableHeader',
  propTypes: {
    columns: React.PropTypes.array,
    sort_column: React.PropTypes.string,
    sort_direction: React.PropTypes.string,
    selectable: React.PropTypes.bool,
    onHeaderColumnChange: React.PropTypes.func
  },
  headerColumnClicked: function(event) {
    if (event.currentTarget.id == this.props.sort_column) {
      var new_direction = (this.props.sort_direction == 'asc' ? 'desc' : 'asc');
      this.props.onHeaderColumnChange(event.currentTarget.id, new_direction);
    } else {
      this.props.onHeaderColumnChange(event.currentTarget.id, 'asc');
    }
  },
  render: function() {
    // Create the header columns, in proper <th>'s.
    var header_columns = this.props.columns.map(function(column) {
      if (column.sortable == true) {
        var clss = 'sortable-col';
        if (this.props.sort_column == column.id) {
          // Add classes for css to style with indicators.
          // This class is only applied to the currently sorted column.
          clss += (this.props.sort_direction == 'asc' ? ' asc' : ' desc');
        }
        return React.DOM.th( {key:column.id, id:column.id, className:clss,
          onClick:this.headerColumnClicked}, React.DOM.span(null,
          [column.content]))
      }
      return React.DOM.th( {key:column.id, id:column.id}, column.content)
    }.bind(this));

    return (
      React.DOM.thead(null,
        React.DOM.tr(null,
          header_columns
        )
      )
    );
  }
});

TableFooter = React.createClass({displayName: 'TableFooter',
  propTypes: {
    sort_column: React.PropTypes.string,
    sort_direction: React.PropTypes.string,
    columns: React.PropTypes.array
  },
  render: function() {
    // Create the footer columns
    var footer_columns = this.props.columns.map(function(column) {
      if (column.sortable == true) {
        var clss = 'sortable-col';
        if (this.props.sort_column == column.id) {
          // Add classes for css to style with indicators.
          // This class is only applied to the currently sorted column.
          clss += (this.props.sort_direction == 'asc' ? ' asc' : ' desc');
        }
        return React.DOM.td( {className:clss}, React.DOM.span(null,
          [column.content]))
      }
      return React.DOM.td( null, column.content)
    }.bind(this));

    return (
      React.DOM.tfoot(null,
        React.DOM.tr(null,
          footer_columns
        )
      )
    );
  }
});

// rows
TableRows = React.createClass({displayName: 'TableRows',
  propTypes: {
    columns: React.PropTypes.array,
    selectable: React.PropTypes.bool,
    rowCheckboxClicked: React.PropTypes.func,
    getVisibleRows: React.PropTypes.func,
    state: React.PropTypes.object
  },

  render: function() {
    var visible_data = this.props.getVisibleRows({});
    var sorted_data = sort_by_column(visible_data,
                                     this.props.state.sort_column,
                                     this.props.state.sort_direction,
                                     this.props.state.sort_compare);

    var final_data = null;
    if (this.props.selectable) {
      final_data = sorted_data.map(function(row) {
        var checked = this.props.state.selected_rows.indexOf(row.id) !== -1;
        row['checkbox'] = React.DOM.input( {type:'checkbox',
          onChange:this.props.rowCheckboxClicked,
          checked:checked});
        return row;
      }.bind(this));
    } else {
      final_data = sorted_data;
    }

    // create rows
    // consider instead of recreating array each time, just hiding the rows.
    var rows = [];
    for (var i = 0; i < final_data.length; i++) {
      rows.push(
        TableRow( {key:final_data[i].id,
          row_object:final_data[i],
          columns:this.props.columns})
      );
    }

    return (
      React.DOM.tbody(null,
        rows
      )
    );
  }
});

// a single row.
TableRow = React.createClass({displayName: 'TableRow',
  propTypes: {
    row_object: React.PropTypes.object,
    columns: React.PropTypes.array
  },
  render: function() {
    cells = [];

    // go through object and get data into table cells
    for (var i = 0; i < this.props.columns.length; i++) {
      var key = this.props.columns[i].id;
      cells.push(
        React.DOM.td( {key:key},
          this.props.row_object[key]
        )
      );
    }
    return (
      React.DOM.tr( {id:this.props.row_object.id,
                     className: this.props.row_object.class_name},
        cells
      )
    );
  }
});

function filter_data(data, filter_func) {
  if (filter_func) {
    return data.filter(filter_func);
  } else {
    return data;
  }
}

function search_data(data, searchables, search_text) {
  if (search_text) {
    return data.filter(function(datum) {
      for (var i = 0; i < searchables.length; i++) {
        if (search_item(search_text, datum[searchables[i]])) {
          return true;
        }
      }
    });
  } else {
    return data;
  }
}

function search_item(search_text, item) {
  if (item.hasOwnProperty('props')) {
    // is a React Component- need to get innerHTML
    return item.props.children.toLowerCase().indexOf(search_text) !== -1
  } else {
    return item.toLowerCase().indexOf(search_text) !== -1
  }
}

function sort_by_column(data, column, direction, compare) {
  // determine sort behaviour
  function makeComparable(a)
  {
    if (typeof a === 'string') {
      return a.toLowerCase().replace(' ', '');
    } else if (a.hasOwnProperty('props')) {
      // Is a react Grade Box
      if (a.props.hasOwnProperty('grade_entry_column') || 
          a.props.hasOwnProperty('data-grade-entry-item-id')) {
        return a;
      // Contains image
      } else if (a.props.hasOwnProperty('src')) {
        return a.props.src;
      // Is a react component, get innerHTML
      } else if (a.props.hasOwnProperty('dangerouslySetInnerHTML')) {
        return a.props.dangerouslySetInnerHTML.__html.toLowerCase();
      } else {
        return React.renderComponentToString(a);
      }
    }
    return a;
  }

  if (typeof compare === 'string') {
    compare = window[compare]
  }

  compare = compare || compare_values;

  // sort row by column id
  var sorted = data.sort(function(a, b) {
    return compare(makeComparable(a[column]), makeComparable(b[column]));
  });

  // flip order if direction descending
  if (direction == 'desc') {
      sorted.reverse();
  }

  return sorted;
}

