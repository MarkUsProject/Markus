import React from 'react';
import {render} from 'react-dom';

import {CheckboxTable, withSelection} from './markus_with_selection_hoc'
import {stringFilter} from './Helpers/table_helpers';

class RawMarksSpreadsheet extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      grade_columns: [],
      data: [],
      sections: {},
      loading: true,
      show_hidden: false,
      filtered: [{id: 'hidden', value: false}]
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    // Getting additional grade entry item columns
    $.ajax({
      url: Routes.get_mark_columns_grade_entry_form_path(this.props.grade_entry_form_id),
      method: 'GET',
      dataType: 'json'
    }).then(data => {
      let grade_columns = data.map(c =>
        Object.assign({},
                      c,
                      { Cell: this.inputCell,
                        style: {padding: '0', border: '1px solid #8d8d8d', margin: '-1px 0'},
                        className: 'grade-input',
                        minWidth: 50,
                        defaultSortDesc: true
                      }));
      this.setState({ grade_columns });
    });

    // Getting row data
    $.ajax({
      url: Routes.populate_grades_table_grade_entry_form_path(this.props.grade_entry_form_id),
      method: 'GET',
      dataType: 'json',
    }).then(response => {
      this.props.resetSelection();

      this.setState({
        data: response.data,
        loading: false,
        sections: response.sections
      }, () => this.forceUpdate());
    });
  };

  /* Called when an action is run */
  onSubmit = (event) => {
    event.preventDefault();

    const data = {
      student_ids: this.props.selection,
      bulk_action: this.actionBox.state.action,
      grace_credits: this.actionBox.state.grace_credits,
      section: this.actionBox.state.section
    };

    $.ajax({
      method: 'patch',
      url: Routes.bulk_modify_students_path(),
      data: data
    }).then(this.fetchData);
  };

  nameColumns = () => [
    {
      id: 'hidden',
      accessor: 'hidden',
      filterMethod: (filter, row) => {
        return filter.value || !row.hidden;
      },
      className: 'rt-hidden',
      headerClassName: 'rt-hidden',
      resizable: false,
      width: 0,
      Filter: () => '',
    },
    {
      Header: I18n.t('activerecord.attributes.user.user_name'),
      accessor: 'user_name',
      id: 'user_name',
      minWidth: 120
    },
    {
      Header: I18n.t('activerecord.models.section', {count: 1}),
      accessor: 'section_id',
      show: this.props.show_sections || false,
      minWidth: 70,
      Cell: ({ value }) => {
        return this.state.sections[value] || ''
      },
      filterMethod: (filter, row) => {
        if (filter.value === 'all') {
          return true;
        } else {
          return this.state.sections[row[filter.id]] === filter.value;
        }
      },
      Filter: ({ filter, onChange }) =>
        <select
          onChange={event => onChange(event.target.value)}
          style={{ width: '100%' }}
          value={filter ? filter.value : 'all'}
        >
          <option value='all'>{I18n.t('all')}</option>
          {Object.entries(this.state.sections).map(
            kv => <option key={kv[1]} value={kv[1]}>{kv[1]}</option>)}
        </select>,
    },
    {
      Header: I18n.t('activerecord.attributes.user.first_name'),
      accessor: 'first_name',
      minWidth: 120
    },
    {
      Header: I18n.t('activerecord.attributes.user.last_name'),
      accessor: 'last_name',
      minWidth: 120
    },
  ];

  inputCell = row => {
    return <GradeEntryCell
      grade_entry_form_id={this.props.grade_entry_form_id}
      grade_id={'grade_' + row.original._id + '_' + row.column.id}
      grade_entry_column={row.column.id}
      student_id={row.original._id}
      default_value={row.value}
      updateTotal={(gradeEntryItemId, newGrade, newTotal) =>
                    this.updateTotal(row.index, row.original._id, gradeEntryItemId, newGrade, newTotal)}
    />;
  };

  totalColumn = () => { return {
    accessor: 'total_marks',
    Header: `${I18n.t('activerecord.attributes.grade_entry_form.total')} (${this.props.out_of_total})`,
    minWidth: 50,
    className: 'grade-total',
    Cell: row => {
      return <GradeEntryTotal initial_value={row.value} ref={node => this[`total-${row.original._id}`] = node} />;
    },
    defaultSortDesc: true,
    sortMethod: (a, b, desc) => {
      a = a === null || a === undefined || a === 'N/A' ? -Infinity : a;
      b = b === null || a === undefined || b === 'N/A' ? -Infinity : b;
      if (a < b) {
        return -1;
      } else if (a > b) {
        return 1;
      } else {
        return 0;
      }
    }

  }};

  markingStateColumn = {
    accessor: 'released_to_student',
    Header: I18n.t('grade_entry_forms.grades.marking_state'),
    Cell: ({ value }) => value ? I18n.t('results.state.released') : '',
    filterable: false,
    minWidth: 50,
  };

  updateTotal = (index, id, gradeEntryItemId, newGrade, newTotal) => {
    if (this.props.show_total) {
      this[`total-${id}`].setState({value: newTotal});
    }
    this.setState((prevState) => {
      // State should never be modified directly, we copy the relevant data using the spread syntax and modify the copy.
      let newData = [...prevState.data];
      newData[index] = {...newData[index]};
      newData[index]['total_marks'] = newTotal;
      newData[index][gradeEntryItemId] = newGrade;
      return {data: newData};
    });
  };

  shouldComponentUpdate(nextProps, nextState) {
    let f1 = this.state.filtered;
    let f2 = nextState.filtered;
    if (f1.length !== f2.length) {
      return true;
    }
    for (let i = 0; i < f1.length; i++) {
      if (f1[i].id !== f2[i].id || f1[i].value !== f2[i].value) {
        return true;
      }
    }

    return (nextState.grade_columns.length !== this.state.grade_columns.length) ||
           (nextState.data.length !== this.state.data.length) ||
           (nextProps.selection !== this.props.selection);
  }

  getColumns = () => {
    let columns = this.nameColumns().concat(this.state.grade_columns);
    if (this.props.show_total) {
      columns = columns.concat([this.totalColumn()]);
    }
    columns = columns.concat([this.markingStateColumn]);
    return columns;
  };

  isSelected = (key) => {
    return this.props.selection.includes(key);
  };

  toggleRelease = (released) => {
    const dataLoad = {
      release_results: released,
      filter: 'none',
      students: this.props.selection
    };

    this.setState({loading: true}, () => {
      $.ajax({
        method: 'POST',
        url: Routes.update_grade_entry_students_grade_entry_form_path(this.props.grade_entry_form_id),
        data: dataLoad,
      }).then(this.fetchData);
    });
  };

  onFilteredChange = (filtered) => {
    this.setState({filtered}, () => this.forceUpdate());
  };

  hiddenInput = () => {
    return (
      <span>
        <input
          id='show_hidden'
          name='show_hidden'
          type='checkbox'
          checked={this.state.show_hidden}
          onChange={this.updateShowHidden}
          style={{marginLeft: '5px', marginRight: '5px'}}
        />
        <label htmlFor='show_hidden'>
          {I18n.t('students.display_inactive')}
        </label>
      </span>
    );
  };

  updateShowHidden = (event) => {
    let show_hidden = event.target.checked;
    let filtered = [];
    this.state.filtered.forEach(filter => {
      if (filter.id === 'hidden') {
        filtered.push({id: 'hidden', value: show_hidden});
      } else {
        filtered.push({...filter});
      }
    });
    this.setState({show_hidden, filtered}, () => this.forceUpdate());
  };

  render() {
    const { data, loading } = this.state;

    return (
      <div>
        <SpreadsheetActionBox
          ref={(r) => this.actionBox = r}
          toggleRelease={this.toggleRelease} />
        {this.hiddenInput()}
        <CheckboxTable
          ref={(r) => this.checkboxTable = r}
          data={data}
          columns={this.getColumns()}
          defaultSorted={[
            {
              id: 'user_name'
            }
          ]}
          filterable
          filtered={this.state.filtered}
          defaultFilterMethod={stringFilter}
          onFilteredChange={this.onFilteredChange}
          onSortedChange={() => this.forceUpdate()}
          loading={loading}
          {...this.props.getCheckboxProps()}
        />
      </div>
    );
  }
}


class GradeEntryCell extends React.Component {
  constructor(props) {
    super(props);
    this.typing_timer = undefined;
    this.state = {
      value: props.default_value === null || props.default_value === undefined ? '' : props.default_value
    };
  }

  componentWillReceiveProps = (nextProps) => {
    this.setState({value: nextProps.default_value === null || nextProps.default_value === undefined ? '' : nextProps.default_value});
  };

  handleChange = (event) => {
    if (this.typing_timer) {
      clearTimeout(this.typing_timer);
    }

    let updated_grade = event.target.value === '' ? '' : Number(event.target.value);
    this.setState({value: updated_grade});

    if (updated_grade !== '' && (Number.isNaN(updated_grade) || updated_grade < 0)) {
      return;
    }

    let params = {
      'updated_grade':       updated_grade,
      'student_id':          this.props.student_id,
      'grade_entry_item_id': this.props.grade_entry_column,
    };

    this.typing_timer = setTimeout(() => {
      $.ajax({
        url:  Routes.update_grade_grade_entry_form_path(this.props.grade_entry_form_id),
        data: params,
        type: 'POST',
        dataType: 'text',
      }).then(total => {
        // Flash green
        $(`#${this.props.grade_id}`)
          .css('background-color', '')
          .addClass('updated')
          .delay(1000)
          .queue(function () {
            $(this).removeClass('updated');
            $(this).dequeue();
          });

        if (total === '') {
          total = I18n.t('grade_entry_forms.grades.no_mark');
        } else {
          total = parseFloat(total);
        }
        this.props.updateTotal(this.props.grade_entry_column, updated_grade, total);
      });
    }, 300);
  };

  render() {
    return (
      <input id={this.props.grade_id} type="number" step="any" size={4} value={this.state.value} min={0}
             onChange={this.handleChange} />
    );
  }
}


class GradeEntryTotal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: props.initial_value
    };
  }

  componentDidUpdate(oldProps) {
    if (oldProps.initial_value !== this.props.initial_value) {
      this.setState({value: this.props.initial_value});
    }
  }

  render() {
    return <span>{this.state.value}</span>;
  }
}


class SpreadsheetActionBox extends React.Component {
  render() {
    return (
      <div className='react-release-marks'>
        <button onClick={() => this.props.toggleRelease(true)}>
          {I18n.t('submissions.release_marks')}
        </button>
        <button onClick={() => this.props.toggleRelease(false)}>
          {I18n.t('submissions.unrelease_marks')}
        </button>
      </div>
    );
  }
}


let MarksSpreadsheet = withSelection(RawMarksSpreadsheet);


export function makeMarksSpreadsheet(elem, props) {
  render(<MarksSpreadsheet {...props} />, elem);
}
