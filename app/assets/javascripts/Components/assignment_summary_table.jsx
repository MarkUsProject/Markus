import React from 'react';
import {render} from 'react-dom';
import {markingStateColumn} from "./Helpers/table_helpers";

import ReactTable from 'react-table';


class AssignmentSummaryTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      criteriaColumns: [],
      loading: true,
      num_assigned: 0,
      num_marked: 0
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.ajax({
      url: Routes.summary_assignment_path(this.props.assignment_id),
      dataType: 'json',
    }).then(res => {
      res.criteriaColumns.forEach((col) => {
        col['filterable'] = false;
        col['defaultSortDesc'] = true;
      });
      this.setState({
        data: res.data,
        criteriaColumns: res.criteriaColumns,
        num_assigned: res.numAssigned,
        num_marked: res.numMarked,
        loading: false
      });
    });
  };

  fixedColumns = [
    {
      Header: I18n.t('activerecord.models.group.one'),
      id: 'group_name',
      accessor: 'group_name',
      Cell: row => {
        if (row.original.result_id) {
          const path = Routes.edit_assignment_submission_result_path(
            this.props.assignment_id,
            row.original.submission_id,
            row.original.result_id
          );
          return <a href={path}>{row.original.group_name}</a>;
        } else {
          return <span>{row.original.group_name}</span>;
        }
      },
      filterMethod: (filter, row) => {
        if (filter.value) {
          // Check group name
          if (row._original.group_name.includes(filter.value)) {
            return true;
          }

          // Check member names
          const member_matches = row._original.members.some(
            (member) => member.some((name) => name.includes(filter.value))
          );

          if (member_matches) {
            return true;
          }

          // Check grader user names
          return row._original.graders.some(
            (grader) => grader.includes(filter.value)
          );
        } else {
          return true;
        }
      },
    },
    markingStateColumn(),
    {
      Header: I18n.t('activerecord.attributes.result.total_mark'),
      accessor: 'final_grade',
      Cell: row => {
        if (row.original.final_grade) {
          const max_mark = Math.round(row.original.max_mark * 100) / 100;
          return row.original.final_grade + ' / ' + max_mark;
        } else {
          return '';
        }
      },
      className: 'number',
      filterable: false,
      defaultSortDesc: true,
    },
  ];

  bonusColumn = {
    Header: I18n.t('activerecord.models.extra_mark.other'),
    accessor: 'total_extra_marks',
    Cell: ({value}) => parseFloat(value) ? value : '',
    className: 'number',
    filterable: false,
    defaultSortDesc: true,
  };

  render() {
    const {data, criteriaColumns} = this.state;
    return (
      <div>
        <div style={{'display': 'inline-block'}}>
          <div className='progress'>
            <meter
              value={this.state.num_marked}
              min={0}
              max={this.state.num_assigned}
              low={this.state.num_assigned * 0.35}
              high={this.state.num_assigned * 0.75}
              optimum={this.state.num_assigned}
            >
              {this.state.num_marked}/{this.state.num_assigned}
            </meter>
            {this.state.num_marked}/{this.state.num_assigned}&nbsp;{I18n.t('submissions.state.complete')}
          </div>
        </div>
        {this.props.is_admin &&
        <form className='rt-action-box'
              action={Routes.summary_assignment_path({id: this.props.assignment_id, format: 'csv', _options: true})}
              method='get'>
          <button
            type='submit'
            name='download'>
            {I18n.t('download')}
          </button>
        </form>
        }
        <ReactTable
          data={data}
          columns={this.fixedColumns.concat(criteriaColumns, [this.bonusColumn])}
          filterable
          defaultSorted={[{id: 'group_name'}]}
          SubComponent={(row) => {
            return (
              <div>
                <h4>{I18n.t('activerecord.attributes.group.student_memberships')}</h4>
                <ul>
                  {row.original.members.map((member) => {
                    return <li key={member[0]}>({member[0]}) {member[1]} {member[2]}</li>;
                  })}
                </ul>
                <h4>{I18n.t('activerecord.models.ta', {count: 2})}</h4>
                <ul>
                  {row.original.graders.map((grader) => {
                    return <li key={grader[0]}>({grader[0]}) {grader[1]} {grader[2]}</li>;
                  })}
                </ul>
              </div>
            );
          }}
          loading={this.state.loading}
        />
      </div>
    );
  }
}

export function makeAssignmentSummaryTable(elem, props) {
  render(<AssignmentSummaryTable {...props} />, elem);
}
