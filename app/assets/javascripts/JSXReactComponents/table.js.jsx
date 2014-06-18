/** @jsx React.DOM */

Table = React.createClass({displayName: 'Table',
  propTypes: {
    data: React.PropTypes.array,
    search_placeholder: React.PropTypes.string,
    columns: React.PropTypes.array,
    filters: React.PropTypes.array, // Optional: pass null
  },
  getInitialState: function() {
    var first_sortable_column = this.props.columns.filter(function(col) {
      return col.sortable == true;
    })[0].id;

    var first_filter_name = this.props.filters ? this.props.filters[0].name : null;
    var first_filter_func = this.props.filters ? this.props.filters[0].func : null;

    return {
      filter: first_filter_name,
      filter_func: first_filter_func,
      sort_column: first_sortable_column,
      sort_direction: 'asc'
    }
  },
  // A filter was clicked. Adjust state accordingly.
  synchronizeFilter: function(filter) {
    var filter_func = this.props.filters.filter(function(fltr) {
        return fltr.name == filter;
      })[0].func;

    this.setState({
      filter: filter,
      filter_func: filter_func
    });
  },
  // Search input changed. Adjust state accordingly.
  synchronizeSearchInput: function(search_text) {
    this.setState({
      search_text: search_text.toLowerCase()
    });
  },
  // Header col was clicked. Adjust state accordingly.
  synchronizeHeaderColumn: function(sort_column, sort_direction) {
    this.setState({
      sort_column: sort_column, 
      sort_direction: sort_direction
    });
  },
  render: function() {
    return (
      React.DOM.div(null, 
        TableFilter( {filters:this.props.filters,
          current_filter:this.state.filter, 
          onFilterChange:this.synchronizeFilter,
          data:this.props.data}
        ),
        TableSearch( {onSearchInputChange:this.synchronizeSearchInput,
          placeholder:this.props.search_placeholder} ),
        React.DOM.table( {className:"table"}, 
          TableHeader( {columns:this.props.columns,
            sort_column:this.state.sort_column,
            sort_direction:this.state.sort_direction,
            onHeaderColumnChange:this.synchronizeHeaderColumn} ),
          TableRows( {columns:this.props.columns,
                     data:this.props.data,
                     state:this.state} )
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
      React.DOM.input( 
        {type:"text",
        placeholder:this.props.placeholder,
        value:this.props.search_text,
        ref:"searchText",
        onChange:this.searchInputChanged} )
    );
  }
});

TableFilter = React.createClass({displayName: 'TableFilter',
  propTypes: {
    filters: React.PropTypes.array,
    current_filter: React.PropTypes.string,
    data: React.PropTypes.array
  },
  // Tells parent that filter changed and to adjust accordingly.
  filterClicked: function(event) {
    this.props.onFilterChange(event.currentTarget.id);
  },
  render: function() {
    if (this.props.filters) {
      var filters_dom = [];

      for (var i = 0; i < this.props.filters.length; i++) {
        // Get number of elements that pass filter
        var number = this.props.data.filter(this.props.filters[i].func).length;
        var fltr = 
          (this.props.current_filter == this.props.filters[i].name ?
           React.DOM.span( {key:this.props.filters[i].name}, 
             this.props.filters[i].text, " (",number,")"
             ) :
            React.DOM.a( {key:this.props.filters[i].name,
              id:this.props.filters[i].name,
              onClick:this.filterClicked}, 
              this.props.filters[i].text, " (",number,")"
            ));
        filters_dom.push(fltr);
        filters_dom.push(' ');
      }
      return (
        React.DOM.div(null, 
          filters_dom
        )
      );
    } else {
      return (
        React.DOM.div(null)
      );
    }
  }
});


TableHeader = React.createClass({displayName: 'TableHeader',
  propTypes: {
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
    // Create the header columns, in proper <th>'s and stuff.
    var header_columns = this.props.columns.map(function(column) {
      if (column.sortable == true) {
        var arrow_indicator = '';
        var clss = 'sortable';
        if (this.props.sort_column == column.id) {
          if (this.props.sort_direction == 'asc') {
            arrow_indicator = ' ▲';
            clss += ' asc';
          } else {
            arrow_indicator = ' ▼';
            clss += ' desc';
          }
        }
        return React.DOM.th( {key:column.id, id:column.id, className:clss,
        onClick:this.headerColumnClicked}, column.content + arrow_indicator)
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

// rows
TableRows = React.createClass({displayName: 'TableRows',
  propTypes: {
    columns: React.PropTypes.array,
    data: React.PropTypes.array,
    state: React.PropTypes.object
  },

  render: function() {
    var searchables = this.props.columns.filter(function(col) {
      return col.searchable == true;
    }).map(function(col) {
      return col.id;
    });

    var filtered_data = filter_data(this.props.data,
                                    this.props.state.filter_func);

    var searched_data = search_data(filtered_data,
                                    searchables, 
                                    this.props.state.search_text);
    
    var sorted_data = sort_by_column(searched_data,
                                     this.props.state.sort_column,
                                     this.props.state.sort_direction);

    // create rows
    // consider instead of recreating array each time, just hiding the rows.
    var rows = [];
    for (var i = 0; i < sorted_data.length; i++) {
      rows.push(
        TableRow( {key:sorted_data[i].id,
          row_object:sorted_data[i],
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

//single row.
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
      React.DOM.tr( {id:this.props.row_object.id}, 
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
        if (datum[searchables[i]].toLowerCase().indexOf(search_text) != -1) {
          return true;
        }
      }
      return false;
    });
  } else {
    return data;
  }
}

function sort_by_column(data, column, direction) {
  function makeSortable(a)
  {
    if (typeof a == 'string') {
      return a.toLowerCase().replace(' ', '');
    } else {
      return a;
    }
  }
  // sorts column id
  var r = data.sort(function(a, b) {
    if (makeSortable(a[column]) > makeSortable(b[column])) {
      return 1;
    } else if (makeSortable(b[column]) > makeSortable(a[column])) {
      return -1;
    }
    return 0;
  });
  // flips order if direction descending.
  if (direction == 'desc') r.reverse();

  return r;
}
