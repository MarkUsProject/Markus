import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';


class AssignmentSummaryTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      criteriaColumns: []
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
      this.setState({data: res.data, criteriaColumns: res.criteriaColumns});
    });
  };

  fixedColumns = [
    {
      Header: I18n.t('groups.group_name'),
      id: 'group_name',
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
    {
      Header: I18n.t('browse_submissions.marking_state'),
      accessor: 'marking_state',
      filterMethod: (filter, row) => {
        if (filter.value === 'all') {
          return true;
        } else {
          return filter.value === row[filter.id];
        }
      },
      Filter: ({ filter, onChange }) =>
        <select
          onChange={event => onChange(event.target.value)}
          style={{ width: '100%' }}
          value={filter ? filter.value : 'all'}
        >
          <option value='all'>{I18n.t('all')}</option>
          <option value='unmarked'>{I18n.t('marking_state.not_collected')}</option>
          <option value='partial'>{I18n.t('marking_state.in_progress')}</option>
          <option value='completed'>{I18n.t('marking_state.completed')}</option>
          <option value='released'>{I18n.t('marking_state.released')}</option>
          <option value='remark'>{I18n.t('marking_state.remark_requested')}</option>
        </select>,
    },
    {
      Header: I18n.t('browse_submissions.final_grade'),
      accessor: 'final_grade',
      filterable: false,
      defaultSortDesc: true,
    },
  ];

  render() {
    const {data, criteriaColumns} = this.state;
    return (
      <div>
        {this.props.is_admin &&
         <form action={Routes.csv_summary_assignment_path(this.props.assignment_id)}
               method='get'>
           <input type='submit'
                  name='download'
                  value={I18n.t('download')}>
           </input>
           <input type='submit'
                  name='download'
                  value={'Old: ' + I18n.t('browse_submissions.detailed_csv_report')}>
           </input>
         </form>
        }
        <ReactTable
          data={data}
          columns={this.fixedColumns.concat(criteriaColumns)}
          filterable
          defaultSorted={[{id: 'group_name'}]}
          SubComponent={(row) => {
            return (
              <div>
                <h4>{I18n.t('members')}</h4>
                <ul>
                  {row.original.members.map((member) => {
                    return <li key={member[0]}>({member[0]}) {member[1]} {member[2]}</li>;
                  })}
                </ul>
                <h4>{I18n.t('graders.graders')}</h4>
                <ul>
                  {row.original.graders.map((grader) => {
                    return <li key={grader}>{grader}</li>;
                  })}
                </ul>
              </div>
            );
          }}
        />
      </div>
    );
  }
}

export function makeAssignmentSummaryTable(elem, props) {
  render(<AssignmentSummaryTable {...props} />, elem);
}
