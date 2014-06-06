/** @jsx React.DOM */

// The parent component. Implements all the callbacks from children
// to synchronize state, and ultimately renders everything.
StudentsTable = React.createClass({
  getInitialState: function() {
    return {
      students: [],
      selected_students: [],
      filter: 'all',
      search_text: '',
      sort_column: 'user_name',
      sort_direction: 'asc'
    }
  },
  componentWillMount: function() {
    this.refresh();
  },
  // Asks for new info from backend and sets props accordingly.
  refresh: function() {
    jQuery.ajax({
      method: "GET",
      url: "/students",
      dataType: "json",
      success: function(data) {
        var students = data[0];
        this.setState({
          students: students
        });
      }.bind(this)
    });
  },
  // Checkbox clicked (this must be in the parent since we're passing the box down from here)
  checkboxAllClicked: function(event) {
    var value = event.currentTarget.checked;
    if (value) {
      var new_selected_students = this.state.students.slice();
      this.setState({
        selected_students: new_selected_students
      });
    } else {
      this.setState({
        selected_students: []
      });
    }
  },
  // The checkbox on one of the table rows was clicked.
  synchronizeCheckboxRow: function(student, value) {
    // Figure out new selected_students state...
    if (value == true) {
      var new_selected_students = this.state.selected_students.concat(student);
          } else {
      var new_selected_students = this.state.selected_students.splice();
      new_selected_students.splice(new_selected_students.indexOf(student), 1);
      if (new_selected_students == []) {
        this.synchronizeCheckboxAll(false);
      }
    }
    this.setState({
      selected_students: new_selected_students
    });

    // If we change a checkbox and all of them become checked
    // or unchecked, change AllCheckbox appropriately.
    if (this.state.selected_students == this.state.students) {
      this.synchronizeCheckboxAll(true);
    } else if (this.state.selected_students == []) {
      this.synchronizeCheckboxAll(false);
    }
  },
  // A filter was clicked. Adjust state accordingly.
  synchronizeFilter: function(filter) {
    this.setState({
      filter: filter
    });
  },
  // Search input changed. Adjust state accordingly.
  synchronizeSearchInput: function(search_text) {
    this.setState({
      search_text: search_text.toLowerCase()});
  },
  // Header col was clicked. Adjust state accordingly.
  synchronizeHeaderColumn: function(sort_column, sort_direction) {
    this.setState({
      sort_column: sort_column, 
      sort_direction: sort_direction
    });
  },

  render: function() {
    var rows = constructStudentTableRows(this.props.rows, this.state.students, this.state.selected_students, 
                                         this.synchronizeCheckboxRow, this.state.search_text, this.state.filter,
                                         this.state.sort_column, this.state.sort_direction);
    var table_header_columns = [
      {
        id: "checkbox",
        content: <div><input type="checkbox" onChange={this.checkboxAllClicked} /></div>,
        sortable: false
      },
      {
        id: "user_name",
        content: this.props.columns.user_name,
        sortable: true
      },
      {
        id: "last_name",
        content: this.props.columns.last_name,
        sortable: true
      },
      {
        id: "first_name",
        content: this.props.columns.first_name,
        sortable: true
      },
      {
        id: "section",
        content: this.props.columns.section,
        sortable: true
      },
      {
        id: "grace_credits",
        content: this.props.columns.grace_credits,
        sortable: true
      },
      {
        id: "notes",
        content: this.props.columns.notes,
        sortable: false
      }];

    return (
      <div>
        <StudentsActionBox
          actions_text={this.props.actions}
          selected_students={this.state.selected_students}
          sections={this.props.sections}
          refresh={this.refresh} />
        <StudentsTableFilter
          filters_text={this.props.filters}
          filter={this.state.filter}
          onFilterChange={this.synchronizeFilter}
          students={this.state.students} />
        <TableSearch
          placeholder_text={this.props.search}
          search_text={this.state.search_text}
          onSearchInputChange={this.synchronizeSearchInput} />
        <table id="students">
          <TableHeader
            columns={table_header_columns}
            sort_column={this.state.sort_column}
            sort_direction={this.state.sort_direction}
            onHeaderColumnChange={this.synchronizeHeaderColumn} />
          <tbody>
            {rows}
          </tbody>
        </table>
      </div>
    );
  }
});

// The bulk action box where you can give grace credits,
// change sections, or mark as active or inactive.
StudentsActionBox = React.createClass({
  getInitialState: function() {
    return {
        select_value: "give_grace_credits",
        grace_credits_input: "0",
        button_disabled: false
    };
  },
  actionSelectChanged: function(event) {
    // Reset state based on action selected.
    this.setState({
      select_value: event.target.value,
      button_disabled: false
    });
    if (event.target.value == "give_grace_credits") {
      this.setState({
        grace_credits_input: "0",
        section_id: ""
      });
    } else if (event.target.value == "update_section") {
      if (this.props.sections) {
        var initial_section = this.props.sections[0].id;
        this.setState({
          grace_credits_input: "0",
          section_id: initial_section
        });
      } else {
        this.setState({
          grace_credits_input: "0",
          section_id: "",
          button_disabled: true
        });
      }
    }
  },
  sectionSelectChanged: function(event) {
    this.setState({
      section_id: event.target.value
    });
  },
  graceCreditsChanged: function(event) {
    // Checks that the input is valid (integer)
    var value = event.target.value;
    if (!isNaN(+value)) {
      this.setState({
        grace_credits_input: value, 
        button_disabled: false
      });
    } else {
      this.setState({
        grace_credits_input: value,
        button_disabled: true});
    }
    
  },
  performAction: function() {
    // Gets student ids and other relevant info from this.state and
    // sends an AJAX call over to the appropriate backend. Then tells
    // parent to refresh
    var student_ids = this.props.selected_students.map(function(i) {
      return i.id.toString();
    });

    var dataLoad = {
      student_ids: student_ids,
      bulk_action: this.state.select_value,
      number_of_grace_credits: this.state.grace_credits_input,
      section: this.state.section_id
    };

    jQuery.ajax({
      method: "POST",
      url: "/students/bulk_modify",
      data: dataLoad,
      success: function(data) {
        this.props.refresh();
      }.bind(this)
    });
  },

  render: function() {
    // Create apply button and secondary select input based on current state.
    var applyButton = 
      <button onClick={this.performAction} disabled={this.state.button_disabled}>
        Apply
      </button>;
    var optionalInputBox = null;
    if (this.state.select_value == "give_grace_credits") {
      optionalInputBox =
        <input type="text" value={this.state.grace_credits_input} onChange={this.graceCreditsChanged} />
    } else if (this.state.select_value == "update_section") {
      if (this.props.sections) {
        var section_options = [];
        for (var i = 0; i < this.props.sections.length; i++) {
          var section = this.props.sections[i];
          var option = 
            <option value={section.id} onChange={this.sectionSelectChanged}>
              {section.name}
            </option>
          section_options.push(option);
        }
        optionalInputBox =
          <select value={this.state.section_id} onChange={this.sectionSelectChanged}>
            {section_options}
          </select>
      } else {
        optionalInputBox =
          <span>
            {this.props.actions_text.no_sections}
          </span>
      }
    }

    // If more than one student is selected render the div. Otherwise nothing.
    if (this.props.selected_students.length > 0) {
      return (
        <div>
          <select value={this.state.select_value} onChange={this.actionSelectChanged}>
            <option value="give_grace_credits">{this.props.actions_text.give_grace_credits}</option>
            <option value="update_section">{this.props.actions_text.add_section}</option>
            <option value="hide">{this.props.actions_text.hide_students}</option>
            <option value="unhide">{this.props.actions_text.unhide_students}</option>
          </select>
          {optionalInputBox}
          {applyButton}
        </div>
      );
    } else {
      return (
        <div></div>
      );
    }
  }
});

// The component for a single table row. This represents one student.
StudentsTableRow = React.createClass({
  // Tells parent that this student's row's checkbox changed
  checkboxChanged: function(event) {
    this.props.onCheckboxRowChange(this.props.student, event.currentTarget.checked);
  },
  render: function() {
    return (
        <tr>
          <td>
            <input type="checkbox" onChange={this.checkboxChanged} checked={this.props.checked} />
          </td>
          <td>
            <label>
              {this.props.student.user_name}
            </label>
          </td>
          <td>
            {this.props.student.last_name}
          </td>
          <td>
            {this.props.student.first_name}
          </td>
          <td>
            {this.props.student.section_name ? this.props.student.section_name : "-"}
          </td>
          <td>
            {this.props.student.grace_credits_remaining} / {this.props.student.grace_credits}
          </td>
          <td>
            <a href={this.props.student.edit_link}>
              {this.props.edit_text.edit}
            </a>
            |
            <a href={this.props.student.notes_link} data-remote="true" id="notes_highlight_user_id">
              {this.props.edit_text.notes} ({this.props.student.num_notes})
            </a>
          </td>
        </tr>
    );
  }
});



function constructStudentTableRows(i18n_text, students, selected_students, 
                                   on_checkbox_row_change, search_text, 
                                   filter, sort_column, sort_direction)
{
  // Filter out students based on search text.
  var searchedStudents = [];
  if (search_text) {
    students.forEach(function(student) {
      // Search through first name, last name, and user name.
      if (student.first_name.toLowerCase().indexOf(search_text) !== -1 || 
          student.last_name.toLowerCase().indexOf(search_text) !== -1 ||
          student.user_name.toLowerCase().indexOf(search_text) !== -1)
      {
        searchedStudents.push(student);
      }
    }.bind(this));
  } else {
    students.forEach(function(student) {
      searchedStudents.push(student);
    });
  }
  
  // Filter out students by filter (all/active/not active)
  var filteredStudents;
  if (filter !== "all") {
    if (filter == "active") {
        filteredStudents = searchedStudents.filter(function(student) {
        return !student.hidden;
      });
    } else if (filter == "not_active") {
        filteredStudents = searchedStudents.filter(function(student) {
        return student.hidden;
      });
    }
  } else {
    filteredStudents = searchedStudents;
  }

  // Sort students according to sort_column and sort_direction.
  var sortedAndFilteredStudents = filteredStudents.sort(function(a, b) {
    // Use makeSearchable to create valid strings/numbers to sort against.
    if (makeSearchable(a[sort_column]) > makeSearchable(b[sort_column])) {
      return 1;
    } else if (makeSearchable(b[sort_column]) > makeSearchable(a[sort_column])) {
      return -1;
    }
    return 0;
  }.bind(this));

  // Flip order if direction is descending.
  if (sort_direction == 'desc') sortedAndFilteredStudents.reverse();

  var rows = [];
  sortedAndFilteredStudents.forEach(function(student) {
    var checked = (selected_students.indexOf(student) > -1 ? true : false);
    rows.push(
      <StudentsTableRow
        student={student}
        key={student.id}
        edit_text={i18n_text}
        onCheckboxRowChange={on_checkbox_row_change}
        checked={checked} />
    );
  }.bind(this));

  return rows;
}

function makeSearchable(a)
{

  if (typeof a == 'string') {
    return a.toLowerCase().replace(" ", "");
  } else {
    return a;
  }
}
