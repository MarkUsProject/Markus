/** @jsx React.DOM */

TableSearch = React.createClass({
  // Tells parent that the search box changed. Consider using event.target.value instead?
  searchInputChanged: function() {
    this.props.onSearchInputChange(this.refs.searchText.getDOMNode().value);
  },
  render: function() {
    return (
      <input 
        type="text"
        placeholder={this.props.placeholder_text}
        value={this.props.search_text}
        ref="searchText"
        onChange={this.searchInputChanged} />
    );
  }
});

// The filters for the student table. Filters are All, Active, and Inactive.
StudentsTableFilter = React.createClass({
  // Tells parent that filter changed and to adjust accordingly.
  filterClicked: function(event) {
    this.props.onFilterChange(event.currentTarget.id);
  },
  render: function() {
    // Number of students, active and inactive.
    var number_all = this.props.students.length;
    var number_active = this.props.students.filter(
      function(student) { return !student.hidden }).length;
    var number_not_active = number_all - number_active;

    // Constructing the filters here.
    var all = (this.props.filter == 'all' ?
               <span>All ({number_all})</span> :
               <a id="all" onClick={this.filterClicked}>
                 {this.props.filters_text.all}({number_all})
               </a>);
    var active = (this.props.filter == 'active' ?
                  <span>Active ({number_active})</span> :
                  <a id="active" onClick={this.filterClicked}>
                    {this.props.filters_text.active} ({number_active})
                  </a>);
    var not_active = (this.props.filter == 'not_active' ?
                      <span>Not active ({number_not_active})</span> :
                      <a id="not_active" onClick={this.filterClicked}>
                        {this.props.filters_text.not_active} ({number_not_active})
                      </a>);
    return (
      <div>
        {all} | {active} | {not_active}
      </div>
    );
  }
});

TableHeader = React.createClass({
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
        var arrow_indicator = "";
        var clss = "sortable";
        if (this.props.sort_column == column.id) {
          if (this.props.sort_direction == "asc") {
            arrow_indicator = ' ▲';
            clss += " asc";
          } else {
            arrow_indicator = ' ▼';
            clss += " desc";
          }
        }
        return <th id={column.id} class={clss} onClick={this.headerColumnClicked}>{column.content + arrow_indicator}</th>
      }
      return <th>{column.content}</th>
    }.bind(this));

    return (
      <thead>
        <tr>
          {header_columns}
        </tr>
      </thead>
    );
  }
});

